# CURRENT GAL UX — READ BEFORE ANY GAL UX WORK

**Status:** LOCKED  
**Locked:** 2026-09-04  
**Current UX family:** **GAL UX10 — Tee Box Personalization**  
**Current version:** `GAL-UX10.01`  
**Next review candidate:** `GAL-UX10.01-RC1`

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

## Authoritative visual reference

- File: `gal_golf_analytics_dashboard.png`
- Dimensions: 1619 × 971
- SHA-256: `895f2c68b4be457356ba104b7a5d3335bc361cacfc73effe18138de5368a81c3`
- Full specification: `docs/superpowers/specs/2026-09-04-gal-ux10-01-tee-box-personalization-design.md`
- Machine-readable authority: `GAL_UX_MANIFEST.json`

## Locked UX10.01 architecture

- premium dark/navy My GAL shell using the locked Option 7A Motion Arc identity;
- primary navigation remains Today | My Bag | Insights | Guides | Progress;
- **tee-box environment and bag visual are separate independent layers**;
- the tee-box is a user-selectable presentation preference and may change independently (for example, a coastal Spyglass-inspired scene versus a Torrey-inspired cliffs scene);
- the bag is a separate foreground visual driven by the golfer's saved bag/presentation preference and actual equipment structure where data exists;
- changing the tee box must never change the bag, equipment configuration, club status, insights, recommendations, or analytics;
- changing bag appearance must never change the tee box or analytical state;
- a single composited course+bag image is forbidden as the active UX10 scene architecture;
- the bag remains the hero object with Driver, Fairway/3 Wood, Hybrid, Irons, Wedges, Putter, and Ball status exploration;
- Bag Status, Next Opportunity, Bag Visual/Bag Setup, Bag Value when governed, Quick Actions, Recent Insight, and Progress remain part of the My GAL experience;
- club detail uses Overview | Why It Matters | What To Do | Recommendations | Compare;
- mobile preserves the locked Driver/Profile progressive-disclosure model and viewport-anchored five-part bottom navigation;
- `Tell GAL once. Connect it once. Use it everywhere.` remains a personalization/data-reuse principle.

## Truthfulness rule

The visual mockup controls presentation, not analytical truth. Example golfer metrics, optimized states, yardage gains, values, product recommendations, and real-world-result claims require governed GAL data or must be withheld/labeled as review data.

## UX10 version-control rule

`GAL-UX10` is the current architectural family.

- The first locked version is `GAL-UX10.01`.
- Revisions within this architecture increment `.02`, `.03`, `.04`, and so on.
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

UX10.01 supersedes UX5 as the current visual/interaction authority while intentionally restoring the independent tee-box and independent bag-personalization requirements documented on 2026-09-02. Earlier implementation candidates remain history, not authority.
