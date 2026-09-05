# GAL UX10.01 — Tee Box Personalization

**Status:** USER-APPROVED / LOCKED  
**Date:** 2026-09-04  
**UX family:** `GAL-UX10`  
**UX version:** `GAL-UX10.01`  
**First implementation candidate:** `GAL-UX10.01-RC1`  
**Product surface:** Authenticated My GAL / My Bag experience

## 1. Decision

The user-approved desktop mockup generated and approved on 2026-09-04 is the governing My GAL architectural UX. It corrects a material UX5 implementation mistake: the current `reference-bag.webp` combines the scenic golf-course environment and bag imagery into one asset, even though the approved 2026-09-02 tee-box specification explicitly requires the tee-box presentation theme and bag presentation to be independent.

UX10.01 therefore uses a layered personalization model:

`Tee Box Theme + Personalized Bag Visual + Governed Equipment State + Contextual Intelligence`

The selected tee box changes only the environment. The selected/customized bag visual changes only the foreground bag presentation. Neither preference changes GAL's analytical state, equipment records, recommendations, or evidence.

## 2. Versioning governance

`GAL-UX10` is the locked UX family for this architecture.

- Initial locked version: `GAL-UX10.01`.
- Subsequent revisions within the same architecture increment sequentially: `GAL-UX10.02`, `GAL-UX10.03`, and so on.
- Review candidates append `-RC1`, `-RC2`, etc. to the locked minor version, for example `GAL-UX10.02-RC1`.
- A new whole-number UX family (for example `GAL-UX11`) requires an explicit user-approved architectural replacement decision. Implementation drift, a new release candidate, or a visual experiment cannot create a new UX family.
- A minor UX10 revision must update `GAL_UX_MANIFEST.json`, `GAL_UX_CURRENT.md`, the governing versioned specification, and the governance archive together.

## 3. Authoritative visual reference

The approved reference is the 2026-09-04 mockup showing independent tee-box and bag personalization.

- local review filename: `gal_golf_analytics_dashboard.png`
- dimensions: 1619 × 971
- SHA-256: `895f2c68b4be457356ba104b7a5d3335bc361cacfc73effe18138de5368a81c3`

The mockup is authoritative for desktop composition, hierarchy, visual tone, placement of the tee-box chooser, separation of tee-box background and bag visual, contextual Driver intelligence surface, and bottom instructional pattern.

Where the mockup contains sample facts or named equipment, it remains a presentation reference only. Governed-data rules below control production content.

## 4. Relationship to earlier approved UX

UX10.01 restores and makes explicit several requirements from the 2026-09-02 design that UX5 partially lost:

- the golf-course scene is a replaceable user preference;
- the bag is the central hero object;
- bag visual customization is distinct from equipment configuration;
- presentation preferences do not alter analytical truth;
- desktop and mobile preserve `Course -> Bag -> Status -> Opportunity -> Why -> Action -> Progress`;
- known golfer/profile/equipment information is reused across GAL rather than repeatedly requested.

UX10.01 also retains the locked mobile Driver and Golfer Profile interaction patterns: one insight at a time, progressive disclosure, clear next action, context preserved, and `Tell GAL once. Use it everywhere.`

## 5. Chosen implementation architecture

Build the My GAL scene from independent components and state:

1. `TeeBoxTheme` — scenic background choice;
2. `BagVisual` — personalized foreground bag rendering;
3. `BagStatusRail` — governed category states;
4. `BagSummary` — status/opportunity/value modules;
5. `ClubIntelligencePanel` — Driver and future club detail;
6. `UserPreferenceStore` — presentation-only preference persistence.

This architecture matches the approved UX and September 2 design, supports future course and bag assets without reworking the intelligence layer, and prevents presentation preferences from leaking into recommendation logic.

A single composited scene image is rejected. Full 3D is deferred. UX10.01 uses a performant 2D/2.5D layered composition.

## 6. Desktop information architecture

### 6.1 Global shell

- locked Option 7A Motion Arc / GAL Custom Hybrid brand identity;
- dark premium My GAL application shell;
- primary navigation remains `Today | My Bag | Insights | Guides | Progress`;
- Golfer Profile remains separate from primary navigation;
- `Tell GAL once. Use it everywhere.` appears as a restrained trust/personalization principle, not a new navigation destination.

The visual mockup shows an extra `My Game` item. This is not adopted because the current locked GAL navigation contract remains five items unless the user separately changes it.

### 6.2 Tee-box environment layer

The scenic golf-course background spans the My GAL hero area and is independent from all bag imagery.

Required behavior:

- `Choose My Tee Box` opens a compact selector/gallery;
- the current selection is visibly identified;
- selecting another theme changes only the background presentation;
- the selected theme persists as a presentation preference;
- background changes do not alter club status, insights, recommendations, fit calculations, or bag configuration;
- background loading failure falls back to a branded neutral GAL environment without breaking the bag or controls.

Initial review themes must include at least two distinct course-style environments to prove separation. Product-facing names remain conservative until image/naming rights are confirmed. Use safe labels such as `Spyglass-inspired Coastal` and `Torrey-inspired Cliffs` unless licensed/approved assets allow exact course naming.

### 6.3 Personalized bag layer

The bag is a separate foreground asset positioned over the tee-box environment.

Required behavior:

- bag presentation is independent from the selected tee-box theme;
- visual bag choice can reflect stand/cart/staff style where approved assets exist;
- bag colors/accents may reflect saved visual preferences;
- displayed club structure must not imply equipment the golfer does not actually carry;
- unknown equipment uses an honest incomplete-data state;
- changing bag appearance never changes equipment intelligence;
- `Bag Visual` / `Customize My Bag` explains that appearance and equipment configuration are separate.

For RC1, the app may use a governed set of bag render assets and choose the nearest visual match to the golfer's stored bag preference. It must not fabricate a photorealistic exact replica of a user's physical bag if GAL lacks that asset/data.

## 7. Equipment status rail

Show the primary categories:

- Driver
- Fairway / 3 Wood
- Hybrid
- Irons
- Wedges
- Putter
- Ball

States remain governed and golfer-safe. Candidate states include `Needs Attention`, `Good/Strong Fit` only with positive evidence, `Watching`, and `Not Evaluated / GAL Needs More Information`.

Absence of an active negative insight is not evidence of optimization.

## 8. Bag summary and actions

The My GAL hero/adjacent summary includes:

- Bag Status;
- Next Opportunity;
- Bag Visual / Bag Setup;
- Bag Value only when governed methodology/data exists;
- Quick Actions;
- Recent Insight;
- Ready to Improve / equivalent action only when supported by governed recommendations.

The `Bag Visual` module is first-class because it makes the bag/background separation visible to the golfer.

## 9. Contextual club intelligence

Selecting Driver or another category opens contextual intelligence without losing the My GAL scene context.

Driver detail follows the approved desktop + locked mobile model:

`Overview | Why It Matters | What To Do | Recommendations | Compare`

When governed data exists, the panel can show:

- golfer/equipment snapshot;
- measured/observed metrics with provenance;
- performance versus evidence-backed target ranges;
- concise key insights;
- contributing-factor explanation;
- recommended next steps;
- equipment recommendations;
- comparison;
- club specs;
- real-world results only when methodology and evidence support them.

## 10. Mobile behavior

### 10.1 Driver flow

`Today / My Bag -> Driver Peek -> See Why -> What To Do -> Recommendations`

Principles:

- one primary insight per screen;
- progressive disclosure;
- clear action at the end of each screen;
- user never loses context of which club/bag they are reviewing;
- bottom navigation remains `Today | My Bag | Insights | Guides | Progress`.

### 10.2 Golfer Profile flow

`Profile Home -> You / Measurements -> Your Swing -> Your Miss -> Connected Golf`

Principles:

- `Tell GAL once. Connect it once. Use it everywhere.`;
- known profile information is reused across recommendations and guides;
- connected-data provenance remains visible;
- tee-box and bag appearance preferences are stored separately from golfer measurements and performance data.

### 10.3 Mobile tee-box + bag composition

The mobile Today/My Bag screen keeps the selected course as the full scenic environment and the bag as a separate foreground layer. Course selection uses a sheet/gallery. Bag customization uses a separate sheet/page. Neither requires the other to change.

## 11. Preference/data boundary

### Presentation-only preferences

Examples:

- `tee_box_theme_id`;
- `bag_visual_id`;
- bag primary/accent color when supported;
- optional display personalization.

### Analytical/equipment data

Examples:

- equipment identity/configuration;
- measured launch/speed/spin/carry;
- golfer measurements;
- connected-golf data;
- governed insights;
- recommendations/outcomes.

No analytical scoring or recommendation function may read presentation-only preferences as decision inputs.

## 12. Asset architecture

RC1 assets are organized by type, never as a combined scene:

```text
portal/public/ux10/
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

The current combined `portal/public/ux5/reference-bag.webp` must not remain active UX10 scene authority.

## 13. Accessibility and performance

- minimum practical 44×44 px interactive targets;
- readable contrast over all supported course themes;
- decorative background images use appropriate semantics and do not create redundant screen-reader noise;
- reduced-motion preference is honored;
- background and bag assets use responsive sizing/compression;
- bag foreground remains legible if the background is delayed or unavailable;
- course selector is keyboard accessible;
- no critical interaction depends on hover.

## 14. Truthfulness and rights

The approved mockup contains illustrative metrics, optimized counts, valuations, named products, projected gains, and course names. Those are examples, not approved production facts.

Production/RC behavior:

- no fabricated golfer metrics;
- no unsupported `Optimized` states;
- no unsupported yardage gains;
- no bag valuations until methodology/source data are governed;
- no named product recommendation unless the recommendation pipeline supports it;
- no `real-world results` claims without approved methodology/evidence;
- do not imply official affiliation, licensing, or exact reproduction of Spyglass Hill, Torrey Pines, Pebble Beach, or another course unless rights are confirmed.

## 15. Code boundaries

UX10.01 replaces the current combined-scene implementation rather than layering another patch onto it.

Expected boundaries:

- replace/refactor `portal/src/ux5/bagEnvironment.ts` into UX10 scene components;
- introduce tee-box theme configuration/model;
- introduce bag visual configuration/model;
- update Today/My Bag renderers to consume independent theme + bag inputs;
- use an explicit UX10 visual layer;
- keep governed insight, profile, equipment, recommendation, Supabase/RLS, and security contracts intact;
- update registered-user and subscriber/customer portal surfaces together when shared components are affected.

## 16. Testing strategy

Implementation is test-first.

Required regression gates:

1. tee-box background and bag asset are separate DOM elements and source paths;
2. switching tee-box theme does not change bag visual ID or equipment/category data;
3. switching bag visual does not change tee-box theme or equipment/category data;
4. no active UX10 source references combined UX5 `reference-bag.webp`;
5. primary navigation remains the locked five-item set;
6. Driver detail includes `Overview`, `Why It Matters`, `What To Do`, `Recommendations`, `Compare`;
7. mobile bottom navigation remains viewport-anchored;
8. sample facts from mockups are rejected from rendered bundles;
9. service-role material is rejected from browser output;
10. governed tee-box/bag assets reconstruct/checksum correctly in CI;
11. desktop/mobile screenshots are manually reviewed against the approved reference before candidate release.

## 17. UX10.01 RC1 acceptance criteria

`GAL-UX10.01-RC1` is ready for review when:

1. a user can visibly switch between at least two independent tee-box themes;
2. the bag remains unchanged when the tee box changes;
3. the bag visual is independently selectable/customizable from a governed asset set;
4. the tee-box background remains unchanged when the bag visual changes;
5. desktop My GAL matches the approved UX10 hierarchy;
6. Driver contextual panel follows the five-tab model including `What To Do`;
7. mobile follows approved Driver/Profile principles and bottom navigation;
8. golfer-facing data is governed or shown as honest incomplete/learning state;
9. all tests/build/security/anti-fabrication/asset checks pass;
10. production remains untouched until explicit user approval.

## 18. Authority

`GAL-UX10.01` is the current locked architectural UX after the governance files are updated atomically with this specification.

Authority precedence:

1. later explicit user-approved UX lock;
2. `GAL_UX_MANIFEST.json`;
3. `GAL_UX_CURRENT.md`;
4. this UX10.01 specification;
5. earlier approved specifications;
6. implementation/code.

Code does not silently supersede the approved UX.