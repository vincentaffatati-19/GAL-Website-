# GAL Golfer Intelligence Fact Catalog — FACT-1.0

**Schema family:** GI-1.1  
**Catalog version:** FACT-1.0  
**Status:** Foundation vocabulary  
**Authority:** `public.gal_fact_catalog`

## Governance rule

No GAL feature, Buyer’s Guide, AI process, dashboard, import, or derived-intelligence process may create a new golfer fact key unless that key is first registered through a reviewed Fact Catalog migration. Product-specific wording may change, but canonical fact semantics remain governed here.

Current equipment ownership is not represented as profile facts. `gal_bags` and `gal_bag_items` remain authoritative for the golfer’s equipment state.

## FACT-1.0 vocabulary

| Fact key | Domain | Type / unit | Refresh | Commercial class | Purpose |
|---|---|---|---|---|---|
| `golfer.display_name` | golfer | text | stable | personal_only | Individual golfer-facing display name. |
| `physical.height` | physical | number / inches | stable | restricted_aggregate | Stature input for equipment-fit contexts where height is relevant. |
| `experience.years_playing` | experience | number / years | seasonal | aggregate_eligible | Golf experience proxy. |
| `game.handicap_index` | game | number | dynamic | aggregate_eligible | Current Handicap Index or equivalent golfer-reported index. |
| `game.typical_score` | game | number / strokes | dynamic | aggregate_eligible | Typical-score proxy when an index is unavailable. |
| `swing.driver.speed_mph` | swing | number / mph | dynamic | aggregate_eligible | Driver clubhead speed; approved proxy inference is allowed. |
| `swing.driver.carry_yards` | swing | number / yards | dynamic | aggregate_eligible | Typical driver carry. |
| `swing.iron_7.carry_yards` | swing | number / yards | dynamic | aggregate_eligible | Typical 7-iron carry. |
| `swing.driver.shot_shape` | swing | enum | dynamic | aggregate_eligible | Typical driver curvature pattern. |
| `swing.driver.typical_miss` | swing | enum | dynamic | aggregate_eligible | Primary driver miss pattern. |
| `preference.performance.forgiveness` | preferences | enum | seasonal | aggregate_eligible | Forgiveness preference relative to other performance tradeoffs. |
| `preference.appearance.irons` | preferences | enum | seasonal | aggregate_eligible | Iron visual-profile preference. |
| `preference.value.price_sensitivity` | value | enum | seasonal | aggregate_eligible | Degree to which price influences golfer-specific value scoring. |
| `goal.primary_game_goal` | goals | enum | seasonal | aggregate_eligible | Primary current golf objective. |
| `goal.equipment_priority` | goals | enum | event_driven | aggregate_eligible | Equipment outcome the golfer most wants to improve next. |
| `environment.primary_region` | environment | text | seasonal | restricted_aggregate | Coarse playing-region context; not precise location. |
| `behavior.brand_consideration` | behavior | multiselect | event_driven | aggregate_eligible | Behavioral brand-consideration signal kept distinct from declared preference. |

## Privacy and commercial-use semantics

`aggregate_eligible` facts may contribute to governed de-identified aggregate intelligence subject to GAL privacy thresholds and consent. `restricted_aggregate` facts require stronger cohort/privacy handling. `personal_only` facts remain individual-experience data and are excluded from commercial aggregate products.

Sensitive health, medical, physical-limitation, and free-text fitting-accommodation facts are intentionally **not** part of the initial FACT-1.0 vocabulary. If GAL later needs such facts to serve an individual golfer, they require explicit catalog review and an `excluded_from_commercial_use` classification.

## Change control

FACT-1.0 is append-and-version governed. A future semantic change must use a reviewed migration and version transition; application code must not silently reinterpret an existing key. Historical facts retain the semantics and provenance that applied when they were captured.
