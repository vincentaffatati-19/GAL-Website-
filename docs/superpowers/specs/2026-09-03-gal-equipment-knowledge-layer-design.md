# GAL Equipment Knowledge Layer Design

Status: APPROVED / LOCKED — PARTIAL ARCHITECTURE; DESIGN CONTINUES
Date: 2026-09-03
Applies to: GAL AI Fitting, Buyers Guides, My Bag, Equipment Intelligence, Equipment Testing, Recommendations, Comparisons, Commerce Routing, and future Fit My Bag orchestration.

## 1. Purpose

The GAL Equipment Knowledge Layer is the governed equipment-data foundation used by GAL to translate golfer needs into brand-neutral target characteristics and then evaluate actual equipment configurations against those targets.

It must support GAL's permanent analytical sequence:

`Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`

The Equipment Knowledge Layer must not be shaped around manufacturer marketing labels or retailer SKUs. GAL owns the analytical vocabulary used by AI Fitting.

## 2. Locked Source Philosophy — Multi-Source Equipment Evidence

GAL will use a multi-source equipment evidence model.

Different sources may coexist for the same product characteristic. GAL must preserve provenance and must not silently overwrite one source with another.

### Manufacturer / Authoritative Published Data

Manufacturer or authoritative technical documentation is appropriate for factual published specifications such as:
- product/model identity;
- stated loft options;
- published dimensions;
- published head or component weight where available;
- materials and construction;
- stock shaft/component choices;
- adjustability mechanisms and setting ranges;
- stated model-year/lifecycle information;
- officially offered configuration options.

Manufacturer marketing claims do not automatically become GAL analytical characteristics merely because they are published by the manufacturer.

### GAL Measured / Tested Data

GAL-controlled laboratory, fitting, or equipment-testing data is a primary source for characteristics GAL actually measures or observes, including where methodology supports them:
- launch behavior;
- spin behavior;
- dispersion behavior;
- strike/face performance;
- forgiveness/stability patterns;
- friction/spin-related performance;
- configuration response;
- category-specific performance characteristics.

GAL testing must preserve test method, sample/configuration, date, relevant environment, instrumentation, and methodology version.

### Independent / Partner Evidence

Licensed or otherwise permitted independent testing, partner data, structured fitting evidence, and other credible external evidence may be incorporated where useful.

Such data must remain attributed to its source and must comply with license, access, privacy, and commercial-use requirements.

### GAL Derived Characteristics

GAL may calculate or classify equipment characteristics from one or more underlying evidence sources using a governed, versioned methodology.

A GAL-derived characteristic must preserve the evidence references and methodology version that produced it.

## 3. Locked Canonical Equipment Structure

GAL will use a canonical:

`Product Family -> Product Variant -> Component -> Compatible Configuration`

model rather than treating every retailer SKU or product listing as an isolated fitting object.

### Product Family

Represents the stable named equipment family or model line.

Examples conceptually include a named driver family, iron family, wedge family, putter family, or golf-ball family.

### Product Variant

Represents meaningful variants within the family, such as:
- driver loft/head variant;
- fairway-wood loft;
- hybrid loft;
- iron/set member or set architecture variant;
- wedge loft/bounce/grind combination;
- putter head/hosel variant;
- ball version/model variant.

### Component

Represents independently meaningful components where the category supports them, for example:
- club head;
- shaft;
- adapter/hosel mechanism;
- grip;
- iron/wedge component specification;
- putter head/neck/grip components.

### Compatible Configuration

Represents a concrete fitting configuration assembled from compatible variants/components/settings.

Examples may include:
- driver head + loft + adapter setting + shaft + flex + weight + playing length + grip;
- iron head + shaft + length + lie + grip + set composition;
- wedge loft + bounce + grind + shaft + length + lie + grip;
- putter head + hosel + length + lie + loft + grip.

GAL fits configurations, not merely model names.

Compatibility rules must determine which components/settings can legitimately form a configuration.

## 4. Locked GAL-Owned Equipment Ontology

GAL will maintain its own equipment attribute ontology.

Manufacturer terminology may be stored as source metadata and mapped into GAL concepts, but manufacturer naming does not define GAL's analytical schema.

This protects AI Fitting from annual marketing-language changes and allows products from different manufacturers to be compared against the same golfer target.

### Universal Attribute Concepts

Where relevant by category, universal GAL concepts may include:
- forgiveness / stability;
- launch tendency;
- spin tendency;
- directional bias;
- adjustability;
- head / shape characteristics;
- weight characteristics;
- length;
- lie;
- loft;
- material / construction;
- feel;
- durability;
- intended role;
- skill-demand level;
- configuration flexibility.

Universal concepts do not imply that every category uses every attribute.

### Category-Specific Attributes

#### Driver
Potential fitting-relevant attributes include:
- MOI/stability measures or governed proxies;
- center-of-gravity characteristics where known;
- face-depth/geometry characteristics;
- effective loft and adjustment range;
- directional bias capability;
- launch/spin tendency;
- forgiveness pattern;
- head adjustability;
- shaft and playing-length compatibility.

#### Fairway Woods / Hybrids
Potential fitting-relevant attributes include:
- loft/gapping role;
- ease of launch;
- face height;
- sole/turf interaction;
- tee-versus-turf role;
- forgiveness;
- launch/spin/stopping tendency;
- directional bias;
- shaft/length compatibility.

#### Irons
Potential fitting-relevant attributes include:
- set architecture;
- blade/head dimensions;
- offset;
- sole width/geometry;
- topline/shape characteristics;
- center-of-gravity characteristics where known;
- forgiveness/stability;
- launch/spin/stopping tendency;
- length/lie ranges;
- shaft compatibility;
- grip sizing options;
- transition role to hybrids/woods and wedges.

#### Wedges
Potential fitting-relevant attributes include:
- loft;
- bounce;
- grind;
- sole geometry;
- leading-edge characteristics;
- heel/toe relief;
- turf/sand interaction;
- full-shot versus finesse-shot role;
- shaft/length/lie/grip configuration.

#### Putter
Potential fitting-relevant attributes include:
- head shape;
- stability characteristics;
- hosel/neck type;
- toe-hang / face-balance behavior where supported;
- alignment system;
- head weight;
- face technology;
- loft;
- lie;
- length;
- grip characteristics.

#### Ball
Potential fitting-relevant attributes include:
- compression/performance relationship;
- construction;
- cover type;
- driver flight/spin tendency;
- iron flight/spin/stopping tendency;
- greenside spin/feel;
- durability;
- price/value classification.

## 5. Attribute Record Requirements

Every fitting-relevant equipment attribute must support enough metadata to answer what GAL knows and why it believes it.

Conceptually an attribute observation/derivation should support:

`attribute + value/range/class + unit where applicable + source + source type + observed/published/derived state + methodology version when derived + effective date + evidence state + underlying evidence references`

Unknown values remain unknown.

GAL must not fabricate precision simply to make a fitting record look complete.

## 6. Locked Equipment Evidence Hierarchy

GAL uses four evidence classes for equipment knowledge.

### Class 1 — Published Specification

Directly supported by manufacturer or authoritative technical documentation.

Appropriate for factual specifications and officially offered options.

### Class 2 — GAL Measured

Produced through GAL-controlled testing, laboratory work, fitting, or other approved measurement processes.

This is the strongest basis for claims about what GAL itself observed, subject to the quality and scope of the test.

### Class 3 — Independent Observed

Produced by credible independent/partner evidence under appropriate licensing and provenance.

The original source remains visible internally and where golfer-facing attribution is relevant.

### Class 4 — GAL Derived

Calculated or classified by GAL from one or more supporting sources using a versioned methodology.

A derived characteristic must reference its underlying evidence.

## 7. Locked Claim-State Model

Fitting-relevant product claims use explicit support states.

### Known

The characteristic is directly supported by authoritative published data or qualifying measured evidence.

Examples may include stated loft, measured weight, supported adjustment range, or directly measured performance data.

### Derived

GAL calculated/classified the characteristic using an approved methodology and traceable evidence.

Examples may include a GAL launch-tendency class, forgiveness classification, or directional-support classification derived from qualifying evidence.

### Unknown / Insufficient Evidence

GAL does not currently have enough evidence to make a defensible claim.

GAL must prefer Unknown / Insufficient Evidence over invented precision or unverified marketing language.

## 8. Evidence Strength Constraint

**A derived equipment characteristic can never be stronger than the evidence supporting it.**

A GAL derivation must not convert weak, incomplete, or purely promotional source material into a strong analytical claim.

Where supporting sources disagree, GAL must preserve the disagreement and either:
- apply an approved context-specific resolution method;
- present a qualified derived state;
- or leave the characteristic Unknown / Insufficient Evidence.

## 9. Manufacturer Marketing Separation

Manufacturer language such as "Max," "HD," "Tour," "Fast," "LS," "forgiving," "high launch," or similar descriptors may be retained for identity/search/display purposes.

Such terminology must not automatically populate GAL analytical attributes.

GAL must map products into its own ontology based on qualifying evidence.

## 10. Relationship to AI Fitting

The Equipment Knowledge Layer supplies candidate configuration characteristics to the shared GAL AI Fitting engine only after the golfer's brand-neutral target characteristics have been established and frozen.

Conceptually:

`Frozen Golfer Target Characteristics + Equipment Knowledge -> Candidate Configuration Matching`

The same GAL target set must be usable to evaluate products across manufacturers.

## 11. Commerce Separation

Equipment Knowledge used for analytical ranking remains separate from commerce metadata such as:
- affiliate commission;
- retailer economics;
- paid placement;
- advertising relationship;
- sponsorship;
- inventory economics;
- promotional incentives.

Commercial factors must not alter analytical equipment characteristics or analytical candidate rank.

Price may be used as a golfer-declared fitting constraint/value consideration only through a governed product rule; commission remains excluded from analytical ranking.

## 12. Current Locked Decisions

The following #4 architectural decisions are approved and locked:

1. Multi-source equipment evidence with preserved provenance.
2. Manufacturer data is authoritative for qualifying published specifications, not automatically for GAL performance claims.
3. GAL measured/tested evidence supports GAL-observed performance characteristics.
4. Independent/partner evidence may coexist when credible and permitted.
5. GAL-derived characteristics require traceable evidence and methodology versioning.
6. Canonical `Product Family -> Variant -> Component -> Configuration` structure.
7. GAL fits configurations rather than merely product names.
8. GAL owns the universal + category-specific equipment ontology.
9. Manufacturer terminology maps into GAL concepts and does not define them.
10. Four evidence classes: Published Specification, GAL Measured, Independent Observed, GAL Derived.
11. Three claim states: Known, Derived, Unknown / Insufficient Evidence.
12. A derived claim cannot exceed the strength of its supporting evidence.
13. Unknown is preferable to fabricated or unsupported precision.
14. Analytical equipment knowledge is separated from commerce influence.

## 13. Design Status / Next Sections

The Equipment Knowledge Layer design is not yet complete. The approved sections above are locked architectural requirements.

Remaining design topics should include:
- equipment source ingestion and source governance;
- test/sample/configuration representation;
- versioning and product lifecycle;
- compatibility/configuration rules;
- category completeness requirements for AI Fitting eligibility;
- handling conflicting measurements and repeated tests;
- equipment image/media rights and provenance;
- data review/promotion workflow from research to production;
- Equipment Knowledge completeness/quality states;
- update cadence and new-model onboarding;
- public Buyers Guide reuse;
- schema implications and Supabase gap analysis.

No production schema changes are authorized by this design document alone.
