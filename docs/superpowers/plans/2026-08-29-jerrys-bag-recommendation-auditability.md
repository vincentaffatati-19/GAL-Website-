# Jerry’s Bag + Recommendation Auditability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build longitudinal Jerry’s Bag history, immutable bag snapshots, safe what-if scenarios, bag score snapshots, and the normalized recommendation audit chain required to reproduce GAL Fit decisions.

**Architecture:** Extend the existing `gal_bags`, `gal_bag_items`, `gal_decision_snapshots`, and `gal_catalog_products` tables additively. Current bag state remains golfer-editable current truth; history, snapshots, score snapshots, and recommendation records are golfer-readable/trusted-write audit evidence. Recommendation ranking remains deterministic and independent of commerce routing.

**Tech Stack:** PostgreSQL 17 / Supabase, Row Level Security, pgTAP, Supabase CLI 2.116.0, GitHub Actions isolated replay CI.

**Spec:** `docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md`

## Global Constraints

- Work only on `feature/golfer-intelligence-v1`; do not modify `develop`, `main`, staging, or production.
- Preserve existing canonical user, bag, item, decision-snapshot, valuation, and product IDs.
- All public tables must have RLS enabled and least-privilege grants.
- `authenticated` access must combine role grants with ownership predicates; UPDATE policies require both `USING` and `WITH CHECK`.
- Append-only/immutable evidence tables expose SELECT to the owning golfer and trusted writes only.
- Use `gal_category` where semantics match; do not create rapidly evolving enums for model keys or event keys.
- Unknown/partial equipment identity is valid; never invent a canonical product ID.
- Same frozen golfer/bag inputs + same data/model versions must be reproducible.
- Fit ranking is completed before commerce routing; affiliate payout cannot affect Fit Score or rank.
- New migration filenames must be generated with `supabase migration new <name>` using the pinned CLI, not invented manually.
- TDD is mandatory: add failing pgTAP first, verify RED for the intended missing behavior, then add the minimum migration and replay the full suite.
- Run Supabase security and performance advisors before closing the phase.

---

## File Map

**Existing files modified**
- `supabase/test-baseline/gal_core_current_shape.sql` — unchanged production-shaped baseline; only read for compatibility.
- `supabase/migrations/*` — additive GI-1.1 migrations.
- `supabase/tests/*` — pgTAP contracts.
- `docs/data/gi-1.1/*` — permanent verification evidence.

**New test files**
- `supabase/tests/gi11_009_bag_history.sql`
- `supabase/tests/gi11_010_bag_snapshots.sql`
- `supabase/tests/gi11_011_bag_scenarios.sql`
- `supabase/tests/gi11_012_bag_scores.sql`
- `supabase/tests/gi11_013_recommendation_runs.sql`
- `supabase/tests/gi11_014_recommendation_items.sql`
- `supabase/tests/gi11_015_recommendation_audit_links.sql`

**New migration responsibilities**
- `*_gi11_bag_history.sql` — extend bag/item current state and create immutable item history + trigger.
- `*_gi11_bag_snapshots.sql` — immutable full-bag snapshots.
- `*_gi11_bag_scenarios.sql` — golfer-owned draft/saved what-if scenarios and scenario items; private trusted adoption routine.
- `*_gi11_bag_scores.sql` — immutable whole-bag optimization score snapshots.
- `*_gi11_recommendation_runs.sql` — first-class recommendation execution records.
- `*_gi11_recommendation_items.sql` — candidate/finalist rows + score components.
- `*_gi11_recommendation_audit_links.sql` — link legacy decision snapshots into the normalized audit chain.

---

### Task 1: Bag item lifecycle history

**Files:**
- Test: `supabase/tests/gi11_009_bag_history.sql`
- Create migration: `supabase/migrations/<generated>_gi11_bag_history.sql`

**Interfaces:**
- Consumes: `gal_bags`, `gal_bag_items`, `gal_users`, `gal_catalog_products`, `gal_current_user_id()`.
- Produces: `gal_bag_item_history`, `gal_bag_items.identification_status`, `gal_bag_items.identification_confidence`, `gal_bag_items.effective_from`, `gal_bags.bag_type`, `gal_bags.archived_at`.

- [ ] **Step 1: Write failing pgTAP** covering: additive columns; history table; RLS; authenticated own-history SELECT only; no authenticated INSERT/UPDATE/DELETE; service-role writes; replacement/configuration history; partial identity; 14-club current-bag count remains correct.
- [ ] **Step 2: Run `supabase test db` and verify RED** while the existing 192 Foundation assertions remain green.
- [ ] **Step 3: Implement minimum migration.** `gal_bag_item_history` stores `history_id`, `user_id`, `bag_id`, `bag_item_id`, item/category/slot/product/brand/display/configuration/status/ownership/count fields, `change_type`, `change_reason`, `effective_from`, `effective_to`, `decision_snapshot_id`, and timestamps. Add a trigger-only function in `gal_private` that captures OLD before UPDATE/DELETE. `change_type` accepts `ADDED`, `REPLACED`, `RECONFIGURED`, `REMOVED`, `SOLD`, `LOST`, `RETIRED`, `UNKNOWN_DISPOSITION`, `UPDATED`.
- [ ] **Step 4: Replay full suite and verify GREEN.**
- [ ] **Step 5: Commit** `feat(db): add Jerry's Bag item history`.

### Task 2: Immutable bag snapshots

**Files:**
- Test: `supabase/tests/gi11_010_bag_snapshots.sql`
- Create migration: `supabase/migrations/<generated>_gi11_bag_snapshots.sql`

**Interfaces:**
- Consumes: current bag/item state.
- Produces: `gal_bag_snapshots` with stable `bag_snapshot_id` and versioned item JSON evidence.

- [ ] **Step 1: Write failing pgTAP** covering table/columns, user-time index, RLS, own SELECT, no authenticated mutation, service-role INSERT only, preservation of item/configuration evidence, and immutable replay after current bag changes.
- [ ] **Step 2: Verify intended RED** with all earlier tests green.
- [ ] **Step 3: Implement migration** with fields: `id`, `bag_snapshot_id`, `user_id`, `bag_id`, `snapshot_type`, `bag_version`, `items_snapshot`, `club_count`, `market_code`, `currency`, `captured_at`, `created_at`. Revoke all from anon/authenticated then grant authenticated SELECT and service-role SELECT/INSERT only.
- [ ] **Step 4: Verify full GREEN.**
- [ ] **Step 5: Commit** `feat(db): add immutable bag snapshots`.

### Task 3: What-if scenarios + atomic adoption

**Files:**
- Test: `supabase/tests/gi11_011_bag_scenarios.sql`
- Create migration: `supabase/migrations/<generated>_gi11_bag_scenarios.sql`

**Interfaces:**
- Consumes: `gal_bags`, `gal_bag_items`, `gal_bag_item_history`, `gal_bag_snapshots`, `gal_profile_snapshots`.
- Produces: `gal_bag_scenarios`, `gal_bag_scenario_items`, `gal_private.gal_adopt_bag_scenario(uuid,text)`.

- [ ] **Step 1: Write failing pgTAP** for golfer-owned scenario CRUD, cross-user denial, scenario isolation from actual bag state, partial product identity, scenario version context, adoption status, and explicit adoption modifying the real bag only through the trusted routine.
- [ ] **Step 2: Verify RED** without altering earlier behavior.
- [ ] **Step 3: Implement migration.** Scenario fields include owner/bag/profile snapshot/base bag snapshot/status/name/category/context/model/data versions/market/currency/timestamps. Scenario items express `ADD`, `REMOVE`, `REPLACE`, or `RECONFIGURE` with target bag-item references and proposed product/configuration. The adoption routine is `SECURITY INVOKER`, lives in `gal_private`, is executable only by `service_role`, validates ownership/OPEN status, applies item mutations transactionally, marks scenario `ADOPTED`, and writes an immutable bag snapshot. Event emission is intentionally deferred until the governed behavior-event phase seeds canonical event semantics.
- [ ] **Step 4: Verify GREEN**, including `GI-BAG-004` scenario isolation and `GI-BAG-005` adoption.
- [ ] **Step 5: Commit** `feat(db): add Jerry's Bag scenarios and adoption`.

### Task 4: Bag optimization score snapshots

**Files:**
- Test: `supabase/tests/gi11_012_bag_scores.sql`
- Create migration: `supabase/migrations/<generated>_gi11_bag_scores.sql`

**Interfaces:**
- Consumes: bag snapshot + profile snapshot + model registry.
- Produces: immutable `gal_bag_score_snapshots`.

- [ ] **Step 1: Write failing pgTAP** for 0–100 score constraints, separate component JSON, confidence, model/data versions, own SELECT only, service-role INSERT only, and no age-based required penalty field.
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement migration** with `bag_score_snapshot_id`, `user_id`, `bag_id`, `bag_snapshot_id`, optional `scenario_id`, `profile_snapshot_id`, `optimization_score`, `confidence`, `components`, `bag_optimization_version`, `equipment_data_version`, `captured_at`, `created_at`.
- [ ] **Step 4: Verify GREEN.**
- [ ] **Step 5: Commit** `feat(db): add bag optimization score snapshots`.

### Task 5: Recommendation runs

**Files:**
- Test: `supabase/tests/gi11_013_recommendation_runs.sql`
- Create migration: `supabase/migrations/<generated>_gi11_recommendation_runs.sql`

**Interfaces:**
- Consumes: profile snapshot, bag snapshot, optional scenario, model registry.
- Produces: immutable/versioned `gal_recommendation_runs`.

- [ ] **Step 1: Write failing pgTAP** for required version chain, run status, normalized input snapshot, market/currency, own SELECT, trusted INSERT/UPDATE of lifecycle status only, cross-user denial, and replay identity fields.
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement migration** with stable `recommendation_run_id`, user/run/category/status, snapshot references, scenario reference, equipment/fit/category/guide/bag/question/AI versions, normalized inputs/results JSON, market/currency, started/completed/superseded/created timestamps. Authenticated gets SELECT only; service role gets SELECT/INSERT/UPDATE, not DELETE.
- [ ] **Step 4: Verify GREEN.**
- [ ] **Step 5: Commit** `feat(db): add recommendation runs`.

### Task 6: Recommendation items + Fit Score components

**Files:**
- Test: `supabase/tests/gi11_014_recommendation_items.sql`
- Create migration: `supabase/migrations/<generated>_gi11_recommendation_items.sql`

**Interfaces:**
- Consumes: recommendation run + canonical products.
- Produces: `gal_recommendation_items`, `gal_fit_score_components`.

- [ ] **Step 1: Write failing pgTAP** proving: item eligibility/exclusion state; rank; 0–100 Fit Score; separate 0–1 confidence; structured strengths/tradeoffs; current-equipment delta; `KEEP_CURRENT`/`RECONFIGURE_CURRENT` valid result types; component weights reconcile to stored Fit Score within a defined tolerance; own read only; no commerce commission/network/retailer-payout columns.
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement migration.** Recommendation items store `result_type`, optional product/configuration, eligibility/exclusion reason, fit score, rank, confidence, strengths/tradeoffs JSON, current delta, price/availability evidence, and timestamps. Components store component key, raw/normalized score, weight, weighted score, evidence, model version. Add indexes on run/rank and product.
- [ ] **Step 4: Verify GREEN**, including `GI-REC-001`, `GI-REC-002`, `GI-REC-004`, `GI-REC-005`, `GI-REC-006` structural contracts.
- [ ] **Step 5: Commit** `feat(db): add recommendation items and fit components`.

### Task 7: Link legacy decision snapshots into the audit chain

**Files:**
- Test: `supabase/tests/gi11_015_recommendation_audit_links.sql`
- Create migration: `supabase/migrations/<generated>_gi11_recommendation_audit_links.sql`

**Interfaces:**
- Consumes: existing `gal_decision_snapshots` plus normalized recommendation records.
- Produces: backward-compatible links `recommendation_run_id`, `recommendation_item_id`, `profile_snapshot_id`, `bag_snapshot_id`.

- [ ] **Step 1: Write failing pgTAP** proving additive columns/FKs, existing decision snapshot behavior remains read-only to golfer, and a completed recommendation can be traced decision → item → run → profile/bag snapshots.
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement additive migration** with nullable FKs and indexes; do not rewrite existing rows.
- [ ] **Step 4: Verify GREEN**, including historical reproducibility chain `GI-REC-003`.
- [ ] **Step 5: Commit** `feat(db): link decision snapshots to recommendation audit chain`.

### Task 8: Phase verification gate

**Files:**
- Create: `docs/data/gi-1.1/jerrys-bag-recommendation-verification.md`

**Interfaces:**
- Consumes: all prior phase migrations/tests.
- Produces: immutable verification record for review before behavior/intelligence work.

- [ ] **Step 1: Clean replay** sanitized current-shape baseline + every GI-1.1 migration on disposable PostgreSQL 17.
- [ ] **Step 2: Run full `supabase test db`** and record exact file/assertion counts.
- [ ] **Step 3: Run `supabase db advisors --local --type security` and `--type performance`; zero unresolved issues required.
- [ ] **Step 4: Record RLS matrix** for bag history, bag snapshots, scenarios, scores, recommendation runs/items/components, and decision links.
- [ ] **Step 5: Record acceptance mapping** for `GI-BAG-001..006` and `GI-REC-001..006`, with exact test names and result.
- [ ] **Step 6: Commit** `test(db): verify Jerry's Bag and recommendation audit phase`.

---

## Self-Review

**Spec coverage:** This plan covers approved Sections 5, 6, 11.5, 11.6, and the Phase 4/5 acceptance requirements in Section 12. It intentionally defers governed behavior-event emission, connected services, Intelligence State, commercial aggregates, and guide UI integration to their scheduled later phases.

**Placeholder scan:** No implementation step contains `TBD`, `TODO`, or unspecified error-handling placeholders. Migration timestamps are intentionally represented as `<generated>` because the Supabase CLI must generate them at execution time; this is an execution requirement, not an implementation ambiguity.

**Type consistency:** UUIDs are used for relational PK/FKs, durable public IDs remain text, confidence is numeric 0–1, user-facing Fit/bag scores are numeric 0–100, currency is char(3), categories reuse `gal_category`, variable configuration/evidence uses JSONB.
