# GAL UX10.02 — STEP 18 Integrated Staging QA

**Status:** PASS — ready for human release-candidate review  
**Date:** 2026-09-07  
**Release candidate:** `GAL-UX10.02-STEP18-STAGING-RC.html`

## Integrated scope
STEP 18 verifies the approved UX and the governed staging services together:
- controlled profile fields
- Dynamic Golfer Visual System
- longitudinal profile fact precedence/history
- profile revisions and audit events
- live governed location resolution and climate enrichment
- location-change retirement behavior
- consumer/profile snapshot consistency
- persistence and unknown-data behavior

## Transactional staging acceptance test — PASS
The database acceptance scenario ran under an authenticated existing staging GAL user **inside a transaction and rolled back**.

Sequence:
1. Self-Reported driver speed = 95 mph.
2. MEASURED launch-monitor driver speed = 94.7 mph.
3. Later Self-Reported driver speed = 101 mph.
4. Playing location = Madison, WI / May–October.
5. Golfer environment override added.
6. Playing location changed to Bari, Puglia / Year-round.
7. Playing location changed to `Unindexed Test City`.

Final in-transaction assertions:
- authoritative driver speed = **94.7 mph**
- authoritative quality = **MEASURED**
- driver speed history count = **3**
- active city = **Unindexed Test City**
- active derived environmental fact count = **0**
- location-specific facts retired for city changes = **21**
- profile revision = **11**
- profile revision ledger rows = **11**
- audit ledger rows = **11**
- `gal_profile_snapshot()` revision = **11**
- snapshot city = **Unindexed Test City**

This verifies that a lower-quality later self-report cannot overwrite a measured fact, historical records remain preserved, city changes retire stale environment, unknown locations remain unknown, and the consumer snapshot reflects the same active profile revision.

## QA residue — PASS
After rollback:
- `gal_profile_facts` = 0 QA rows
- `gal_profile_revisions` = 0 QA rows
- `gal_profile_audit_events` = 0 QA rows

No test profile data was persisted.

## Browser integration — PASS
The STEP 17 browser acceptance test is part of this release gate:
- dynamic visual synchronization passes
- Madison → Bari → unindexed city passes
- no stale environment leak
- same-revision consumer snapshot passes
- persistence passes
- 0 console errors
- 0 page errors

## Visual / approved-design integrity
- RC2 → RC3 `<header>` block is byte-for-byte equal.
- Corrected senior male/female mappings from approved RC2 are retained.
- RC3 adds only the missing visual manifest required for correct runtime behavior.
- STEP18 file changes only the document/review label from RC3; the UX/service behavior is unchanged.

## Security advisor
No STEP 17/18 schema/RLS issue was reported. One existing project-level production blocker remains:

**Supabase Auth — Leaked Password Protection Disabled**

This should be enabled before production golfer authentication is opened.
Official remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Performance advisor
Only INFO-level `unused_index` notices were returned. These are expected for lightly used/new staging tables and are not release-candidate blockers. No missing foreign-key/index or RLS issue was surfaced in this pass.

## Release decision
**STEP 18 staging verification: PASS.**

The candidate is suitable for founder/human review. It is **not approved for production promotion yet**. Production promotion should require:
1. explicit release approval,
2. Supabase leaked-password protection enabled before golfer auth,
3. normal GAL release-branch / staging-to-production governance.
