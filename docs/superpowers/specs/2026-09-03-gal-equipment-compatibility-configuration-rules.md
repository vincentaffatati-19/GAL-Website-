# GAL Equipment Compatibility & Configuration Rules

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: GAL Equipment Knowledge Layer, AI Fitting, My Bag, configuration generation, comparisons, recommendations, testing, and future Fit My Bag orchestration.

## Purpose

GAL must only evaluate and recommend physically valid, actually buildable equipment configurations. Compatibility is a governed analytical domain, not an assumption inferred from retailer listings.

## Core Rule

`Product Variant + Component + Setting + Constraint Rules -> Valid Configuration`

GAL generates valid configurations first, then evaluates those configurations against the golfer's frozen target characteristics.

## Compatibility States

Every relevant compatibility assertion uses one of these states:

- VALID — supported configuration.
- INVALID — known incompatible or impossible.
- UNKNOWN — insufficient evidence to assert compatibility.

Unknown must not be treated as valid.

## Hard Compatibility

Compatibility rules may govern, where relevant:
- shaft/adapter/head compatibility;
- model-generation compatibility;
- loft and lie settings;
- handedness-specific settings;
- allowable playing-length ranges;
- shaft/hosel compatibility;
- grip/shaft sizing compatibility;
- iron/wedge shaft and head compatibility;
- wedge loft/bounce/grind combinations;
- putter head/hosel/neck combinations;
- region/model-year restrictions;
- component availability periods;
- any other deterministic build constraint.

These rules must be explicitly sourced and versioned.

## Configuration Effects

A configuration is not merely metadata. Settings and component changes may alter the equipment's analytical profile.

Conceptually:

`Base Head Characteristics + Adapter Transformation + Weight-Setting Transformation + Shaft Characteristics + Length/Lie/Grip Effects -> Configured Equipment Profile`

GAL applies an effect only when the relationship is supported by qualifying evidence.

## Known Mechanical Effects vs Derived Performance Effects

GAL distinguishes:

### Known Mechanical Effects

Examples:
- manufacturer-documented loft or lie geometry;
- component weight;
- playing length;
- deterministic adapter position;
- directly measured static specifications.

### Derived Performance Effects

Examples:
- expected launch change;
- expected spin change;
- expected directional-bias change;
- expected strike-consistency change;
- expected dispersion change;
- expected speed effect.

Derived performance effects require GAL measured/observed evidence or a governed versioned model. They are not assumed from mechanical compatibility alone.

## Governing Principle

**Physical compatibility may be deterministic; performance response usually is not. GAL must not confuse the two.**

## Rule Record Requirements

A compatibility or transformation rule should conceptually support:
- rule_id;
- rule_scope;
- applies_to product/variant/component/configuration;
- condition;
- allowed/disallowed range or state;
- source/provenance;
- effective dates/version;
- compatibility state;
- evidence/claim state;
- methodology version when derived;
- supersession relationship when updated.

## AI Fitting Generation Order

GAL AI Fitting uses this sequence:

1. Produce/freeze brand-neutral target characteristics.
2. Generate only valid configurations from the Equipment Knowledge Layer.
3. Exclude invalid and materially unknown configurations.
4. Apply supported configuration transformations.
5. Score valid configured equipment against the frozen target set.
6. Explain matches, tradeoffs, unknowns, and supporting evidence.

The fitting engine must not score an impossible configuration and then attempt to fix compatibility afterward.

## Unknown Effects

A configuration can be physically buildable while its performance effect remains unknown.

Examples:
- Can the shaft be installed? VALID.
- Can the club be built to a supported length? VALID.
- Will that length improve this golfer's dispersion? UNKNOWN unless supported.
- Does an adapter setting mechanically change stated loft? KNOWN when documented.
- Does it create a specific spin delta for this golfer? Not assumed.

## Lifecycle Awareness

Compatibility is temporally versioned. Historical fitting sessions must remain reproducible even after component offerings, adapters, manufacturing revisions, or compatibility relationships change.

Historical compatibility rules are preserved rather than silently rewritten.

## Relationship to My Bag

My Bag may contain current, retired, or custom equipment configurations. GAL should validate known components and settings where possible while preserving golfer-entered unknown/custom attributes with appropriate evidence states.

A currently owned configuration is not automatically a valid manufacturer-stock configuration; custom builds must be representable separately from stock availability.

## Relationship to Testing

Physical test records must reference the exact configuration actually tested. A test of one setting/shaft/length does not automatically support all compatible configurations of the same product family.

## Editorial Integrity

Commercial availability, affiliate economics, paid placement, or retailer inventory do not establish compatibility and must not influence analytical compatibility rules.

## Locked Decisions

1. GAL fits only verifiably buildable configurations.
2. Compatibility uses VALID / INVALID / UNKNOWN states.
3. Unknown is never assumed valid.
4. Hard compatibility is governed separately from predicted performance response.
5. Configuration changes may alter the analytical equipment profile only when effects are supported.
6. Mechanical effects and performance effects are distinct evidence domains.
7. Compatibility/configuration rules are sourced, versioned, and lifecycle-aware.
8. Valid configurations are generated before analytical scoring.
9. Historical compatibility remains reproducible.
10. Commerce does not establish or alter compatibility.

No production schema changes are authorized by this specification alone.
