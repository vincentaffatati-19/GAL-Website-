# GI-1.1 PR #3 Reconciliation

Status: PR #3 retired as an integration vehicle; source branch preserved for selective extraction.

## Why PR #3 must not merge as-is

PR #3 is a 150-commit draft created before the governed Tasks 8–13 longitudinal chain. It contains many useful GI-1.1 assets, but its migration series uses historical timestamps that precede the now-established material-insight, exposure, response, outcome, aggregate-learning, and promotion migrations. Merging the draft wholesale after the newer release chain would make migration history and architectural authority ambiguous.

## Preserve and selectively extract

The following families remain valuable and should be rebased/extracted into fresh, focused PRs against the current `main` after the longitudinal release is complete:

- governance/fact/question/event catalogs;
- profile fact history and governed inferences;
- consent governance improvements that do not conflict with the current withdrawal-reconciliation policy;
- profile, bag, and intelligence snapshots;
- bag history, scenarios, and bag scoring;
- recommendation runs, items, and audit links;
- buyer-event vocabulary/extensions;
- deterministic intelligence-state builder/rebuild tests;
- sanitized production-shaped test baseline and CI workflow concepts;
- previously identified backend security hardening that is still applicable.

## Superseded / requires redesign before extraction

Any PR #3 logic that assumes it is the authoritative longitudinal feedback loop must defer to the current governed chain:

`signal -> insight -> exposure -> response -> outcome -> resolution -> privacy-safe aggregate learning -> evaluated candidate -> governed promotion`

Consent logic must also preserve the newer rule that withdrawal can invalidate/recompute published aggregates and roll back dependent learning candidates.

## Release rule

Do not reopen or merge PR #3 wholesale. Create new PRs by concern, each based on current `main`, with fresh migration timestamps and staging verification. The original branch remains an archive/reference source until all useful components are either extracted or intentionally retired.
