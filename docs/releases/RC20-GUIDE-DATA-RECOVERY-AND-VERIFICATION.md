# GAL Buyers Guides — recovery and verification gate (2026-11-03)

## Newly recovered authoritative Fairway/Hybrid sources
- `recovery/fairway-hybrids-STANDALONE-REVIEW.html`: actual six-question guide with FH_FIT_0.3_GOVERNED scoring, comparison, fit/value/confidence, 71 embedded product configurations.
- `recovery/fairway-hybrid-catalog-71.json`: parsed standalone catalog, 71 unique IDs, 49 fairways + 22 hybrids, zero missing IDs, brand, model, category or loft.
- `recovery/GAL-Fairway-Hybrid-Master-v2.1-Image-Governance-FINAL.csv`: recovered governed image master, 71 unique IDs, 68 VERIFIED_REVIEW_ASSET, 3 SOURCE_RECOVERY_HOLD (GAL-FH-0069..0071).

## Recovered RC19 package
- Drivers 64 records, Irons 117, Putters 369, Wedges 227 (777 combined). These records require scoring and rendering verification; their presence alone is not proof of functionality.
- Existing RC19 fairway-hybrids.html is *not* the functional historical guide; it is intake-only. Do not promote it as complete.
- Existing Golf Ball Guide is the reference, but still requires independent runtime acceptance.

## Executed local checks
- `python assets/tools/validate-buyers-guide-consistency.py`: PASS for six guide contract imports, market imports, no GPS, no manual market selection.
- `node --test tests/test_rc15_driver_scoring_regression.js`: PASS.
- `pytest -q tests`: 9 passed, 2 failed; both failures are historical RC15 assertions incompatible with intentional RC16+ changes (Putter SHA and account-deletion migration). These must be rebaselined with governance, not silently removed.
- Playwright/Chromium navigation was attempted, but runtime blocks both localhost HTTP and file:// with ERR_BLOCKED_BY_ADMINISTRATOR. Browser end-to-end testing NOT achieved; do not claim PASS.

## Hard gate before another review candidate
1. Integrate recovered 71-record FH guide with locked Option 7A Motion brand, UX11 navigation, shared market and My Bag contract; preserve 3 image holds, no fabricated fallback.
2. Verify each guide loads real catalog and generates top 3 for representative profiles, including mobile, empty/unknown answers, and My Bag save.
3. Verify original 50-case UX11 profile routing, 12 Body, 12 Swing, senior/unknown age, handedness, and account flows.
4. Complete browser acceptance in an accessible staging environment; isolated GitHub preview only; production untouched.

Status: RECOVERY PROGRESS, NOT RELEASE APPROVAL.
