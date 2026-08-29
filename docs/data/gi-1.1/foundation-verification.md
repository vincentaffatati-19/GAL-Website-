# GAL Golfer Intelligence v1.1 — Foundation Verification

**Verification date:** 2026-08-29  
**Branch:** `feature/golfer-intelligence-v1`  
**Design:** `docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md`  
**Implementation plan:** `docs/superpowers/plans/2026-08-29-gi-1.1-foundation.md`

## Verification result

**FOUNDATION GATE: PASS**

The GI-1.1 Foundation was replayed from a sanitized production-shaped GAL baseline into a disposable PostgreSQL 17 / Supabase environment. No production golfer data, credentials, or historical import secrets are included in the repository test baseline. All forward migrations were applied in timestamp order and the complete pgTAP suite passed.

- PostgreSQL runtime: 17.6.x Supabase local image
- Supabase CLI: 2.116.0
- Verification workflow: `.github/workflows/gi-backend-tests.yml`
- GREEN run: GitHub Actions run `33265239503`, job `99134040027`
- Test files: 9
- Assertions: 192
- Result: **192 / 192 PASS**
- Security advisor replay: **No issues found**
- Performance advisor replay: **No issues found**
- Production schema/data modified by this work: **No**

## Forward migration chain verified

1. `20260829090000_gi11_governance_catalogs.sql`
2. `20260829091000_gi11_seed_fact_catalog.sql`
3. `20260829092000_gi11_extend_profile_facts.sql`
4. `20260829154752_backend_readiness_hardening.sql`
5. `20260829162713_gi11_profile_fact_history.sql`
6. `20260829163759_gi11_inferences.sql`
7. `20260829164938_gi11_questions.sql`
8. `20260829164940_gi11_seed_questions.sql`
9. `20260829170324_gi11_consent_governance.sql`
10. `20260829171648_gi11_profile_snapshots.sql`

## Test suites verified

1. `000_backend_security_readiness.sql`
2. `gi11_001_structure.sql`
3. `gi11_002_fact_catalog.sql`
4. `gi11_003_profile_facts.sql`
5. `gi11_004_fact_history.sql`
6. `gi11_005_inferences.sql`
7. `gi11_006_questions.sql`
8. `gi11_007_consent.sql`
9. `gi11_008_profile_snapshots.sql`

## Foundation contracts verified

### Governance catalogs

`gal_fact_catalog`, `gal_question_catalog`, `gal_event_catalog`, `gal_model_registry`, and `gal_external_source_catalog` are governed reference structures. RLS is enabled and normal authenticated users do not receive direct write access.

### Canonical golfer facts

`gal_profile_facts` remains the current-truth table with one row per `(user_id, fact_key, scope)`. GI-1.1 adds provenance, confidence, value state, catalog/version, privacy/commercial classification, and source metadata without removing the legacy source fields during expand-and-contract migration.

Only cataloged fact keys are accepted by the Foundation migration path. FACT-1.0 contains the approved initial canonical vocabulary.

### Immutable fact history

Prior current-fact values are preserved in `gal_profile_fact_history`. Golfers may read only their own history and may not directly modify or delete history evidence. Current fact changes are captured atomically through the governed mutation/history mechanism.

### Inference provenance

`gal_inferences` preserves inferred values/ranges, confidence, evidence, model/version provenance, lifecycle status, and privacy/commercial classification. Golfers may read only their own inference records and may confirm or reject an inference through scoped lifecycle functions without rewriting the original evidence, value, confidence, or model provenance.

### Question and response history

The Question Catalog is versioned and linked to canonical Fact Catalog semantics. Responses preserve exact question version and source/session context. Explicit unknown states and the approved driver-speed-to-driver-carry proxy path are supported. Response evidence is historical rather than silently overwritten.

### Consent ledger

`gal_consent_records` is append-only for normal authenticated golfers. Golfers may SELECT and INSERT their own consent history but cannot UPDATE or DELETE prior consent records or create records for another golfer. GI-1.1 adds `interface`, `jurisdiction`, and structured `metadata`, and adds the approved consent classes without removing existing values.

### Immutable profile snapshots

`gal_profile_snapshots` preserves recommendation-time fact and inference state for deterministic replay. The owning golfer has SELECT-only access. Normal authenticated clients cannot INSERT, UPDATE, or DELETE snapshots. The trusted service path may INSERT snapshot evidence but is not granted UPDATE or DELETE, preserving immutability after capture.

## Security readiness outcomes

The Foundation branch resolves the database-level issues identified during readiness review:

- `gal_parse_set_club_count(text)` receives a fixed search path.
- authenticated/browser clients cannot directly execute privileged `gal_add_to_my_bag(jsonb)`; trusted service execution remains available.
- the obsolete temporary import RPC is removed without publishing its historical secret-bearing implementation.
- consent history is select + append rather than broad self-ALL access.
- exposed GI golfer tables use explicit grants plus RLS ownership policies.
- privileged internal history operations are kept outside the exposed `public` schema where definer privileges are required.

An isolated replay of the complete Foundation schema returned **No issues found** from both Supabase security and performance advisors.

## Account/platform prerequisites outside this migration chain

The existing Supabase Auth project setting for leaked-password protection was previously observed as disabled. This is an account-level Auth configuration rather than a GI-1.1 database migration and remains a **required pre-launch control before onboarding real registered golfers**.

Existing equipment-data performance items outside the GI Foundation scope should continue to be tracked separately; no Foundation migration removes existing production indexes based only on low/zero current usage.

## Environment and data-safety statement

The automated test environment is disposable and reconstructed from sanitized structural baselines plus Git-controlled forward migrations. Production golfer data is not copied into the test environment. Historical SQL containing temporary import secrets is intentionally excluded from the public repository and represented only by sanitized compatibility fixtures where necessary.

No migration in this Foundation package has been applied to production. Promotion remains subject to the governed `feature → develop → release → protected main` flow and later staging/RC verification.

## Foundation exit criteria

The Foundation phase is accepted for progression because:

- governance catalogs exist and are protected;
- canonical current facts are catalog-governed;
- prior fact values are reproducible;
- inferences retain evidence and model provenance;
- questions and responses are versioned/reusable;
- consent history is append-only;
- recommendation-time profile snapshots are immutable;
- all 192 Foundation assertions pass from a clean replay;
- isolated Supabase security and performance advisors report no issues; and
- production remains unchanged.

**Next implementation phase:** Jerry’s Bag history/scenarios and recommendation auditability, following the approved GI-1.1 implementation plan and the same RED → minimal implementation → GREEN discipline.
