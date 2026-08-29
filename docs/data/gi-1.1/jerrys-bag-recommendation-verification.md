# GI-1.1 Jerry's Bag + Recommendation Auditability Verification

**Verification date:** 2026-08-29  
**Branch:** `feature/golfer-intelligence-v1`  
**Design spec:** `docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md`  
**Phase plan:** `docs/superpowers/plans/2026-08-29-jerrys-bag-recommendation-auditability.md`  
**Execution environment:** disposable local Supabase database in GitHub Actions, PostgreSQL 17.6.x  
**Supabase CLI:** 2.116.0  
**Production modified:** No

## Phase Result

The Jerry's Bag + Recommendation Auditability phase passed its implementation and verification gate.

A clean replay of the sanitized production-shaped baseline plus every GI-1.1 migration completed successfully. The full pgTAP suite reported:

- Test files: **16**
- Assertions: **407**
- Failed assertions: **0**
- Result: **PASS**
- Verification workflow run: **33273608825**

The isolated database advisor gate reported:

- Security Advisors: **No issues found**
- Performance Advisors: **No issues found**
- Advisor workflow run: **33273608687**

The additional database lint completed with no lint errors. It reported one non-blocking `warning extra` in the pre-existing sanitized-baseline compatibility function `public.gal_add_to_my_bag`: unused parameter `p_payload`. The warning predates this phase's Jerry's Bag/recommendation migrations and is retained as baseline technical debt rather than driving an unrelated compatibility change.

## Migrations Verified

This phase adds the following migrations after the completed GI-1.1 Foundation chain:

1. `20260829190421_gi11_bag_history.sql`
2. `20260829191355_gi11_bag_snapshots.sql`
3. `20260829192736_gi11_bag_scenarios.sql`
4. `20260829193815_gi11_bag_scores.sql`
5. `20260829194350_gi11_recommendation_runs.sql`
6. `20260829201429_gi11_recommendation_items.sql`
7. `20260829202202_gi11_recommendation_audit_links.sql`

All migrations are additive to the existing GAL schema. No production data rewrite, destructive rename, or production deployment occurred during this phase.

## Test Suites Verified

The phase-specific pgTAP suites are:

- `gi11_009_bag_history.sql`
- `gi11_010_bag_snapshots.sql`
- `gi11_011_bag_scenarios.sql`
- `gi11_012_bag_scores.sql`
- `gi11_013_recommendation_runs.sql`
- `gi11_014_recommendation_items.sql`
- `gi11_015_recommendation_audit_links.sql`

All earlier Foundation/security suites also replayed and passed in the same 407-assertion run.

## RLS and Mutation Matrix

| Resource | Authenticated golfer | Trusted service path | Evidence model |
| --- | --- | --- | --- |
| `gal_bag_items` | Existing own-bag current-state CRUD remains governed by existing RLS | System access as already governed | Current truth |
| `gal_bag_item_history` | SELECT own only | INSERT through trusted/history mechanism; no ordinary rewrite/delete | Immutable history |
| `gal_bag_snapshots` | SELECT own only | SELECT + INSERT; no UPDATE/DELETE | Immutable snapshot |
| `gal_bag_scenarios` | Own-scenario CRUD subject to state guard; golfer cannot self-mark `ADOPTED` | Trusted adoption routine controls adoption | What-if working state |
| `gal_bag_scenario_items` | Own-scenario item CRUD subject to ownership/state | Trusted adoption consumes scenario items | What-if working state |
| `gal_bag_score_snapshots` | SELECT own only | SELECT + INSERT; no UPDATE/DELETE | Immutable score evidence |
| `gal_recommendation_runs` | SELECT own only | INSERT plus bounded lifecycle/result UPDATE; frozen inputs/version chain guarded; no DELETE | Versioned execution record |
| `gal_recommendation_items` | SELECT own only | SELECT + INSERT; no UPDATE/DELETE | Immutable shortlist evidence |
| `gal_fit_score_components` | SELECT own only | SELECT + INSERT; no UPDATE/DELETE | Immutable deterministic score evidence |
| `gal_decision_snapshots` | SELECT own only | SELECT + INSERT; no UPDATE/DELETE | Immutable decision evidence |

Cross-golfer access denial is covered by the phase test suites. Ownership consistency triggers prevent a recommendation, bag score, or decision from combining one golfer's frozen state with another golfer's evidence.

## Bag Acceptance Mapping

- **GI-BAG-001 — Bag lifecycle history:** `gi11_009_bag_history.sql` verifies additive lifecycle fields and immutable prior-state capture.
- **GI-BAG-002 — Configuration history:** `gi11_009_bag_history.sql` verifies reconfiguration/replacement history preserves prior configuration evidence.
- **GI-BAG-003 — Partial equipment identity:** `gi11_009_bag_history.sql` and `gi11_011_bag_scenarios.sql` verify unknown/partial product identity is valid and no canonical product ID is invented.
- **GI-BAG-004 — Scenario isolation:** `gi11_011_bag_scenarios.sql` verifies OPEN what-if scenarios do not mutate the actual bag.
- **GI-BAG-005 — Explicit adoption:** `gi11_011_bag_scenarios.sql` verifies trusted adoption changes the live bag atomically, preserves history, and writes a post-adoption immutable bag snapshot.
- **GI-BAG-006 — Current-bag integrity:** `gi11_009_bag_history.sql` preserves existing active-bag/club-count validation behavior; snapshots preserve observed state rather than silently correcting history.

## Recommendation Acceptance Mapping

- **GI-REC-001 — Component evidence persisted:** `gi11_014_recommendation_items.sql` verifies deterministic Fit Score components are stored with evidence and model version.
- **GI-REC-002 — Component math reconciles:** `gi11_014_recommendation_items.sql` verifies weighted components reconcile to the stored Fit Score when component weights total 1.0.
- **GI-REC-003 — Reproducible audit chain:** `gi11_015_recommendation_audit_links.sql` verifies decision → recommendation item → recommendation run → frozen profile/bag snapshots.
- **GI-REC-004 — Keep/reconfigure are valid outcomes:** `gi11_014_recommendation_items.sql` verifies `KEEP_CURRENT` and `RECONFIGURE_CURRENT` are first-class recommendation result types.
- **GI-REC-005 — Commerce independence:** `gi11_014_recommendation_items.sql` verifies recommendation/Fit component schemas contain no commission, affiliate-payout, retailer-payout, network-payout, or commerce-score fields.
- **GI-REC-006 — Fit Score bounds:** `gi11_014_recommendation_items.sql` verifies Fit Score is bounded to 0–100 while confidence remains separately bounded to 0–1.

## Reproducibility Chain

GI-1.1 now supports the normalized deterministic chain:

`current/profile evidence → immutable profile snapshot → immutable bag snapshot → recommendation run → recommendation item → Fit Score components → immutable decision snapshot`

Recommendation runs freeze the applicable equipment-data, Fit-model, category-model, guide, question-engine, bag-optimization, and AI-explanation version metadata. Service-side lifecycle updates cannot rewrite the frozen input/version chain.

## Trust and Commerce Boundary

- Fit ranking remains deterministic.
- Confidence is not the Fit Score.
- `KEEP_CURRENT` is a valid result when the golfer's current equipment remains the best recommendation.
- What-if scenarios do not mutate the live bag until explicit trusted adoption.
- Commerce payout information is absent from Fit Score and recommendation ranking records.
- Historical/legacy decision snapshots remain valid without normalized links; new GI-1.1 decisions may use the complete normalized audit chain.

## Phase Exit Decision

**PASS — eligible to proceed to the Longitudinal Intelligence phase.**

The next implementation phase extends the existing `gal_buyer_events` append-only evidence stream and governed `gal_event_catalog`, then builds derived Intelligence State/snapshots. No competing behavior-event table should be introduced.
