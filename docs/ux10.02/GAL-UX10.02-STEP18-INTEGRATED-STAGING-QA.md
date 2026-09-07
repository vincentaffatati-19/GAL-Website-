# GAL UX10.02 — STEP 18 Integrated Staging QA

**Status:** PASS — ready for human release-candidate review  
**Date:** 2026-09-07  
**Release candidate:** `GAL-UX10.02-STEP18-STAGING-RC.html`

## Integrated scope
STEP 18 verifies the approved UX and governed staging services together:
- controlled profile fields
- Dynamic Golfer Visual System
- longitudinal fact precedence/history
- profile revisions and audit events
- live governed location resolution and climate enrichment
- location-change retirement
- unknown-data behavior
- downstream snapshot consistency

## Fresh transactional staging acceptance test — PASS
The acceptance scenario ran under an authenticated GAL staging context inside a database transaction and was rolled back.

Sequence:
1. Driver speed = 95 mph SELF_REPORTED.
2. Driver speed = 94.7 mph MEASURED.
3. Later driver speed = 101 mph SELF_REPORTED.
4. Location = Madison, WI / May–October.
5. Golfer wind override = 15 mph.
6. Location = Bari, Puglia / Year-round.
7. Location = `Unindexed Test City`.

Final in-transaction assertions:
- authoritative driver speed = **94.7 mph**
- authoritative quality = **MEASURED**
- driver history = 95 SUPERSEDED / 94.7 ACTIVE / 101 RECORDED_ONLY
- active city = **Unindexed Test City**
- active derived geographic/environment fact count = **0**
- facts retired with `primary_location_changed` = **20**
- profile revision = **11**
- revision ledger rows = **11**
- audit ledger rows = **11**
- `gal_profile_snapshot()` revision = **11**
- snapshot city = **Unindexed Test City**

This confirms that a later lower-quality self-report cannot overwrite a measured fact, historical facts remain preserved, city changes retire stale location intelligence, and an unresolved city does not inherit prior environment data.

## QA residue — PASS
Fresh post-rollback query:
- profile facts = 0
- profile revisions = 0
- profile audit events = 0

No profile QA residue persisted.

## Browser integration — PASS
Fresh RC3 browser gate:
- complete gender/age/handedness routing matrix passes
- Madison → Bari → unindexed city passes
- no stale environment leakage
- same-revision consumer snapshots pass
- 0 console errors
- 0 page errors

## Staging coverage
- 34 governed places
- 238 governed environment rows
- 28 successful refresh jobs

## Security advisor
No STEP 17/18 schema/RLS defect was reported. One existing project-level production blocker remains:

**Supabase Auth — Leaked Password Protection Disabled**

This should be enabled before public golfer authentication is opened.
Official remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Performance advisor
Only INFO-level `unused_index` notices were returned. No new missing-FK/index or RLS blocker was surfaced.

## Release decision
**STEP 18 staging verification: PASS.**

The candidate is suitable for founder/human release review. It is not approved for production promotion. Production promotion still requires explicit approval, the normal GAL `release/*` governance path, and Auth leaked-password protection before public golfer authentication.
