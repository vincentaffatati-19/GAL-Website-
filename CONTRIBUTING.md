# Contributing to Golf Analytics Lab

## UX source-of-truth preflight

Before changing My GAL, portal visual design, navigation, interaction architecture, or any shared registered/subscriber UX:

1. Read `GAL_UX_MANIFEST.json`.
2. Read `GAL_UX_CURRENT.md`.
3. Read the authoritative versioned UX specification referenced by the manifest.
4. Compare the proposed work with the current lock before editing code.
5. If the proposed work conflicts with the current lock, stop and obtain an explicit user-approved superseding UX decision with a new UX identifier.
6. When a new UX is approved, update the manifest, current-UX pointer, and versioned specification in the same governed change.

The most recent implementation or release candidate is **not** automatically the approved UX. Code may lag the lock; code must not silently supersede it.

## Branch workflow

GAL uses a controlled branch and release model:

- `main` — production only. Do not develop or upload feature files directly to `main`.
- `develop` — integrated development branch.
- `feature/*` — isolated feature work created from `develop`.
- `release/*` — release-candidate branches created from `develop` after integrated verification.

## Required flow

1. Create a `feature/*` branch from `develop`.
2. Make and verify changes on the feature branch.
3. Open a pull request into `develop`.
4. Verify shared behavior, including both golfer/user and industry/customer portals when shared UX, personalization, data, or navigation changes are involved.
5. Create a `release/*` branch from verified `develop`.
6. Verify the release candidate in staging/preview.
7. Open a pull request from the `release/*` branch into `main`.
8. Promote only after review and production-readiness checks.
9. Archive the approved production release to the GAL Production area in Google Drive with the commit/tag and model/data versions.

## Production rules

- No manual feature uploads directly to `main`.
- No unreviewed database migrations in production.
- No secrets, private keys, passwords, service-role credentials, or production `.env` files in Git.
- Production golfer data must not be copied into development or preview environments unless explicitly anonymized/sanitized.
- Recommendation ranking must remain independent from commerce payout.

## Release naming

Use governed release identifiers such as `GAL-vX.Y.Z` or the applicable component-specific identifier. Every production release must be traceable to a Git commit and, where applicable, database migration, equipment-data version, scoring-model version, and AI/model version.
