# GAL UX10.02 — STEP17.3 Dynamic Golfer Visual V3 QA

**Candidate:** `GAL-UX10.02-STEP17.3-DYNAMIC-VISUAL-RC.html`  
**Date:** 2026-09-08  
**Status:** **REVIEW CANDIDATE PASS — PRODUCTION PROMOTION BLOCKED**

## Executive result

The STEP17.3 integration contract passes all automated resolver, handedness, persistence, and browser-rendering checks. Twelve unique Body routes and twelve unique Swing-plate routes are present. The remaining production gate is asset custody/visual approval: eight newly generated persona pairs are still referenced through the connected image-generation service rather than stored as GAL-owned durable image files, so they are not promoted as production masters.

## Automated verification

| Gate | Result | Evidence |
|---|---|---|
| Structural V3 contract | **PASS** | `PASS: dynamic visual v3 structural contract` |
| Unique Body/Swing routing | **PASS** | `PASS: 12 unique body masters + 12 unique swing plates; 4 embedded approved pairs + 8 dedicated Runway v3 pairs; local dimensions pass` |
| Gender × Age × Handedness browser matrix | **PASS** | 12 personas × 2 handedness states = **24/24** |
| Save/reload persistence | **PASS** | Male 65–74 / Left state survives document recreation |
| Swing four-stage plate renderer | **PASS** | `400% 100%` plate crop contract verified |
| Left-handed presentation | **PASS** | Photographic layer mirrors; UI/stage labels remain unmirrored |
| Page/runtime errors | **PASS** | **0 page errors** |
| Approved local image dimensions | **PASS** | Body ≥ 850×550; Swing plate ≥ 1100×300 |

## Defect caught during QA

The first Swing-frame placeholder used an opaque pixel, which obscured the plate background and produced blank-looking swing frames. Browser QA exposed the defect. The candidate now uses a truly transparent 1×1 PNG; all four crop stages render correctly in the verified local baseline pair.

## Visual evidence

- `GAL-UX10.02-STEP17.3-V3-BODY-BROWSER-VERIFICATION.png` — approved Female 55–64 Body route.
- `GAL-UX10.02-STEP17.3-V3-SWING-BROWSER-VERIFICATION.png` — approved Female 55–64 four-stage Swing plate.
- `GAL-UX10.02-STEP17.3-V3-LEFT-HANDED-VERIFICATION.png` — approved Female 65+ left-handed mirrored photography with normal labels.

These browser screenshots use the embedded approved baseline assets because the local verification environment blocks external HTTPS image loading. They prove the resolver/rendering behavior but do **not** substitute for pixel-level inspection of the eight new generated pairs.

## Persona asset state

- **4/12 pairs — approved + durable in candidate:** Female 18–34, Male 55–64, Female 55–64, Female 65+.
- **8/12 pairs — generated and uniquely routed, pending durable promotion + final pixel QA:** Junior Male, Junior Female, Male 18–34, Male 35–54, Female 35–54, Male 65+, Neutral Junior, Neutral Adult.

All eight new pairs have dedicated Body and matching Swing task/asset IDs in `GAL-DYNAMIC-VISUAL-V3-ASSET-MANIFEST.json`; no new pair is represented by a reused matrix/dashboard asset.

## Required final visual QA before production

For each of the eight new pairs, verify: correct gender/neutral presentation and age band; same-person identity between Body and all four Swing positions; two hands correctly placed on the grip; plausible wrists/elbows/shoulders/hips through address, backswing, impact and finish; continuous club shaft/clubhead; no grain/softness/malformed anatomy; coherent turf/shadow/course integration; no text/UI/logos baked into the photography; no accidental crop.

## Promotion decision

**STEP17.3 is review-ready, not production-ready.** The resolver/application work is complete and passes QA. Production promotion must remain blocked until the eight new generated pairs are copied into the GAL-owned durable asset repository and pass the final pixel-level visual review.
