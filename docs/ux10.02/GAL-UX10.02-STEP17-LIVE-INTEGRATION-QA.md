# GAL UX10.02 — STEP 17 Live Staging Integration QA

**Status:** PASS — staging/review candidate  
**Date:** 2026-09-07  
**Candidate:** `GAL-UX10.02-STEP17.2-RC3.html`

## Scope
STEP 17 connects the approved UX10.02 profile candidate to the governed GAL staging location service without changing the approved controlled-field or Dynamic Golfer Visual System design.

## Runtime correction made during integration
The previously approved RC2 had the correct senior male/female Body mappings, but the `GOLFER_VISUAL_MANIFEST` constant had been accidentally omitted during the RC2 correction. The browser regression exposed the missing constant before release. RC3 restores the manifest while preserving the approved RC2 senior mappings.

## Browser acceptance test — PASS
The browser regression exercised the integrated profile flow using staging-shaped responses validated directly against the connected Supabase project.

Verified:
- Dynamic golfer resolver: Female + 65–74 + Left-handed resolves to `female_senior` for Body and Swing and applies left-handed mirroring.
- Country → Region → City search is region-aware.
- Madison, WI / May–October preview displays governed staging values.
- Saving Madison writes structured location plus derived environment into the longitudinal browser review state.
- Madison → Bari retires prior location-specific environmental facts.
- Bari, Puglia / Year-round displays the governed Bari environment.
- Changing to an unindexed city retains the structured golfer-entered location while leaving all environmental facts unknown.
- No prior city `placeId`, GeoNames ID, coordinates, elevation, temperature, wind, humidity, precipitation, seasonality, or override note remains active after the unindexed-city change.
- Buyer Guide consumer snapshot uses the same profile revision and active facts.
- Browser persistence/restoration passes.
- 0 console errors.
- 0 page errors.

## Direct staging service verification — PASS
Connected Supabase validation confirmed:

### Madison, Wisconsin
`gal_location_city_search('Mad','US','WI',10)` resolved Madison / GeoNames 5261457.

`gal_location_preview('US','WI','Madison','may_oct')` returned:
- elevation: 873 ft
- typical temperature: 63.4 °F
- typical wind: 9.4 mph
- typical humidity: 76.3%
- precipitation: 0.134 in/day
- NASA POWER confidence: 0.88
- NASA POWER API version: v2.9.7
- climatology range: January 2001–December 2020

### Bari, Puglia
`gal_location_city_search('Bari','IT',null,10)` resolved Bari / GeoNames 3182351 / Puglia region code 13.

`gal_location_preview('IT','13','Bari','year_round')` returned:
- elevation: 16 ft
- typical temperature: 62.6 °F
- typical wind: 10.0 mph
- typical humidity: 71.9%
- precipitation: 0.067 in/day
- NASA POWER confidence: 0.88

## Staging coverage observed
- `public.gal_places`: 34 rows
- `public.gal_place_environment_normals`: 238 rows
- `public.gal_location_sources`: 2 rows

## Governance boundary
- Browser uses a Supabase **publishable** key only.
- No service-role credential is embedded in the candidate.
- Authenticated profile writes remain governed by STEP 14 RPCs.
- No public Nominatim production dependency.
- This is staging/review only; no production promotion was performed.
