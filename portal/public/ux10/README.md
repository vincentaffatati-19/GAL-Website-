# GAL UX10.01 Governed Visual Assets

These assets implement the locked `GAL-UX10.01` layered scene architecture.

## Provenance

The tee-box and bag assets were prepared from the user-approved UX10 visual direction on 2026-09-04 for release-candidate review. They are stored as deterministic base64 source parts under `portal/ux10-assets/` and reconstructed by CI before tests/build.

## Usage

- `tee-boxes/coastal-01.webp` — presentation-only coastal tee-box environment (`Spyglass-inspired Coastal` review label).
- `tee-boxes/cliffs-01.webp` — presentation-only cliffside tee-box environment (`Torrey-inspired Cliffs` review label).
- `bags/gal-tour-bag.png` — transparent foreground tour-bag presentation asset.
- `bags/gal-stand-bag.png` — transparent foreground stand-bag presentation asset.

The course environment and bag visual are intentionally independent. Changing either must not alter golfer equipment records, fitting evidence, insights, recommendations, or analytical state.

## Rights / naming

The RC uses descriptive `-inspired` labels and does not claim official course affiliation, licensing, or exact course reproduction. Exact named-course use requires separately confirmed rights/approval.

## Integrity

Checksums are recorded in `SHA256SUMS` and verified in GitHub Actions before the portal test/build steps.
