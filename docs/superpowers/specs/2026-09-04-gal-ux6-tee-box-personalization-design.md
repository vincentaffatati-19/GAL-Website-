# GAL UX6 — Tee Box Personalization

**Status:** USER-APPROVED VISUAL DIRECTION / WRITTEN SPEC FOR REVIEW  
**Date:** 2026-09-04  
**UX identifier:** `GAL-UX6-TBP`  
**First implementation candidate:** `GAL-UX6-TBP-RC1`  
**Product surface:** Authenticated My GAL / My Bag experience

## 1. Decision

The user-approved desktop mockup generated and approved on 2026-09-04 becomes the next My GAL UX direction. It corrects a material UX5 implementation mistake: the current `reference-bag.webp` combines the scenic golf-course environment and bag imagery into one asset, even though the approved 2026-09-02 tee-box specification explicitly requires the tee-box presentation theme and bag presentation to be independent.

UX6 therefore uses a layered personalization model:

`Tee Box Theme + Personalized Bag Visual + Governed Equipment State + Contextual Intelligence`

The selected tee box changes only the environment. The selected/customized bag visual changes only the foreground bag presentation. Neither preference changes GAL's analytical state, equipment records, recommendations, or evidence.

## 2. Authoritative visual reference

The approved reference is the 2026-09-04 mockup titled in the footer as **GAL-UX6 Tee Box Personalization**.

- local review filename: `gal_golf_analytics_dashboard.png`
- dimensions: 1619 × 971
- SHA-256: `895f2c68b4be457356ba104b7a5d3335bc361cacfc73effe18138de5368a81c3`

The mockup is authoritative for the desktop composition, hierarchy, visual tone, placement of the tee-box chooser, separation of tee-box background and bag visual, contextual Driver intelligence surface, and bottom instructional pattern.

Where the mockup contains sample facts or named equipment, it remains a presentation reference only. Governed-data rules below control production content.

## 3. Relationship to earlier approved UX

UX6 does not discard the 2026-09-02 design. It restores and makes explicit several requirements that UX5 partially lost:

- the golf-course scene is a replaceable user preference;
- the bag is the central hero object;
- bag visual customization is distinct from equipment configuration;
- presentation preferences do not alter analytical truth;
- desktop and mobile preserve `Course -> Bag -> Status -> Opportunity -> Why -> Action -> Progress`;
- known golfer/profile/equipment information should be reused across GAL rather than repeatedly requested.

UX6 also retains the locked mobile Driver and Golfer Profile interaction patterns: one insight at a time, progressive disclosure, clear next action, context preserved, and `Tell GAL once. Use it everywhere.`

## 4. Chosen implementation approach

### Approach A — Layered personalization components — CHOSEN

Build the My GAL scene from independent components and state:

1. `TeeBoxTheme` — scenic background choice;
2. `BagVisual` — personalized foreground bag rendering;
3. `BagStatusRail` — governed category states;
4. `BagSummary` — status/opportunity/value modules;
5. `ClubIntelligencePanel` — Driver and future club detail;
6. `UserPreferenceStore` — presentation-only preference persistence.

This approach matches the approved UX and September 2 architecture, supports future course and bag assets without reworking the intelligence layer, and prevents presentation preferences from leaking into recommendation logic.

### Approach B — Keep one composited scene image — REJECTED

This is what UX5 effectively did. It is visually simple but makes the course and bag inseparable, prevents independent personalization, and directly conflicts with the approved September 2 requirements.

### Approach C — Full 3D scene and bag engine — DEFERRED

It could support richer personalization but adds unnecessary complexity, performance cost, asset-production burden, and accessibility risk. UX6 launches as a performant 2D/2.5D layered composition.

## 5. Desktop information architecture

The desktop experience follows the approved UX6 mockup.

### 5.1 Global shell

- locked Option 7A Motion Arc / GAL Custom Hybrid brand identity;
- dark premium My GAL application shell;
- primary navigation remains `Today | My Bag | Insights | Guides | Progress`;
- Golfer Profile remains separate from primary navigation;
- `Tell GAL once. Use it everywhere.` appears as a restrained trust/personalization principle, not a new navigation destination.

The visual mockup shows an extra `My Game` item. This is **not** adopted because the current locked GAL navigation contract remains five items unless the user separately changes it.

### 5.2 Tee-box environment layer

The scenic golf-course background spans the My GAL hero area and is independent from all bag imagery.

Required behavior:

- `Choose My Tee Box` control opens a compact selector/gallery;
- the current selection is visibly identified;
- selecting another theme changes only the background presentation;
- the user's selected theme persists as a presentation preference;
- background changes do not alter club status, insights, recommendations, fit calculations, or bag configuration;
- background loading failure falls back to a branded neutral GAL course environment without breaking the bag or controls.

Initial review themes should include two distinct course-style environments to prove the separation, with product-facing naming handled conservatively until image/naming rights are confirmed. For implementation and testing, use labels such as `Spyglass-inspired Coastal` and `Torrey-inspired Cliffs` unless a licensed/approved asset allows exact course naming.

### 5.3 Personalized bag layer

The bag is a separate foreground asset positioned over the tee-box environment.

Required behavior:

- bag presentation is independent from the selected tee-box theme;
- visual bag choice can reflect stand/cart/staff style where approved assets exist;
- bag colors/accents may reflect saved visual preferences;
- the displayed club structure must not imply equipment the golfer does not actually carry;
- unknown equipment uses an honest incomplete-data state;
- changing bag appearance must never change equipment intelligence;
- `Bag Visual` / `Customize My Bag` entry point explains that appearance and equipment configuration are separate.

For RC1, the app may use a governed set of bag render assets and choose the nearest visual match to the golfer's stored bag preference. It must not fabricate a photorealistic exact replica of a user's physical bag if GAL lacks that asset/data.

## 6. Left equipment-status rail

Show the primary categories:

- Driver
- Fairway / 3 Wood
- Hybrid
- Irons
- Wedges
- Putter
- Ball

States remain governed and golfer-safe. Candidate display states include `Needs Attention`, `Good/Strong Fit` only with positive evidence, `Watching`, and `Not Evaluated / GAL Needs More Information`.

Absence of an active negative insight is not evidence of optimization.

## 7. Bag summary and actions

The My GAL hero/adjacent summary includes:

- Bag Status;
- Next Opportunity;
- Bag Visual / Bag Setup;
- Bag Value when governed methodology/data exists;
- Quick Actions;
- Recent Insight;
- Ready to Improve / equivalent action when supported by governed recommendations.

The `Bag Visual` module is a first-class UX6 addition because it makes the bag/background separation visible to the golfer.

## 8. Contextual club intelligence

Selecting Driver or another category opens contextual intelligence without losing the My GAL scene context.

Driver detail follows the approved desktop + locked mobile model:

`Overview | Why It Matters | What To Do | Recommendations | Compare`

The earlier UX5 four-tab model is expanded to include `What To Do`, matching the locked mobile Driver experience.

When governed data exists, the panel can show:

- golfer/equipment snapshot;
- measured/observed metrics with provenance;
- performance versus evidence-backed target ranges;
- concise key insights;
- `What may be contributing` / root-factor explanation;
- recommended next steps;
- equipment recommendations;
- comparison;
- club specs;
- real-world results only when methodology and evidence support them.

## 9. Mobile behavior

UX6 must preserve the two locked mobile reference systems.

### 9.1 Driver mobile flow

`Today / My Bag -> Driver Peek -> See Why -> What To Do -> Recommendations`

Principles:

- one primary insight per screen;
- progressive disclosure;
- clear action at the end of each screen;
- user never loses context of which club/bag they are reviewing;
- bottom navigation remains `Today | My Bag | Insights | Guides | Progress`.

### 9.2 Golfer Profile mobile flow

`Profile Home -> You / Measurements -> Your Swing -> Your Miss -> Connected Golf`

Principles:

- `Tell GAL once. Connect it once. Use it everywhere.`;
- known profile information is reused across recommendations and guides;
- connected-data provenance remains visible;
- presentation preferences such as tee box and bag appearance are stored separately from golfer measurements and performance data.

### 9.3 Mobile tee-box + bag composition

The mobile Today/My Bag screen keeps the selected course as the full scenic environment and the bag as a separate foreground layer. Course selection can use a sheet/gallery. Bag customization can use a separate sheet/page. Neither requires the other to change.

## 10. Preference/data boundaries

Introduce a clear conceptual boundary between presentation preferences and analytical data.

### Presentation-only preferences

Examples:

- `tee_box_theme_id`;
- `bag_visual_id`;
- bag primary/accent color when supported;
- optional display personalization.

These values may be stored in a golfer preference record or equivalent safe user-facing configuration store.

### Analytical/equipment data

Examples:

- equipment identity and configuration;
- measured launch/speed/spin/carry;
- golfer measurements;
- connected-golf data;
- governed insights;
- recommendations and outcomes.

No analytical scoring or recommendation function may read presentation-only preferences as decision inputs.

## 11. Asset architecture

RC1 assets are organized by type rather than as a single composited scene.

Suggested structure:

```text
portal/public/ux6/
  tee-boxes/
    coastal-01.webp
    cliffs-01.webp
  bags/
    gal-tour-bag.webp
    gal-stand-bag.webp
  thumbnails/
    ...
```

Each asset family receives provenance documentation and checksum verification in CI, following the existing locked-logo / governed-asset practice.

The current combined `portal/public/ux5/reference-bag.webp` must not remain the active UX6 scene authority.

## 12. Accessibility and performance

- minimum practical 44×44 px interactive targets;
- readable contrast over all supported course themes;
- decorative background images use appropriate semantics and do not create redundant screen-reader noise;
- reduced-motion preference is honored;
- background and bag assets use responsive sizing/compression;
- bag foreground remains legible if the background image is delayed or unavailable;
- course selector is fully keyboard accessible;
- no critical interaction depends on hover.

## 13. Truthfulness and rights

The approved mockup includes illustrative golfer metrics, optimized counts, valuations, named products, projected gains, and course names. Those are examples, not approved production facts.

Production/RC behavior:

- no fabricated golfer metrics;
- no unsupported `Optimized` states;
- no unsupported yardage gains;
- no bag valuations until methodology and source data are governed;
- no named product recommendation unless the recommendation pipeline supports it;
- no claimed `real-world results` without approved methodology and evidence;
- do not imply official affiliation, licensing, or exact reproduction of Spyglass Hill, Torrey Pines, Pebble Beach, or other courses unless rights are confirmed.

For review, course-inspired themes may use safe descriptive labels while preserving the UX concept.

## 14. Code boundaries

UX6 should replace the current combined-scene implementation rather than layering another patch onto it.

Expected source boundaries:

- replace/refactor `portal/src/ux5/bagEnvironment.ts` into UX6 scene components;
- introduce tee-box theme configuration/model;
- introduce bag visual configuration/model;
- update Today/My Bag renderers to consume independent theme + bag visual inputs;
- update UX styling into an explicit UX6 visual layer;
- keep existing governed insight, profile, equipment, recommendation, Supabase/RLS, and security contracts intact;
- update both registered-user and subscriber/customer portal surfaces when shared components are affected.

## 15. Testing strategy

Implementation is test-first.

Required regression gates include:

1. tee-box background asset and bag asset are separate DOM elements and separate source paths;
2. switching tee-box theme does not change bag visual ID or equipment/category data;
3. switching bag visual does not change tee-box theme or equipment/category data;
4. no active UX6 source references the combined UX5 `reference-bag.webp` scene;
5. primary navigation remains the locked five-item set;
6. Driver detail includes `Overview`, `Why It Matters`, `What To Do`, `Recommendations`, `Compare`;
7. mobile bottom navigation stays viewport-anchored;
8. sample facts from mockups are rejected from rendered application bundles;
9. service-role material is rejected from browser output;
10. governed course/bag assets reconstruct/checksum correctly in CI;
11. desktop and mobile screenshots are manually reviewed against the approved UX6 reference before candidate release.

## 16. RC1 acceptance criteria

`GAL-UX6-TBP-RC1` is ready for user review when:

1. a user can visibly switch between at least two independent tee-box themes;
2. the bag remains unchanged when the tee box changes;
3. the bag visual is independently selectable/customizable from a governed asset set;
4. the tee-box background remains unchanged when the bag visual changes;
5. the desktop My GAL composition matches the approved UX6 hierarchy;
6. the Driver contextual panel follows the five-step/tab model including `What To Do`;
7. mobile follows the approved Driver/Profile principles and bottom navigation contract;
8. all golfer-facing data is governed or shown as an honest incomplete/learning state;
9. all tests/build/security/anti-fabrication/asset checks pass;
10. production remains untouched until explicit user approval.

## 17. Version authority

After written-spec approval, `GAL_UX_MANIFEST.json` and `GAL_UX_CURRENT.md` will be updated atomically to identify `GAL-UX6-TBP` as the current locked UX. The UX5 manifest remains authoritative until this written spec is approved.

Once locked, authority precedence remains:

1. later explicit user-approved UX lock;
2. `GAL_UX_MANIFEST.json`;
3. `GAL_UX_CURRENT.md`;
4. this UX6 specification;
5. earlier approved specifications;
6. implementation/code.

Code does not silently supersede the approved UX.
