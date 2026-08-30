# Longitudinal Analytics Consent Withdrawal Policy

Status: Release-candidate governance policy

## Rule

Optional analytics consent is revocable. A golfer whose latest `ANALYTICS_OPTIONAL` consent is `DECLINED` or `WITHDRAWN` is excluded from newly built aggregate learning snapshots.

## Previously published aggregates

Published learning snapshots retain an internal, service-only contributor ledger solely so withdrawal can be honored deterministically. The ledger is not golfer-facing, customer-facing, or an Equipment Migration Intelligence publication surface.

When a contributing golfer withdraws optional analytics consent:

1. every affected `PUBLISHED` or `DRAFT` snapshot is recomputed using current latest-consent state;
2. the affected snapshot loses publication status immediately;
3. if the recomputed cohort remains at or above the privacy floor, the snapshot returns to `DRAFT` and must be explicitly reviewed/published again;
4. if the recomputed cohort falls below the floor, the snapshot becomes `WITHHELD`;
5. any `CANDIDATE`, `EVALUATED`, or `APPROVED` learning candidate sourced from the invalidated snapshot becomes `REJECTED`;
6. any `PRODUCTION` learning candidate sourced from it becomes `ROLLED_BACK` with a recorded consent-withdrawal reason;
7. the reconciliation operation is idempotent and audit-recorded.

## Privacy boundary

The contributor ledger exists only for withdrawal/recomputation governance. Browser roles have no direct table access. Aggregate publication must never expose contributor identity or a `user_id` dimension.

## External EMI rule

No externally published Equipment Migration Intelligence product may rely on a snapshot that has not survived the current consent and cohort-size checks. Historical external publication/retention terms require a separate reviewed policy before EMI launch.
