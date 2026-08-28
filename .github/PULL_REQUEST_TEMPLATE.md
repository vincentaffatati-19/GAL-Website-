# GAL Pull Request Checklist

## Change summary

Describe what changed and why.

## Branch / release path

- [ ] This work was developed outside `main`.
- [ ] Feature work targets `develop` first.
- [ ] Production promotion comes from a `release/*` branch after RC/staging verification.

## Verification

- [ ] Core navigation and affected pages/tools verified.
- [ ] Mobile/responsive behavior verified where applicable.
- [ ] Existing Buyer’s Guides affected by shared code/data verified.
- [ ] Golfer/user portal verified when affected.
- [ ] Industry/customer portal verified when shared UX, personalization, data, or navigation is affected.
- [ ] No production secrets or private credentials committed.
- [ ] No unsanitized production golfer data added to development/test assets.

## Data / recommendation governance

- [ ] Canonical product IDs and provenance remain intact where equipment data changed.
- [ ] Recommendation/scoring logic is versioned where changed.
- [ ] Recommendation ranking remains independent of commerce payout.
- [ ] Database/schema changes have a migration/version path where applicable.

## Release readiness (required for PRs into `main`)

- [ ] Release Candidate verified in staging/preview.
- [ ] Release/version identifier recorded.
- [ ] Production rollback point is known.
- [ ] Google Drive Production archive/update is prepared.
