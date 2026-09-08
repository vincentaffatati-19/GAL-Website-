# GAL UX10.02 — STEP17.3.2 Dynamic Visual Corrections QA

Status: REVIEW CANDIDATE ONLY — not Production.

## Reviewer-reported corrections

1. Female profile displayed the wrong gender image when Age Range was `Not provided` or `Prefer not to say`.
2. `Longitudinal / Audit Trail` should be hidden/collapsible with a `+ / −` control.
3. `Review Your Golfer Profile` should be hidden/collapsible with a `+ / −` control.
4. `Your Miss` reference artwork was cropped/obscured by the section layout near `Save My Miss Profile`.

## Root causes

- The dynamic visual resolver treated every adult age value that was not one of the explicit age bands as `neutral_adult`, even when Gender was explicitly Male or Female.
- The review and audit sections were permanently expanded in STEP17.3.
- The Your Miss composite reference image inherited the generic hero-image rule (`width:100%; height:100%; object-fit:cover`), which cropped a 1222×590 informational composite into a much taller two-column container.

## Corrections

### Gender-safe unknown-age routing

- Explicit Male + unknown/undisclosed age routes to `male_age_unspecified`.
- Explicit Female + unknown/undisclosed age routes to `female_age_unspecified`.
- Non-binary / another identity, Prefer not to say gender, or missing gender retain neutral visual families.
- Junior routing remains gender-aware for Male/Female and neutral otherwise.
- Unknown-age Male/Female aliases use durable approved same-gender embedded Body and Swing masters, so the image remains visible even when externally hosted review assets are unavailable.

### Compact profile sections

- `Review Your Golfer Profile` starts collapsed and uses an accessible `+ / −` disclosure button.
- `Longitudinal / Audit Trail` starts collapsed and uses the same disclosure behavior.
- `aria-expanded`, `aria-controls`, and dynamic expand/collapse labels are maintained.

### Your Miss layout

- Added a dedicated `.miss-reference` visual treatment.
- The composite artwork now renders at its natural aspect ratio with `object-fit: contain` rather than hero-style cropping.
- Desktop allocates additional width to the artwork while keeping the form controls in a distinct column.
- At <=1100 px the section stacks into one column, keeps the artwork uncropped, and places Save controls below the reference image.

## Automated regression coverage

`test_step17_3_2_regressions.py` verifies:

- 5 gender states × 10 age states = 50 resolver combinations.
- Explicit regression cases for Female/Male with both `Not provided` and `Prefer not to say` age.
- Unknown-age Male/Female visual sources are embedded same-gender masters with nonzero natural image dimensions.
- Both long sections are collapsed by default, expand/collapse correctly, and switch `+` ↔ `−`.
- Your Miss uses the dedicated reference layout, `object-fit: contain`, natural aspect ratio, and no Save-button/image intersection on desktop and mobile.
- Zero uncaught page errors during the regression run.

## Browser evidence

- `STEP17.3.2-FEMALE-NOT-PROVIDED.png`
- `STEP17.3.2-FEMALE-PREFER-NOT.png`
- `STEP17.3.2-MALE-NOT-PROVIDED.png`
- `STEP17.3.2-YOUR-MISS-DESKTOP.png`
- `STEP17.3.2-YOUR-MISS-MOBILE.png`
- `STEP17.3.2-COLLAPSED-SECTIONS.png`

## Release posture

STEP17.3.2 supersedes STEP17.3.1 for review. It does not modify or promote the prior approved RC to Production. The previously documented durable-asset custody gate for newly generated Runway persona pairs remains separate and unchanged.
