# GAL Equipment Knowledge — Staging Acceptance Review

Date: 2026-09-03 / 2026-09-04 UTC
Branch: `equipment-knowledge-schema-implementation`
Base: `portal-integration-plan`
Production promotion: **NOT AUTHORIZED / NOT PERFORMED**

## Scope

This review records execution evidence for the approved Equipment Knowledge Supabase migration plan:

`docs/superpowers/plans/2026-09-03-gal-equipment-knowledge-schema-migration.md`

All database DDL/migration execution in this phase was performed against staging project `ylrxwtbzavhxxpoqqmho` only. Production project `hgfquqdsdtyboacwmuoq` was queried read-only for legacy schema inventory and was not mutated.

## Implemented Migration Sequence

1. `20260904010000_equipment_wave_a_schema_parity.sql`
2. `20260904011000_equipment_wave_b_canonical_core.sql`
3. `20260904012000_equipment_wave_b_evidence_ontology.sql`
4. `20260904013000_equipment_wave_c_configuration_compatibility.sql`
5. `20260904014000_equipment_wave_c_testing_derivations.sql`
6. `20260904015000_equipment_wave_c_readiness_governance.sql`
7. `20260904016000_equipment_media_governance.sql`
8. `20260904017000_equipment_consumer_views.sql`
9. `20260904018000_equipment_driver_legacy_normalization.sql`
10. `20260904019000_equipment_bag_profile_links.sql`
11. `20260904020000_equipment_security_performance_hardening.sql`
12. `20260904020100_equipment_view_security_invoker.sql`
13. `20260904020200_equipment_private_read_contracts.sql`
14. `20260904020300_equipment_fk_index_completion.sql`
15. `20260904020400_equipment_compatibility_evaluation_gate.sql`

## Test / Review Assets

The branch contains SQL verification assets for schema parity, canonical identity, evidence/ontology, compatibility, testing/derivation, readiness, media governance, consumer views, legacy normalization, My Bag/Profile linkage, security/performance, compatibility-evaluation gating, and full release acceptance.

## Verified Findings

### Schema and Data Isolation
- Required production legacy/reference schema was reproduced in staging without copying production golfer/catalog data.
- Fresh staging count check returned zero rows in `gal_catalog_products`, `gal_driver_master_registry`, normalized equipment families, legacy reconciliation, `gal_bags`, and `gal_profile_facts` before rollback-only synthetic fixtures.
- Legacy tables remain available for rollback/read-path recovery.

### Canonical Equipment / Evidence
- Canonical family/variant/component structures exist.
- Evidence ontology, source records, observations, conflicts and approved characteristics exist.
- Validated observations are immutable and must be superseded rather than rewritten.
- Legacy driver payloads remain raw source lineage; no marketing payload is automatically promoted to analytical truth.

### Configuration Safety
- `UNVERIFIED_INVALID` configurations cannot enter the fitting-eligible view.
- Hard compatibility rules require explicit PASS evaluation.
- Unknown hard-rule compatibility blocks eligibility.
- Synthetic acceptance verified: no rule -> eligible; active hard rule with no evaluation -> blocked; PASS -> eligible; FAIL -> blocked.

### Testing / Derivations
- Physical sample -> tested configuration -> test session -> observation -> derivation structures exist.
- Family-level derivation requires approved generalization methodology.
- Validated test observations are immutable/superseded rather than overwritten.

### Readiness / Evidence Gaps
- Use-case readiness tables support `CATALOG_READY`, `GUIDE_READY`, `AI_FIT_LIMITED`, `AI_FIT_READY`.
- `AI_FIT_READY` is constrained to zero blocking gaps.
- Evidence Gap Queue structures exist.

### Media
- Media rights/provenance are separated from analytical knowledge.
- Production media view excludes `PUBLIC_REFERENCE_ONLY` and `UNVERIFIED_RIGHTS`.

### One Equipment Truth
Rollback-only synthetic acceptance returned:
- Buyers Guide row present: yes
- AI Fit row present: yes
- invalid configuration fitting-eligible: no
- shared approved characteristics equal between Guide and AI Fit: yes

### Security / RLS
- Internal/global equipment tables are not directly readable/mutable by browser roles.
- Public Guide contract: anon + authenticated can execute `gal_public_equipment_guide()`.
- Authenticated AI Fit contract: authenticated can execute; anon cannot.
- All underlying equipment views are `security_invoker`.
- Privileged readers are isolated in non-exposed `gal_private` schema behind public SECURITY INVOKER wrappers.
- Two-user authenticated JWT simulation verified each golfer sees only their own synthetic My Bag row. Fixture transaction was rolled back.

### Security Advisor
After remediation, the only security advisor warning is the pre-existing Supabase Auth leaked-password-protection warning. No new Equipment Knowledge security errors/warnings remain.

Reference: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

### Performance Advisor
- All new `unindexed_foreign_keys` findings were remediated.
- Remaining advisor notices are `unused_index` INFO findings on low/zero-traffic staging tables and pre-existing longitudinal tables; these are not treated as removal candidates before representative traffic exists.
- Representative Guide and AI Fit EXPLAIN plans use canonical product, approved characteristic, readiness, media, configuration, compatibility and rule-evaluation indexes.
- Legacy reconciliation lookup uses `gal_equipment_legacy_recon_product_idx`.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

### Rollback
- Legacy driver registry remains present and readable by privileged/server paths.
- Rollback smoke fixture verified legacy read path without deleting or reversing the new schema.
- No legacy analytical authority has been deleted.

## Final Fresh Acceptance

A single rollback-only staging acceptance executed after all remediations and returned:

`PASS: equipment knowledge staging acceptance`

It covered:
- structural presence;
- security-invoker boundaries;
- browser role grants;
- staging data isolation;
- one-truth Guide/AI Fit behavior;
- hard compatibility unknown/PASS/FAIL behavior;
- readiness constraints;
- media rights filtering;
- legacy rollback path;
- two-user golfer RLS isolation.

## Self-Review Against Approved Plan

No approved logical layer is omitted:
- Wave A preserve/reconcile: implemented and staged.
- Wave B canonical/evidence core: implemented and staged.
- Wave C configuration/testing/readiness/media: implemented and staged.
- Wave D legacy normalization, shared contracts, My Bag/Profile continuity and hardening: implemented and staged.

The production gate remains intentionally unexecuted. Existing production consumers have not been switched. No production migrations have been applied.

## Review Gate

Before production promotion, require explicit user approval of:
- this implementation branch / PR;
- the exact 15-migration production sequence;
- production read-only baseline checks;
- production post-migration acceptance and rollback procedure.
