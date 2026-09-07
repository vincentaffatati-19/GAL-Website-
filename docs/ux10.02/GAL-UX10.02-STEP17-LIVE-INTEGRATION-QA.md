# GAL UX10.02 — STEP 17 Live Staging Integration QA

**Status:** PASS — staging/review candidate  
**Date:** 2026-09-07  
**Candidate:** `GAL-UX10.02-STEP17.2-RC3.html`

## Scope
STEP 17 connects the approved UX10.02 profile candidate to the governed GAL staging location service without changing the approved controlled-field or Dynamic Golfer Visual System design.

## Runtime correction made during integration
The approved RC2 preserved the corrected senior male/female Body mappings, but its `GOLFER_VISUAL_MANIFEST` constant was accidentally omitted. A regression test failed first, the complete 12-persona manifest was restored, and the same test passed. RC3 preserves the approved RC2 senior mappings.

## Fresh browser acceptance test — PASS
The final browser regression exercised:
- Male/Female Junior
- Male/Female 18–34
- Male/Female 35–54
- Male/Female 55–64
- Male/Female 65+, including 65–74 and 75+
- neutral adult and neutral junior fallbacks
- left-handed mirroring in Body and all four Swing frames
- Madison, WI / May–October preview and save
- golfer wind override of 15 mph
- Madison → Bari retirement of old derived and override facts
- Bari, Puglia / Year-round preview and save
- Bari → `Unindexed Test City`
- unindexed city remains saved as structured golfer-entered location
- all active place ID, GeoNames ID, coordinates, elevation, temperature, wind, humidity, precipitation, and seasonality are cleared/retired for the unindexed city
- My GAL, Buyer Guides, Subscriber Portal and Insights receive the same profile revision

Browser result:
- 0 page errors
- 0 console errors
- PASS

## Direct staging service verification
Connected staging verification confirmed:
- Madison → GeoNames 5261457, elevation 873 ft
- Madison May–October → 63.4 °F, 9.4 mph wind, 76.3% humidity, 0.134 in/day precipitation
- Bari → GeoNames 3182351, Puglia region code 13, elevation 16 ft
- Bari Year-round → 62.6 °F, 10.0 mph wind, 71.9% humidity, 0.067 in/day precipitation
- NASA POWER confidence 0.88
- NASA POWER API v2.9.7
- staging coverage: 34 governed places / 238 environment rows
- refresh queue: 28 SUCCEEDED

## Governance boundary
- Browser uses a Supabase publishable key only.
- No service-role credential is embedded in the candidate.
- Authenticated profile writes remain governed by STEP 14 RPCs.
- No public Nominatim production dependency.
- Staging/review only; no production promotion.
