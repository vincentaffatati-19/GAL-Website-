# GAL UX11 — Profile Visual Lineage & Routing Lock

**Status:** LOCKED SOURCE DEPENDENCY  
**Date:** 2026-09-09  
**Applies to:** `GAL-UX11.0-RC1` and all descendants until explicitly superseded by reviewed GAL governance.

## Purpose

Preserve the last approved/refined UX10.02 Golfer Profile visual-routing work as an explicit dependency of UX11. The UX11 rebuild may change surrounding presentation, but it must not silently replace, simplify, regenerate, or remap the governed Body/Swing persona system.

The last profile-visual progress was a sequence of corrections and closeout steps, not a single image board. Runtime authority is determined by approved lineage + QA, not by filename recency.

## Authoritative lineage

1. **STEP17.2 RC2 / RC3** — corrected senior Male/Female Body mappings. During live integration, the complete 12-persona `GOLFER_VISUAL_MANIFEST` was restored after a regression test caught its accidental omission. RC3 preserved the corrected senior mappings.
2. **STEP17.3 Dynamic Visual V3** — established 12 unique Body routes and 12 matching Swing routes spanning gender visual family, age visual band, and handedness presentation.
3. **STEP17.3.2** — fixed the wrong-gender unknown-age defect. Explicit Male/Female gender remains authoritative when age is `Not provided` or `Prefer not to say`; same-gender durable aliases are used instead of neutral adult imagery.
4. **STEP17.3.3** — preserved the persona routing while fixing Swing Breakdown distortion by rendering source plate quarters at native aspect ratio; all six long profile sections use governed `+ / −` disclosure behavior.
5. **FINAL PROFILE RC — 2026-09-08** — preserved the approved STEP17.3.3 UX/behavior and closed asset custody: all 12 persona pairs are durable/governed; the eight newer pairs use GAL-owned Supabase Storage and the four previously approved masters remain embedded.
6. **STEP18 Integrated Staging** — verified the complete gender/age/handedness routing matrix together with controlled profile fields, longitudinal facts, location/environment logic, and downstream same-revision snapshots.

## Final authoritative source stack

Use these together. Do not reconstruct final behavior from intermediate review boards or filenames alone.

- `GAL-UX10.02-FINAL-PROFILE-RC.html` — authoritative final runtime resolver and profile UX.
- `GAL-UX10.02-FINAL-PROFILE-ASSET-MANIFEST.json` — governed Body/Swing asset custody, paths, dimensions and hashes.
- `GAL-UX10.02-FINAL-PROFILE-STATIC-VERIFICATION.json` — 47/47 final profile contract checks and 50/50 Gender × Age resolver matrix.
- `GAL-UX10.02-FINAL-PROFILE-QA.md` — final closeout/equivalence proof and release posture.
- `GAL-UX10.02-STEP17.3.3-SWING-COLLAPSE-QA.md` — native-aspect Swing rendering and disclosure behavior.
- `GAL-UX10.02-STEP17-LIVE-INTEGRATION-QA.md` — corrected senior mappings and 12-persona manifest restoration.
- `GAL-UX10.02-STEP18-INTEGRATED-STAGING-QA.md` — last integrated staging proof.

### Identity hashes

- Final Profile RC SHA-256: `c2dd228f782fd357949c472a07d6a2cb68be6308ea60d749dfac8fe0bdc5c084`
- Approved STEP17.3.3 / normalized-final SHA-256: `aa9908bea071318e45ee3b1af0a0c41f12fa46acb2c1f88111cb6c4fdd7539f7`

## Locked Gender × Age routing

The user-facing age inputs are more granular than the visual families. The aggregation below is intentional and verified.

| Gender state | Age input | Required route |
|---|---|---|
| Male | Under 18 | `junior_male` |
| Female | Under 18 | `junior_female` |
| Male | 18–24 or 25–34 | `male_young` |
| Female | 18–24 or 25–34 | `female_young` |
| Male | 35–44 or 45–54 | `male_middle` |
| Female | 35–44 or 45–54 | `female_middle` |
| Male | 55–64 | `male_mature` |
| Female | 55–64 | `female_mature` |
| Male | 65–74 or 75+ | `male_senior` |
| Female | 65–74 or 75+ | `female_senior` |
| Male | Not provided / Prefer not to say | `male_age_unspecified` |
| Female | Not provided / Prefer not to say | `female_age_unspecified` |
| Missing / Neutral / Non-binary / Prefer-not gender | Under 18 | `neutral_junior` |
| Missing / Neutral / Non-binary / Prefer-not gender | Adult age, unknown age, or undisclosed age | `neutral_adult` |

### Unknown-age gender-authority rule

This rule is a regression lock, not a presentation preference:

- `male_age_unspecified` reuses the approved durable `male_mature` Body and Swing masters while UI metadata removes the age claim.
- `female_age_unspecified` reuses the approved durable `female_mature` Body and Swing masters while UI metadata removes the age claim.
- Explicit Male/Female gender must **never** fall through to `neutral_adult` solely because age is unknown or undisclosed.
- Neutral routing remains correct only when gender itself is missing, neutral, non-binary/another identity, or withheld.

## Locked persona families and asset roles

There are **12 base persona pairs**, each with a Body master and matching Swing master/plate:

| Persona key | Visual family | Visual age band | Final asset role |
|---|---|---|---|
| `junior_male` | Male | Junior | GAL-owned durable Body + Swing |
| `junior_female` | Female | Junior | GAL-owned durable Body + Swing |
| `male_young` | Male | 18–34 | GAL-owned durable Body + Swing |
| `female_young` | Female | 18–34 | approved embedded Body + Swing |
| `male_middle` | Male | 35–54 | GAL-owned durable Body + Swing in final runtime |
| `female_middle` | Female | 35–54 | GAL-owned durable Body + Swing in final runtime |
| `male_mature` | Male | 55–64 | approved embedded Body + Swing |
| `female_mature` | Female | 55–64 | approved embedded Body + Swing |
| `male_senior` | Male | 65+ | GAL-owned durable Body + Swing |
| `female_senior` | Female | 65+ | approved embedded Body + Swing |
| `neutral_junior` | Neutral | Junior | GAL-owned durable Body + Swing |
| `neutral_adult` | Neutral | Adult fallback | GAL-owned durable Body + Swing |

The exact file/object paths, hashes, dimensions and byte sizes remain governed by `GAL-UX10.02-FINAL-PROFILE-ASSET-MANIFEST.json`; UX11 must consume that authority rather than duplicating or guessing asset identity from filenames.

## Handedness lock

- Right-handed photography is the base master.
- Left-handed presentation mirrors the **photographic layer only**.
- HTML labels, text, stage labels and other interface content remain unmirrored.
- The same resolved persona family must be used for Body and all four Swing stages.

## Swing fidelity lock

The four stages remain:

1. Address
2. Backswing
3. Impact
4. Finish

STEP17.3.3 eliminated fixed-height distortion. UX11 must render each source-plate quarter at its native aspect ratio and scale responsively with proportional height. No fixed-height crop/stretch may be reintroduced. Mobile may use the verified 2×2 stage grid.

## Profile disclosure behavior preserved

The following sections start collapsed and use accessible `+ / −` controls with synchronized `aria-expanded`, `aria-controls`, and visibility state:

- Your Swing
- Your Miss
- Where You Play
- Connected Golf
- Review Your Golfer Profile
- Longitudinal / Audit Trail

## Final closeout state that UX11 must inherit

- Persona families: **12 / 12**
- Body masters: **12 / 12**
- Swing plates: **12 / 12**
- Durable/governed persona pairs: **12 / 12**
- Pending durable promotion: **0**
- Final static/profile contract: **47 / 47 PASS**
- Gender × Age resolver matrix: **50 / 50 PASS**
- Runway CDN URLs in final RC: **0**
- Final profile behavior is normalized byte-equivalent to approved STEP17.3.3 after custody/source substitution only.

## UX11 non-regression rules

UX11 RC assembly MUST fail review if any of these occur:

1. A Male or Female profile renders the opposite-gender or neutral Body/Swing family for a verified age route.
2. Explicit Male/Female + unknown/undisclosed age falls through to neutral imagery.
3. Senior Male/Female mappings regress or are reconstructed from an older visual board.
4. 65–74 or 75+ routes to a non-senior visual family.
5. Body and Swing resolve to different persona families.
6. A governed final persona master is replaced by regenerated, guessed, newer-by-filename, or visually similar media without an explicit reviewed supersession record.
7. Left-handed mode mirrors labels/UI instead of only the photographic layer.
8. Swing stages are stretched, cropped, reordered, or rendered with non-native aspect ratio.
9. The 12-base-route / 50-case resolver contract is reduced without explicit governance approval.
10. UX11 treats a presentation-board image as the runtime asset authority instead of the Final Profile runtime + asset manifest.

## Required UX11 verification

Before RC1 can be called review-ready, execute fresh checks for:

- all 12 Body routes present;
- all 12 Swing routes present;
- all 50 Gender × Age combinations;
- explicit Male/Female unknown-age cases;
- Male/Female senior cases for both 65–74 and 75+;
- Body/Swing persona-key parity;
- right/left handed visual behavior;
- native Swing aspect ratio at desktop and mobile widths;
- six disclosure controls;
- final asset-source authority (4 approved embedded + 8 GAL-owned Supabase runtime routes; no review-hosted generation URLs);
- STEP18 downstream profile-revision consistency after integration.

## Production boundary

This lock preserves approved/reviewed profile behavior; it does not itself authorize production promotion. Existing release gates remain in force, including the unrelated Supabase Auth leaked-password protection blocker and outstanding external-platform integrations.
