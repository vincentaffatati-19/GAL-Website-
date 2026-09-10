# UX10 Profile Recommendations v1 — Implementation Plan

1. Add a failing contract test for engine version, Profile revision linkage, canonical product identity, cross-category top-of-bag ranking, and internal-status non-leakage.
2. Bring the governed Fairway/Hybrid data projection and media resolver into the integration branch alongside the existing Driver projection/resolver.
3. Add a Profile adapter for the UX10 `gal_profile_snapshot()` contract, with a staging-only preview fallback when no authenticated frontend client exists.
4. Add `GAL-REC-1.0` recommendation engine. Keep recommendation rules separate from product masters; return canonical IDs and recommendation metadata only.
5. Build the recommendation UI with Bag Needs as default and Equipment Categories as secondary view. Hydrate product details from authoritative projections, not recommendation objects.
6. Preserve common bag behavior: canonical IDs, shared adapter boundary, compare up to three, duplicate-category warning, 14-club guard, missing price as em dash.
7. Verify Node syntax and contract tests, inspect diff against UX10 integrated RC, deploy through Git-connected Vercel preview, and open a staging PR without merging.
