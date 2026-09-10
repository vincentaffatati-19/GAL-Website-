# GAL UX10.02 Profile Recommendations v1 — QA Handoff

**Status:** STAGING CANDIDATE — CODE / DATA / AUTH CONTRACTS PASS; NO PRODUCTION MERGE

## Recommendation architecture
- Engine contract: `GAL-REC-1.0`.
- Default view: Bag Needs.
- Secondary view: Equipment Categories.
- Driver is a dedicated bag need.
- Top-of-bag distance ranks Fairway Woods and Hybrids together before category filtering.
- Recommendation outputs contain canonical product IDs and fit metadata; product identity, price and media hydrate from governed equipment projections.

## Equipment image state
- Fairway/Hybrid canonical records: 71.
- Fairway Woods: 49; Hybrids: 22.
- `VERIFIED_REVIEW_ASSET`: 68.
- Terminal holds: 3, all Mizuno ST-MAX 230 Fairway (`GAL-FH-0069`–`0071`).
- All 19 Titleist GTS2/GTS3/GT1/GT2/GT3 records were remediated from recovered OEM-controlled high-resolution originals and persisted as record-specific 1200×1200 WebP derivatives.
- No retailer or guessed image fallback is used.

## Profile/auth boundary
- Browser client uses the Supabase publishable key only; no service-role secret is shipped.
- Authenticated identity is verified before calling `gal_profile_snapshot()`.
- `gal_profile_snapshot()` remains authenticated-only.
- Unauthenticated users receive a sign-in state; no demo/preview Profile is substituted.
- Authenticated users with zero active Profile facts receive a clearly labeled preliminary recommendation state.
- New Auth users are provisioned into `public.gal_users` by private `SECURITY DEFINER` trigger migration `20260910001929_ux10_profile_auth_provisioning`.
- Provisioning function execute privilege is restricted to `postgres`.

## Fresh local contract verification
```text
PASS recommendation engine contracts
PASS recommendation runtime contracts
PASS recommendation authenticated profile contract
PASS Titleist fairway/hybrid remediation contract
```

Syntax verification passed for recommendation Supabase/profile/app modules and Fairway/Hybrid data/media modules.

## Supabase verification
- Staging project: GAL Longitudinal Staging.
- Migration `20260910001929_ux10_profile_auth_provisioning` registered successfully.
- Security advisor reports only the project-level leaked-password-protection warning; this recommendation flow uses passwordless email auth.
- Performance advisor reports only existing unused-index informational notices.

## Release disposition
Keep PR #41 unmerged until staging review is accepted. Do not promote directly to production.
