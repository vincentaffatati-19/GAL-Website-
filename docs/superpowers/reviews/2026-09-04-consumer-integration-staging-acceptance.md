# GAL Consumer Integration Staging Acceptance

**Date:** 2026-09-04  
**Branch:** `consumer-integration-wave3`  
**Integration base:** `portal-integration-plan` at `ed6f24668502f5126535adf9f72933520e26622b`  
**Scope:** Wave 3 / Task 11 staging acceptance for Consumer Integration  
**Production:** NOT PROMOTED

## Status

**CONDITIONAL — all application/database gates passed; exact-head Vercel preview pending because the Hobby project hit its build-rate limit immediately after Wave 2.**

No production Supabase migration or production deployment is authorized by this record.

## Verified Application Gate

Wave 2 final head `97eca50702c34280888fc77c0da90d5de512d903` passed GitHub Actions run `33833156177`:

- 18/18 Vitest files passed.
- 40/40 tests passed.
- TypeScript compilation passed.
- Vite production build passed.
- Browser bundle service-role scan passed.
- CI repository permission remained read-only.
- Dynamic golfer/database content is HTML-escaped by shared rendering utility.

The tests cover My Bag unknown/missing configuration behavior, Driver target-before-brand ordering, limited/readiness handling, Guide/AI Fit shared truth, Tell GAL Once reuse, golfer-safe Today/Insights/Progress mappings, subscriber/registered analytical invariants, commercial-consent browser behavior, and architecture guards.

## Staging Database Acceptance

Project: `ylrxwtbzavhxxpoqqmho`.

Verified:

- `COMMERCIAL_AGGREGATE` is a separate consent purpose from ordinary product use and `ANALYTICS_OPTIONAL`.
- Commercial eligibility requires latest `ANALYTICS_OPTIONAL=ACCEPTED` and latest `COMMERCIAL_AGGREGATE=ACCEPTED`.
- Withdrawal removes future commercial eligibility without deleting consent history.
- Consent records remain append-only to authenticated browser users.
- `gal_commercial_aggregate_eligible_users_v` is not selectable by `anon` or `authenticated`.
- Anonymous users retain execute access to `gal_public_equipment_guide()`.
- Authenticated users retain execute access to `gal_authenticated_equipment_ai_fit()`.
- Two-user RLS simulation confirmed one authenticated golfer could not read the other golfer's `gal_bags`, `gal_profile_facts`, or `gal_consent_records` rows.

## Security / Performance Advisors

Staging security advisor: only `auth_leaked_password_protection` warning. This is the previously known Supabase plan-level launch blocker; no paid change is authorized here. Remediation reference: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

Staging performance advisor: INFO-only unused-index notices. These are expected on a low/zero-traffic staging database and are not release blockers; no indexes are removed without observed workload evidence.

## Production Boundary Verification

Production project `hgfquqdsdtyboacwmuoq` was checked after Wave 2. It does **not** contain the `COMMERCIAL_AGGREGATE` consent enum value or `gal_commercial_aggregate_eligible_users_v`. Production therefore remains unchanged by Consumer Integration Wave 2/3.

Production security advisor remains the same known leaked-password warning. Production performance advisor remains INFO-level unused-index notices.

## Consumer Scenarios Covered

1. Anonymous Driver Guide — public governed Guide contract and no authenticated personalization requirement.
2. Registered golfer with incomplete Driver configuration — My Bag renders `Configuration details needed`; missing information is never represented as good fit.
3. Registered golfer with limited Driver evidence — fitting distinguishes limited evidence and does not replace missing evidence with assumptions.
4. Subscriber golfer with AI-Fit-ready evidence — subscriber capability flags do not alter equipment facts, readiness, compatibility, or analytical ordering.

Commercial metadata is downstream of the analytical fit path and cannot change candidate ordering in the consumer model/tests.

## Preview / Deployment Evidence

Earlier Wave 2 preview deployments are READY, including deployment `dpl_W2yrZ72zL2PxE9eXDL3W3hjPoxCi` for commit `28dd015605c27f307a4098b22d971881ec753b38`.

The exact merged integration commit `ed6f24668502f5126535adf9f72933520e26622b` received a Vercel build-rate-limit failure (`upgradeToPro=build-rate-limit`). This is an infrastructure quota condition, not a test/build failure. Wave 3 remains CONDITIONAL until an exact-head preview is READY and can be smoke-tested.

### Rerun request

A documentation-only commit was pushed on 2026-09-04 to trigger a fresh Vercel preview without changing application code. The resulting branch head remains code-equivalent to the verified Wave 2 integration and is the exact candidate for the rerun smoke test.

## Rollback

- Code: do not merge Wave 3 review records if final acceptance fails; Wave 2 integration merge can be reverted by normal Git rollback if required before production promotion.
- Staging database: commercial-consent changes are additive and staging-only. Production has not received them.
- Production: no rollback required because production was not promoted.

**PRODUCTION NOT PROMOTED.**