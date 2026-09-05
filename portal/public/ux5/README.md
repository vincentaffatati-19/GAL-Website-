# GAL UX5 visual asset provenance

## Provenance

This directory contains the presentation-only realistic bag scene used by `GAL-UX5-MID-RC1`. The source image was supplied inside the Golf Analytics Lab project as the locked UX5 visual reference and is being used only to reproduce the approved My GAL review composition.

## Source

- Original project reference: `ux5-reference-bag.webp`
- Source dimensions: 480 × 1181 pixels
- Source context: user/project-supplied locked UX5 reference image
- External hotlinking: none

## Usage

The image is atmosphere and interface presentation only. It does **not** assert that the photographed bag, club heads, shafts, logos, specifications, or configuration are the authenticated golfer's actual equipment. Actual golfer equipment identity and fit status continue to come only from governed My Bag / fitting data.

Project-use authorization comes from the user-provided GAL reference asset. Do not redistribute this asset outside the GAL project without confirming the underlying rights for that broader use.

## Modification

`reference-bag.webp` is a review-optimized derivative of the supplied reference image: resized/cropped to 260 × 625 and encoded as WebP at quality 82 for the portal scene. No generated replacement logo is used. The locked Option 7A site logo remains a separate governed asset.

Expected SHA-256:

`11c1f63ab18cb952d1d3ca1a9831905117e93231257b37535a6855b168e3b85f`

For repository builds that do not store the binary directly, reconstruct it from the governed base64 parts before test/build:

`mkdir -p portal/public/ux5 && cat portal/ux5-assets/reference-bag.b64.part* | base64 --decode > portal/public/ux5/reference-bag.webp`
