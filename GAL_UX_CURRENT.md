# CURRENT GAL UX — READ BEFORE ANY GAL UX WORK

**Status:** LOCKED  
**Locked:** 2026-09-04  
**Amended:** 2026-09-05 — universal UX10 shared header rule  
**Current UX family:** **GAL UX10**  
**Current version:** `GAL-UX10.02`  
**Current focus:** **Golfer Profile Experience**  
**Next review candidate:** `GAL-UX10.02-RC1`

This file is the human-readable current-UX pointer. Do not infer the approved UX from whichever portal implementation or release candidate happens to be newest. Implementation may lag the approved UX.

## Mandatory preflight

Before any GAL UX, design, code, database, guide, branding, or portal work that can affect this experience:

1. Read `GAL_UX_MANIFEST.json`.
2. Read this file.
3. Read the governing versioned specification referenced by the manifest.
4. Retrieve/verify the locked visual reference when visual work is involved.
5. Compare the requested work with the current lock before editing code.
6. If there is a conflict, surface it before implementation.

If the governing material cannot be retrieved, implementation does not proceed.

## Locked UX10 brand authority

- **Authoritative brand system:** **Stylized Option B: Motion Arc — built on Option 7A GAL Custom Hybrid**.
- This is the only active brand system for UX10 unless the user explicitly replaces it later.
- Active website dark lockup: `/portal/gal-motion-arc-dark-lockup.webp`.
- Locked dark-lockup SHA-256: `8cd2030c7b3f4e75a9474dbd3e9f27e6697ce89ea756f22a5c4749192c117636`.
- `/portal/gal-option7a-motion.jpg` and other older/approximate GAL marks are retired from active UX10 use.
- Mockups, previews and website builds must verify the locked brand before presentation.

## Universal UX10 shared header

- Every UX10 screen and focused workspace uses one governed shared header implementation.
- This applies to Today, My Bag, Insights, Guides, Progress, Golfer Profile, Profile sub-workspaces, fitting/intelligence views, and future UX10 screens.
- Individual screens may not create alternate or page-specific GAL header/logo treatments.
- The shared header always uses the locked Stylized Option B Motion Arc dark lockup above.
- Primary navigation remains `Today | My Bag | Insights | Guides | Progress`.
- `Golfer Profile` remains separate from primary navigation.
- Responsive/mobile layouts may compress or rearrange the header, but they must preserve the same logo, product identity, navigation model, and shared implementation source.
- Future header refinements are made once in the shared header and propagate everywhere.

## Authoritative Golfer Profile visual reference

- File: `Profile Mobile Screen(1).png`
- Dimensions: 1606 × 979
- SHA-256: `36e3e9d606534cc7af4dd35f1aae81fe7f86fdc4515b90d741c8da2b909c24e8`
- Full specification: `docs/superpowers/specs/2026-09-04-gal-ux10-02-golfer-profile-experience-design.md`
- Governance archive: `GAL UX10.02 — Golfer Profile Experience — LOCKED`
- Machine-readable authority: `GAL_UX_MANIFEST.json`

## Locked UX10.02 Golfer Profile architecture

- governing principle: **Tell GAL Once. Connect It Once. Use It Everywhere.**;
- Golfer Profile remains separate from the five primary navigation items;
- primary navigation remains Today | My Bag | Insights | Guides | Progress;
- Profile Home contains six areas: You, Your Game, Your Swing, Your Miss, Where You Play, Connected Golf;
- mobile progression is Profile Home → You / Measurements → Your Swing → Your Miss → Connected Golf;
- Where You Play and Your Game remain first-class Profile Home areas without becoming extra mandatory mobile progression screens;
- mobile Profile uses focused workspaces, not one long page;
- You / Measurements includes governed body/fitting measurements, source, date, freshness and update guidance;
- Your Swing begins with Driver | 7-Iron and displays only governed metrics;
- Your Miss separates finish direction, shot shape and strike location;
- locked shot-shape options are Hook | Pull | Straight | Push | Slice;
- Connected Golf uses truthful source-status cards and never claims Connected without a valid connection;
- last-sync/freshness appears where known;
- What GAL Learned appears only for actual governed derived/update activity;
- visible data-quality language distinguishes Measured, Observed, Self-Reported and Inferred / Estimated;
- desktop uses the same Profile Home + focused-area model with more room rather than a different information architecture;
- five-part mobile bottom navigation remains viewport anchored;
- missing or unsupported data uses honest incomplete states.

## UX10.01 architecture inherited unchanged

UX10.02 does **not** replace the My GAL tee-box/bag architecture locked in UX10.01:

- tee-box environment and bag visual remain separate independent layers;
- tee-box and bag preferences remain presentation-only;
- presentation preferences never change equipment analytics;
- a combined course+bag scene remains forbidden;
- the bag remains the My GAL hero object;
- club intelligence remains governed and truthful.

The inherited UX10.01 desktop reference remains `gal_golf_analytics_dashboard.png`, 1619 × 971, SHA-256 `895f2c68b4be457356ba104b7a5d3335bc361cacfc73effe18138de5368a81c3`.

## Truthfulness rule

Visual references control presentation, not analytical truth. Example golfer metrics, profile percentages, connection states, optimized states, product recommendations and derived facts require governed GAL data or must remain unavailable/incomplete.

## UX10 version-control rule

`GAL-UX10` is the current architectural family.

- Current locked revision is `GAL-UX10.02`.
- Revisions within this architecture increment `.03`, `.04`, `.05`, and so on.
- Review candidates append `-RC1`, `-RC2`, etc., e.g. `GAL-UX10.02-RC1`.
- A new whole-number family such as UX11 requires an explicit user-approved architectural replacement decision.
- A new implementation, mockup, RC, or code change cannot silently create a new UX version.
- Every locked revision must update this file, `GAL_UX_MANIFEST.json`, its governing versioned specification, and the governance archive together.

## Authority rule

When sources conflict, use this order:

1. a later explicit user-approved UX lock;
2. `GAL_UX_MANIFEST.json`;
3. this file;
4. the authoritative versioned UX specification;
5. older approved UX specifications;
6. current implementation/code.

**Code never silently supersedes a locked UX.**

## Historical continuity

UX10.02 supersedes UX10.01 as the current version pointer because Golfer Profile is the newly approved revision. UX10.01 remains inherited authority for the independent tee-box and bag architecture. Earlier implementation candidates remain history, not authority.
