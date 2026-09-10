# GAL Artifact Provenance & RC Assembly Rule

**Status:** LOCKED GOVERNING RULE  
**Effective:** 2026-09-09  
**Applies to:** Every Golf Analytics Lab release candidate, reconstruction, visual refresh, profile build, Buyers Guide integration, and production promotion.

## Locked rule

> **No GAL release candidate may be reconstructed, promoted, or described as current until its architecture source, visual source, implementation source, asset manifest, supersession lineage, and QA evidence have been identified and cross-checked. Existing approved assets must be recovered and reused rather than recreated. Any regenerated or materially altered visual is a new candidate requiring review.**

## Required provenance classes

Every RC must identify these independently. One artifact may satisfy more than one class only when evidence proves that it does.

1. **Architecture source** — approved information architecture, navigation, interaction hierarchy, and product-flow intent.
2. **Visual source** — approved appearance/reference imagery. A concept board is never automatically an implementation source.
3. **Implementation source** — exact Git branch/commit and code files used as the engineering baseline.
4. **Asset manifest** — exact governed visual/data assets, including version, custody, hashes or durable paths when available.
5. **Supersession lineage** — chronological chain showing what replaced what and why.
6. **QA evidence** — tests, visual regression evidence, static verification, browser verification, and any known blockers.

## Mandatory RC assembly gate

Before implementation begins, create an RC Assembly Manifest containing:

- RC name and version.
- source artifact names and roles;
- Git branch and commit SHA;
- asset hashes/durable locations where available;
- explicit `INCLUDE`, `REFERENCE_ONLY`, `SUPERSEDED`, and `EXCLUDE` classifications;
- visual-regression reference(s);
- open blockers and non-goals;
- statement that no source was selected by filename recency alone.

An RC fails this gate if any required provenance class is unknown or contradictory.

## Chronology rule

“Latest,” “final,” “complete,” numeric suffixes, and timestamps are not sufficient evidence of authority. Determine authority by chronological lineage plus explicit approval/QA status.

When reconstructing a workstream, record the lineage in order and state what changed at each transition. If the lineage cannot be proven, do not infer it from visual similarity or filenames.

## Recover, do not recreate

If an approved asset exists, recover and reuse the exact approved asset whenever technically possible.

Do not substitute:

- CSS-drawn approximations for approved photographic scenes;
- regenerated golfer/persona imagery for approved masters;
- generic equipment imagery for governed product imagery;
- a presentation board for its underlying implementation assets;
- a newer-looking artifact for a proven approved artifact.

A regenerated, redrawn, materially cropped, recolored, or structurally altered visual is a **new candidate** and must not inherit prior approval.

## Visual regression gate

Graphics-heavy GAL surfaces require visual verification in addition to code/contract tests. At minimum compare against the approved visual reference for:

- photographic versus synthetic/CSS scenery;
- official Option 7A Motion Arch branding;
- approved GAL bag treatment;
- golfer/persona family and age/gender routing;
- real governed equipment images;
- information hierarchy and panel placement;
- responsive/mobile treatment;
- absence of promotional badges, retailer watermarks, award graphics, generic fallbacks, and unintended backgrounds.

A technically functional page that materially regresses from the approved visual reference is **FAIL**.

## Versioning rule

- Major product/experience reset: `UX11.0`, `UX12.0`, etc.
- Minor approved functional evolution: `UX11.1`, `UX11.2`, etc.
- Review candidates: `GAL-UX11.0-RC1`, `RC2`, `RC3`, etc.
- Rejected experiments retain their original version and are explicitly marked `REJECTED / SUPERSEDED`; they are never renumbered into the approved lineage.

## Custody rule

- **Google Drive / GAL Library:** authoritative approved visual references, governance records, research, QA, and archived release artifacts.
- **Git:** implementation source, tests, migrations, release branches, and machine-readable RC manifests.
- **Supabase/PostgreSQL:** governed operational data and durable runtime assets where specified by the approved asset manifest.
- **Production:** only reviewed/promoted artifacts.

## Production boundary

A review candidate is not production. Promotion requires a separate release decision after the RC Assembly Manifest and QA gates pass. Existing production-auth/security blockers remain blockers even when an RC otherwise passes visual and functional review.
