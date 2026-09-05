# Contributing to Golf Analytics Lab

## Mandatory GAL governance preflight

Before changing GAL design, UX, code, database behavior, guides, branding, portal behavior, data models, or release configuration:

1. Read `GAL_GOVERNANCE_RULE.md`.
2. Retrieve the current governing specification/version record for the workstream.
3. For My GAL / portal UX work, read `GAL_UX_MANIFEST.json`, `GAL_UX_CURRENT.md`, and the authoritative versioned UX specification referenced by the manifest.
4. Retrieve/verify the locked visual reference when presentation is affected.
5. Compare the proposed work with the current lock before editing implementation.
6. If the request conflicts with a locked decision, surface the conflict before implementation.
7. If authoritative governing material cannot be retrieved, do not proceed with implementation.
8. When the user says `lock it`, `replace it`, `make this the rule`, `use this going forward`, or equivalent language, persist the decision into the appropriate GAL governance record immediately.

The most recent implementation, mockup, release candidate, or assistant output is **not** automatically the approved source of truth. Code may lag the lock; code must not silently supersede it.

## UX source-of-truth and versioning

The current architectural UX family is `GAL-UX10`.

- Initial locked version: `GAL-UX10.01`.
- Revisions inside the same architecture increment sequentially as `.02`, `.03`, `.04`, and so on.
- Review candidates append `-RC1`, `-RC2`, etc.
- A new whole-number UX family requires an explicit user-approved architectural replacement decision.
- Every locked UX revision updates `GAL_UX_MANIFEST.json`, `GAL_UX_CURRENT.md`, the governing versioned specification, and the governance archive together.

For UX10 specifically, the tee-box environment and personalized bag visual are independent presentation layers. A combined course+bag scene image must not be used as the active UX10 architecture, and neither presentation preference may affect analytical state.

## Branch workflow

GAL uses a controlled branch and release model:

- `main` — production only. Do not develop or upload feature files directly to `main`.
- `develop` — integrated development branch.
- `feature/*` — isolated feature work created from the applicable verified development/reconciliation base.
- `release/*` — release-candidate branches created only after integrated verification.

## Required flow

1. Create an isolated `feature/*` branch from the applicable verified base.
2. Make and verify changes on the feature branch.
3. Open a pull request into the applicable integration/reconciliation branch.
4. Verify shared behavior, including both golfer/user and industry/customer portals when shared UX, personalization, data, or navigation changes are involved.
5. Create a `release/*` branch only after integrated verification.
6. Verify the release candidate in staging/preview.
7. Promote toward `main` only after review and explicit production-readiness approval.
8. Archive an approved production release to the GAL Production area in Google Drive with its commit/tag and model/data versions.

## Production rules

- No manual feature uploads directly to `main`.
- No unreviewed database migrations in production.
- No secrets, private keys, passwords, service-role credentials, or production `.env` files in Git.
- Production golfer data must not be copied into development or preview environments unless explicitly anonymized/sanitized.
- Recommendation ranking must remain independent from commerce payout.
- Production promotion requires explicit user approval.

## Release naming

Use governed release identifiers such as `GAL-vX.Y.Z` or the applicable component-specific identifier. UX review candidates use the locked UX version plus RC suffix, for example `GAL-UX10.01-RC1`. Every production release must be traceable to a Git commit and, where applicable, database migration, equipment-data version, scoring-model version, and AI/model version.
