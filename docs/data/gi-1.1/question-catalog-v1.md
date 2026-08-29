# GAL Golfer Intelligence Question Catalog — QUESTION-1.0

**Schema family:** GI-1.1  
**Catalog version:** QUESTION-1.0  
**Status:** Foundation vocabulary  
**Authority:** `public.gal_question_catalog`

## Governance rule

Buyer’s Guides, onboarding, Jerry’s Bag, and AI-assisted fitting must consume governed Question Catalog definitions rather than inventing independent golfer-profile semantics. Question wording may evolve through a new question version, but the canonical golfer fact remains governed by the Fact Catalog.

A known, current canonical fact should be reused instead of re-asking the golfer. A stale or materially uncertain fact should be confirmed. “I don’t know” is valid evidence and may route to an approved proxy path.

## QUESTION-1.0 foundation questions

| Question key | Canonical fact | Response | Level | Unknown / proxy behavior | Purpose |
|---|---|---|---|---|---|
| `game.handicap_index` | `game.handicap_index` | Number | Critical | Unknown allowed | Calibrates game level, forgiveness and consistency expectations. |
| `swing.iron_7.carry_yards` | `swing.iron_7.carry_yards` | Number | Critical | Unknown allowed | Supports iron speed, launch, gapping and category fit. |
| `swing.driver.speed_mph` | `swing.driver.speed_mph` | Number | Critical | Unknown routes to `swing.driver.carry_yards` through `driver_speed_estimation` | High-value input for driver launch, spin, loft, shaft and forgiveness. |
| `swing.driver.carry_yards` | `swing.driver.carry_yards` | Number | Critical | Member of `driver_speed_estimation` proxy group | Approved distance proxy when measured driver speed is unavailable. |
| `swing.driver.typical_miss` | `swing.driver.typical_miss` | Single select | Helpful | Unknown allowed | Distinguishes directional/forgiveness needs. |
| `goal.equipment_priority` | `goal.equipment_priority` | Single select | Helpful | Unknown allowed | Identifies the equipment outcome that matters most now. |
| `preference.value.price_sensitivity` | `preference.value.price_sensitivity` | Single select | Helpful | Unknown allowed | Governs golfer-specific value weighting; affiliate economics remain excluded. |

## Driver-speed proxy contract

The foundation proxy flow is deliberately explicit:

```text
Measured / known driver speed?
        │
        ├── Yes → store/use `swing.driver.speed_mph`
        │
        └── I don't know
                ↓
        ask `swing.driver.carry_yards`
                ↓
        deterministic proxy/inference model may estimate driver speed
                ↓
        inference keeps model, evidence and confidence provenance
```

The question response itself does not fabricate a speed. A later governed inference model may create an inferred speed range with confidence and evidence under the `gal_inferences` contract.

## Response-history contract

`public.gal_question_responses` stores append-only evidence of what was asked and answered. Each row binds to the exact `(question_catalog_id, question_key, question_version)` used at capture time and retains source context such as the originating Buyer’s Guide or session.

Normal authenticated golfers may read only their own response history. They cannot directly insert, update, or delete response evidence. Trusted application/server paths append evidence. Supersession is represented by new evidence plus lifecycle metadata rather than rewriting the original answer.

Supported foundation response states are:

- `ANSWERED`
- `UNKNOWN_DECLARED`
- `SKIPPED`
- `NOT_APPLICABLE`

## Cross-guide reuse

The intended flow is:

```text
Golfer Intelligence current facts
        +
Question Catalog
        ↓
Resolve known / stale / unknown
        ↓
Ask only material missing questions
        ↓
Append response evidence
        ↓
Normalize into canonical golfer facts or approved inference inputs
        ↓
Existing deterministic Buyer’s Guide scoring
```

This means, for example, that a 7-iron carry captured in the Irons Guide can be reused later by a Hybrid or Fairway Wood workflow when relevant. GAL must not create guide-specific duplicate facts such as `irons_7i_distance` or `hybrid_iron_distance`.

## Change control

QUESTION-1.0 is version governed. Wording or branching changes that materially affect meaning or response interpretation require a reviewed question-version transition. Historical responses always retain the version that produced them.
