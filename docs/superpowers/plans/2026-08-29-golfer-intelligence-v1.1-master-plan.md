# GAL Golfer Intelligence v1.1 Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver GI-1.1 as a sequence of independently testable, additive Supabase and static-site changes that make GAL remember, learn, persist Jerry’s Bag, reproduce recommendations, and preserve the golfer/customer privacy boundary.

**Architecture:** Keep the existing GAL operational tables authoritative, introduce missing governance/history/recommendation entities additively, and migrate Buyer’s Guides to shared canonical golfer intelligence only after the backend contracts are verified. Database migrations and pgTAP tests live in Git; production remains untouched until an immutable RC passes staging verification.

**Tech Stack:** PostgreSQL 17 / Supabase, Row Level Security, pgTAP SQL tests, static HTML/CSS/vanilla JavaScript, GitHub Actions, GitHub Pages.

**Spec:** `docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md`

## Global Constraints

- **Algorithms decide. AI interprets, converses and teaches.**
- `gal_users.id` remains the canonical golfer FK.
- `gal_profile_facts` remains current truth; durable history is separate.
- `gal_bags` + `gal_bag_items` remain authoritative for real current equipment.
- `gal_buyer_events` remains the canonical behavioral event table.
- `gal_catalog_products` remains the canonical cross-category product identity layer.
- GI-1.1 is additive; do not drop or rename existing core golfer tables.
- New golfer-owned tables must enable RLS and pass positive/negative ownership tests.
- Consent history is append-only to normal golfer clients; withdrawal is a new row.
- Recommendation scoring is deterministic and cannot consume affiliate payout or retailer-priority fields.
- Historical recommendations remain tied to immutable profile/bag/data/model versions.
- Customer/subscriber systems never receive direct access to individual golfer operational tables.
- Development/preview data is synthetic; do not copy unsanitized production golfer data.
- Every Buyer’s Guide must pass before RC promotion; Fairway Woods & Hybrids is an explicit regression gate.
- Shared golfer/customer data contracts are updated and verified together when affected.
- Locked brand remains Option 7 GAL Custom Hybrid with GAL Navy `#0B245F` and GAL Orange `#FF5A1F`.
- Production remains unchanged until staging verification and explicit user approval.

---

## Plan Decomposition

GI-1.1 spans multiple independently reviewable subsystems. Implement it through these focused plans in order:

1. `docs/superpowers/plans/2026-08-29-gi-1.1-foundation.md` — Supabase project structure, schema baseline capture, governance catalogs, current facts, history, inferences, questions, consent immutability.
2. `docs/superpowers/plans/2026-08-29-gi-1.1-bag-recommendations.md` — bag history/snapshots/scenarios, profile snapshots, recommendation runs/items/components, decision-snapshot links, deterministic audit tests.
3. `docs/superpowers/plans/2026-08-29-gi-1.1-longitudinal-state.md` — canonical event extension, intelligence state, milestone snapshots, insights, rebuild and conflict tests.
4. `docs/superpowers/plans/2026-08-29-gi-1.1-connected-privacy.md` — external source catalog, connection/sync contracts, provider restriction lineage, consent/privacy gates.
5. `docs/superpowers/plans/2026-08-29-gi-1.1-guide-integration-release.md` — shared browser data client, guide-by-guide migration, registered-user UX, regression matrix, CI/RC/release manifest.

Each focused plan must reach a passing, reviewable checkpoint before the next plan becomes dependent on it.

---

### Task 1: Establish the GI-1.1 baseline record

**Files:**
- Create: `docs/data/gi-1.1/baseline.md`
- Create: `docs/data/gi-1.1/live-schema-baseline.sql`
- Create: `docs/data/gi-1.1/guide-regression-matrix.md`

**Interfaces:**
- Consumes: approved GI-1.1 design spec and the feature-branch commit at plan execution start.
- Produces: immutable human-readable baseline and SQL inspection queries reused by every focused plan.

- [ ] **Step 1: Write the baseline inspection SQL**

Create `docs/data/gi-1.1/live-schema-baseline.sql` with read-only queries for `pg_tables`, `pg_policies`, `pg_indexes`, `information_schema.columns`, FK constraints, and the definition of `gal_current_user_id()` limited to `gal_%` objects.

- [ ] **Step 2: Run the baseline SQL against the non-production development/preview database**

Expected: queries return the existing canonical tables, RLS state, indexes, and identity function without mutating data.

- [ ] **Step 3: Record the feature-branch commit and database baseline**

Create `docs/data/gi-1.1/baseline.md` with exact Git SHA, schema inspection date, Supabase environment label, existing canonical table list, and a statement that production was not modified.

- [ ] **Step 4: Record guide regression cases**

Create `docs/data/gi-1.1/guide-regression-matrix.md` with rows for Golf Ball, Driver, Fairway Woods, Hybrids, Irons, Wedges, and Putter and columns for load, questions, completion, result cards, compare, Buy link, mobile, and runtime errors.

- [ ] **Step 5: Commit**

```bash
git add docs/data/gi-1.1/
git commit -m "docs: capture GI-1.1 implementation baseline"
```

---

### Task 2: Execute focused plan 1 — Foundation

**Files:**
- Plan: `docs/superpowers/plans/2026-08-29-gi-1.1-foundation.md`

**Interfaces:**
- Consumes: Task 1 baseline.
- Produces: Git-controlled `supabase/` migration/test structure plus passing governance/profile/question/consent foundation.

- [ ] **Step 1:** Complete every checkbox in the foundation plan using TDD.
- [ ] **Step 2:** Run the foundation pgTAP suite and migration replay from an empty/synthetic database.
- [ ] **Step 3:** Run Supabase security/performance advisors and record findings in `docs/data/gi-1.1/foundation-verification.md`.
- [ ] **Step 4:** Review the diff before beginning bag/recommendation work.
- [ ] **Step 5:** Commit any verification-only documentation separately with `docs: record GI-1.1 foundation verification`.

---

### Task 3: Execute focused plan 2 — Bag + Recommendation Audit Chain

**Files:**
- Plan: `docs/superpowers/plans/2026-08-29-gi-1.1-bag-recommendations.md`

**Interfaces:**
- Consumes: canonical Fact Catalog/profile provenance from Task 2.
- Produces: immutable bag/profile snapshots, scenario isolation, recommendation execution objects, score-component auditability.

- [ ] **Step 1:** Complete every checkbox in the bag/recommendation plan using TDD.
- [ ] **Step 2:** Prove `GI-BAG-001` through `GI-BAG-006` and `GI-REC-001` through `GI-REC-006` against synthetic users.
- [ ] **Step 3:** Record deterministic run inputs/output hashes in `docs/data/gi-1.1/recommendation-determinism.md`.
- [ ] **Step 4:** Verify changing commerce-only fields cannot change fit ranking.
- [ ] **Step 5:** Review and commit verification evidence.

---

### Task 4: Execute focused plan 3 — Longitudinal State

**Files:**
- Plan: `docs/superpowers/plans/2026-08-29-gi-1.1-longitudinal-state.md`

**Interfaces:**
- Consumes: fact/bag/recommendation durable data.
- Produces: canonical event semantics, rebuildable Intelligence State, milestone snapshots, material insights.

- [ ] **Step 1:** Complete every checkbox in the longitudinal-state plan using TDD.
- [ ] **Step 2:** Prove event normalization and event invalidation without rewriting history.
- [ ] **Step 3:** Delete only a synthetic user’s derived state row, rebuild it, and compare canonical state domains.
- [ ] **Step 4:** Prove partial/degraded state status does not erase durable facts or bags.
- [ ] **Step 5:** Commit state verification evidence.

---

### Task 5: Execute focused plan 4 — Connected Services + Privacy

**Files:**
- Plan: `docs/superpowers/plans/2026-08-29-gi-1.1-connected-privacy.md`

**Interfaces:**
- Consumes: fact provenance, consent ledger, Intelligence State.
- Produces: provider-neutral connection/sync records and enforceable use restrictions.

- [ ] **Step 1:** Complete every checkbox in the connected/privacy plan using TDD.
- [ ] **Step 2:** Run the synthetic handicap-provider normalization test.
- [ ] **Step 3:** Prove revocation blocks future sync while retaining governed provenance.
- [ ] **Step 4:** Prove provider `commercial_aggregate_allowed = false` prevents commercial eligibility propagation.
- [ ] **Step 5:** Prove normal golfer clients cannot update/delete prior consent rows.

---

### Task 6: Execute focused plan 5 — Guide Integration + Release

**Files:**
- Plan: `docs/superpowers/plans/2026-08-29-gi-1.1-guide-integration-release.md`

**Interfaces:**
- Consumes: stable backend contracts from Tasks 2–5.
- Produces: shared browser intelligence client, migrated guide inputs, registered-user persistence, CI regression suite, immutable RC evidence.

- [ ] **Step 1:** Complete guide migration one guide at a time; do not bulk-convert every guide in one commit.
- [ ] **Step 2:** After each guide migration, run its standalone flow plus cross-guide known-fact reuse tests.
- [ ] **Step 3:** Run the full guide regression matrix, with Fairway Woods & Hybrids explicitly verified for hangs/runtime errors.
- [ ] **Step 4:** Verify shared golfer/customer canonical product/data contracts when affected.
- [ ] **Step 5:** Create an immutable RC manifest only after every release-blocking test passes.

---

### Task 7: Final GI-1.1 release-readiness review

**Files:**
- Create: `docs/data/gi-1.1/rc-verification.md`
- Create: `docs/data/gi-1.1/release-manifest.example.json`
- Modify: `GAL_DATA_DEPLOYMENT_MANIFEST.json` only when an actual approved RC is created.

**Interfaces:**
- Consumes: all focused-plan verification evidence.
- Produces: one reviewable release-readiness package; does not itself authorize production promotion.

- [ ] **Step 1: Assemble the RC verification sheet**

Include PASS/FAIL rows for migrations, replay, RLS positive/negative tests, consent immutability, fact history, question reuse, bag history/scenarios, recommendation determinism, commerce independence, state rebuild, connected-source framework, privacy, every guide, Jerry’s Bag, mobile, customer contract, and advisors.

- [ ] **Step 2: Create the release-manifest example**

Use concrete keys:

```json
{
  "release_version": "GI-1.1-RC1",
  "source_commit": "<exact-rc-sha>",
  "schema_version": "GI-1.1",
  "fact_catalog_version": "FACT-1.0",
  "question_engine_version": "QUESTION-1.0",
  "event_catalog_version": "EVENT-1.0",
  "fit_engine_versions": {},
  "bag_optimization_version": "BAG-OPT-1.0",
  "intelligence_state_version": "GI-STATE-1.1",
  "privacy_policy_version": "PRIVACY-AGG-1.0",
  "brand_version": "Option 7 GAL Custom Hybrid"
}
```

The literal `<exact-rc-sha>` is replaced only when the actual RC is cut; the example file must state this is an example template, not an RC manifest.

- [ ] **Step 3: Run a clean review against the design spec**

Expected: every locked design requirement maps to a passing test or an explicitly deferred GI-1.2 item already identified in the spec.

- [ ] **Step 4: Commit the readiness artifacts**

```bash
git add docs/data/gi-1.1/
git commit -m "docs: assemble GI-1.1 release readiness package"
```

- [ ] **Step 5: Stop at the production approval gate**

Do not merge to `main`, apply production migrations, or promote a release until the immutable RC has been reviewed and explicitly approved.

---

## Master Plan Self-Review

### Spec coverage

The five focused plans collectively cover Sections 1–12: governance/profile/questions; bag/recommendations; behavior/state; connected services/privacy; guide integration/registered UX/release governance.

### Placeholder scan

No implementation instruction uses `TBD` or `TODO`. The release-manifest SHA placeholder is explicitly confined to an example template and is replaced only when an actual immutable RC exists.

### Type/interface consistency

All focused plans use the same canonical table names and version families defined in the approved spec. Later plans consume outputs from earlier plans rather than creating parallel identity/profile/bag/event models.
