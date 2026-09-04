# GAL Equipment Identity, Deduplication & Product Lifecycle

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: Equipment Knowledge Layer, My Bag, AI Fitting, Buyers Guides, equipment valuation, testing, comparisons, recommendations, and longitudinal equipment history.

## 1. Purpose

GAL requires a permanent, canonical equipment identity system so that manufacturer records, retailer listings, partner datasets, test samples, My Bag entries, and historical recommendations all resolve to the same governed equipment entities.

The system must prevent duplicate fitting candidates, preserve historical equipment identity, and maintain valid configuration compatibility across generations and lifecycle changes.

## 2. Canonical Identity Model

GAL will maintain stable source-independent canonical identities for:
- manufacturer / brand;
- product family;
- product variant;
- component;
- compatible configuration.

External source names, SKUs, retailer IDs, manufacturer IDs, partner IDs, and alternate spellings do not create new canonical products by themselves. They map to canonical GAL identities through governed alias/source-reference records.

## 3. Alias and Source Mapping

Multiple external records may resolve to one canonical GAL entity.

Examples include:
- manufacturer product code;
- retailer SKU;
- partner catalog ID;
- alternate product naming;
- regional naming;
- capitalization/punctuation variations;
- abbreviated model labels.

Alias records should preserve source, source identifier, source label, effective period when known, and mapping status.

## 4. Deduplication

GAL must not deduplicate equipment solely by product name.

Identity resolution should consider multiple signals, including:
`manufacturer + normalized family + category + generation/model year + variant attributes + source identifiers + configuration signature`

Potential duplicates should be automatically detected and routed to governed review where certainty is insufficient.

Merging identities must preserve the prior source mappings and an audit trail.

## 5. Product Generations

Product generations must be represented explicitly rather than silently overwriting prior models.

Relationships may include:
- predecessor;
- successor;
- refresh/revision;
- sibling variant;
- regional variant;
- reissue.

A successor model remains a distinct canonical identity even when marketing names are similar.

## 6. Lifecycle States

Core lifecycle states:
- ANNOUNCED;
- CURRENT;
- RETIRED;
- ARCHIVED.

Additional category/product states may include:
- LIMITED;
- TOUR_ONLY;
- REGION_SPECIFIC;
- DISCONTINUED;
- REISSUED.

Lifecycle state must be sourced and temporally traceable where possible.

## 7. Historical Preservation

GAL never deletes historical equipment identity merely because a product is discontinued or retired.

Historical products must remain resolvable because they may still be relevant to:
- current golfer My Bag records;
- previous fittings;
- before/after outcomes;
- equipment-value workflows;
- resale/trade analysis;
- historical Buyers Guides;
- longitudinal Progress;
- comparison against current models.

## 8. Compatibility Rules

Component and configuration compatibility must be represented as governed evidence-backed rules rather than inferred from names.

A compatibility record should support:
`component/configuration A <-> product/variant B + compatibility rule + effective period + source + support state`

Compatibility can vary by generation, region, handedness, loft, adapter family, shaft-tip specification, set architecture, or other category-specific constraints.

GAL must not generate a fitting candidate that cannot be verified as physically/configurationally possible.

## 9. Lifecycle-Aware Configuration

A configuration may be valid only for a specific period or product generation.

Historical fittings must preserve the compatibility knowledge/version used at the time of the fitting so later product-database changes do not make the historical decision unreproducible.

## 10. Identity Certainty vs Performance Certainty

Identity certainty and analytical performance certainty are separate concepts.

GAL may be highly certain that two retailer listings refer to the same canonical driver while having insufficient evidence to classify that driver's spin behavior.

The data model must not collapse these dimensions into a single generic confidence score.

## 11. Locked Decisions

1. Canonical equipment identities are permanent and source-independent.
2. External SKUs, names, and source IDs map to canonical aliases rather than creating duplicate products.
3. Product generations use explicit predecessor/successor and related-generation relationships.
4. Retired/discontinued equipment remains fully identifiable and usable in My Bag and historical workflows.
5. Compatibility rules are explicit, sourced, versioned, and lifecycle-aware.
6. Deduplication uses multiple identity signals, not names alone.
7. Identity certainty and performance certainty remain separate.
8. Invalid or unverified configurations must not enter AI Fitting candidate generation.

No production schema changes are authorized by this document alone.