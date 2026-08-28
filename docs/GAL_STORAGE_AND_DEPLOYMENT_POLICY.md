# GAL Storage & Deployment Policy

Status: LOCKED

## Systems of record

- Google Drive preserves GAL business records, governance, approved UX/data specifications, brand assets, research, and production archives.
- GitHub preserves executable application source code, database migrations, scoring logic, and release history.
- Supabase preserves operational golfer, bag, recommendation, behavioral, consent, and longitudinal data.
- ChatGPT is the working environment for design, analysis, development, and orchestration; it is not the permanent system of record.

## Branch policy

- `main` — production only.
- `develop` — integrated development.
- `feature/*` — isolated feature work.
- `release/*` — release candidates.

No direct feature development should occur on `main`.

## Release path

Develop → Preview → Release Candidate / Staging → Verify → Approve → Production → Archive.

Production changes must be reviewed and verified before promotion. Shared UX or personalization changes affecting both golfer/user and industry/customer portals must be updated and verified together.

## Data/environment policy

- Development and preview environments use test/synthetic data.
- Staging may use sanitized/anonymized data when necessary.
- Production golfer data must not be copied into development or preview environments unless explicitly anonymized/sanitized.
- Secrets, passwords, private keys, and service-role credentials must never be committed to Git.
- Environment values belong in local/deployment secret stores; `.env.example` contains names only.

## Google Drive release archive

Approved production releases should be archived to the GAL Production area in Google Drive with version, status, promotion date, source commit/tag, data/scoring/model versions, and verification notes.

## Release versioning

Use governed GAL release identifiers such as `GAL-vX.Y.Z` or the applicable component-specific release identifier. Every production release should be traceable to a Git commit and, where applicable, database migration/model version.
