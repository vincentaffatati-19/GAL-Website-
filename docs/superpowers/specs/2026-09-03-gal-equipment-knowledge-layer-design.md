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

GAL will use a multi-source equipment evidence model. Different sources may coexist for the same product characteristic. GAL must preserve provenance and must not silently overwrite one source with another.

### Manufacturer / Authoritative Published Data
Manufacturer or authoritative technical documentation is appropriate for factual published specifications such as product/model identity, stated loft options, published dimensions, published head/component weight, materials/construction, stock component choices, adjustability mechanisms/settings, lifecycle information, and officially offered configurations. Manufacturer marketing claims do not automatically become GAL analytical characteristics.

### GAL Measured / Tested Data
GAL-controlled laboratory, fitting, or equipment-testing data is a primary source for characteristics GAL actually measures or observes, including launch, spin, dispersion, strike/face performance, forgiveness/stability patterns, friction/spin-related performance, configuration response, and category-specific performance. Testing must preserve test method, sample/configuration, date, relevant environment, instrumentation, and methodology version.

### Independent / Partner Evidence
Licensed or otherwise permitted independent testing, partner data, structured fitting evidence, and other credible external evidence may be incorporated where useful. Such data must remain attributed and comply with license, access, privacy, and commercial-use requirements.

### GAL Derived Characteristics
GAL may calculate or classify equipment characteristics from one or more underlying evidence sources using a governed, versioned methodology. A derived characteristic must preserve evidence references and methodology version.

## 3. Locked Canonical Equipment Structure

GAL will use a canonical:

`Product Family -> Product Variant -> Component -> Compatible Configuration`

model rather than treating every retailer SKU or product listing as an isolated fitting object.

- **Product Family** represents the stable named equipment family/model line.
- **Product Variant** represents meaningful variants such as driver loft/head, fairway/hybrid loft, iron/set architecture, wedge loft/bounce/grind, putter head/hosel, or ball version.
- **Component** represents independently meaningful pieces such as head, shaft, adapter/hosel, grip, or category-specific components.
- **Compatible Configuration** represents a concrete fitting build assembled from compatible variants/components/settings.

GAL fits configurations, not merely model names. Compatibility rules determine which components/settings can legitimately form a configuration.

## 4. Locked GAL-Owned Equipment Ontology

GAL maintains its own equipment attribute ontology. Manufacturer terminology may be stored as source metadata and mapped into GAL concepts, but manufacturer naming does not define GAL's analytical schema.

### Universal Attribute Concepts
Where relevant by category: forgiveness/stability, launch tendency, spin tendency, directional bias, adjustability, head/shape characteristics, weight characteristics, length, lie, loft, material/construction, feel, durability, intended role, skill-demand level, and configuration flexibility.

### Category-Specific Attributes
- **Driver:** MOI/stability measures or governed proxies, CG characteristics where known, face/geometry, effective loft/adjustment range, bias capability, launch/spin tendency, forgiveness pattern, head adjustability, shaft/length compatibility.
- **Fairway Woods / Hybrids:** loft/gapping role, ease of launch, face height, sole/turf interaction, tee-vs-turf role, forgiveness, launch/spin/stopping tendency, bias, shaft/length compatibility.
- **Irons:** set architecture, dimensions, offset, sole geometry, topline/shape, CG where known, forgiveness/stability, launch/spin/stopping tendency, length/lie ranges, shaft/grip options, transition roles.
- **Wedges:** loft, bounce, grind, sole geometry, leading edge, heel/toe relief, turf/sand interaction, full-shot vs finesse role, shaft/length/lie/grip configuration.
- **Putter:** head shape, stability, hosel/neck, toe-hang/face-balance behavior where supported, alignment, head weight, face technology, loft, lie, length, grip.
- **Ball:** compression/performance relationship, construction, cover, driver flight/spin tendency, iron flight/spin/stopping tendency, greenside spin/feel, durability, price/value classification.

## 5. Attribute Record Requirements

Every fitting-relevant equipment attribute must support enough metadata to answer what GAL knows and why it believes it:

`attribute + value/range/class + unit where applicable + source + source type + observed/published/derived state + methodology version when derived + effective date + evidence state + underlying evidence references`

Unknown values remain unknown. GAL must not fabricate precision simply to make a fitting record look complete.

## 6. Locked Equipment Evidence Hierarchy

GAL uses four evidence classes:
1. **Published Specification** — directly supported by manufacturer or authoritative technical documentation.
2. **GAL Measured** — produced through GAL-controlled testing, laboratory work, fitting, or other approved measurement processes.
3. **Independent Observed** — credible independent/partner evidence under appropriate licensing and provenance.
4. **GAL Derived** — calculated/classified by GAL from one or more supporting sources using a versioned methodology.

## 7. Locked Claim-State Model

Fitting-relevant product claims use explicit support states:
- **Known** — directly supported by authoritative published data or qualifying measured evidence.
- **Derived** — calculated/classified by GAL using an approved methodology and traceable evidence.
- **Unknown / Insufficient Evidence** — GAL does not currently have enough evidence to make a defensible claim.

GAL must prefer Unknown / Insufficient Evidence over invented precision or unverified marketing language.

## 8. Evidence Strength Constraint

**A derived equipment characteristic can never be stronger than the evidence supporting it.**

Weak, incomplete, or purely promotional source material cannot be converted into a strong analytical claim. When sources disagree, GAL preserves the disagreement and either applies an approved context-specific resolution method, presents a qualified derived state, or leaves the characteristic Unknown / Insufficient Evidence.

## 9. Manufacturer Marketing Separation

Manufacturer terms such as "Max," "HD," "Tour," "Fast," "LS," "forgiving," or "high launch" may be retained for identity/search/display but must not automatically populate GAL analytical attributes. GAL maps products into its own ontology based on qualifying evidence.

## 10. Relationship to AI Fitting

The Equipment Knowledge Layer supplies candidate configuration characteristics to the shared GAL AI Fitting engine only after the golfer's brand-neutral target characteristics have been established and frozen:

`Frozen Golfer Target Characteristics + Equipment Knowledge -> Candidate Configuration Matching`

The same target set must be usable to evaluate products across manufacturers.

## 11. Commerce Separation

Analytical Equipment Knowledge remains separate from affiliate commission, retailer economics, paid placement, advertising relationship, sponsorship, inventory economics, and promotional incentives. Commercial factors must not alter analytical equipment characteristics or candidate rank. Price may be used as a golfer-declared fitting constraint/value consideration through a governed rule; commission remains excluded from analytical ranking.

## 12. Locked Equipment Source Ingestion & Governance

GAL uses a governed staging pipeline:

`Source -> Raw Ingest -> Normalize -> Validate -> Resolve Conflicts -> Review -> Approve -> Promote -> Production Equipment Knowledge`

### Raw Source Preservation
Manufacturer feeds/documents, GAL test data, licensed partner data, manual research, and future approved APIs enter through a raw/source layer that preserves original source evidence and provenance. An ingested source record does not automatically become approved equipment knowledge.

### Normalization
Source-specific terminology/schemas are mapped into GAL's canonical product structure and ontology while preserving original source value/terminology.

### Validation
Validation may include identity checks, unit normalization, category/schema validation, compatibility checks, license eligibility, duplicate detection, range/type checks, provenance completeness, and conflict detection.

### Governance States
`INGESTED -> NORMALIZED -> VALIDATED -> REVIEW_PENDING -> APPROVED -> PRODUCTION`

Exception/lifecycle states include `CONFLICT`, `REJECTED`, `STALE`, and `RETIRED`.

### Production Promotion Gate
**No newly ingested equipment characteristic becomes eligible for AI Fitting merely because it exists in the database.** Only records satisfying validation, review, and promotion policy may enter golfer-facing production knowledge.

### Conflict Preservation
Competing observations are preserved rather than overwritten. Resolution is characteristic-specific and evidence-specific; a generic newest-record-wins rule is prohibited.

### Repeated Testing and Immutable Evidence
Individual GAL test runs and qualifying external observations remain immutable evidence. Repeated testing adds evidence. Derived/aggregate characteristics reference contributing evidence IDs, methodology version, aggregation policy, sample/configuration/environment context, and effective date.

### Research vs Production Boundary
Experimental/research evidence remains distinguishable from approved production equipment knowledge and cannot influence golfer-facing recommendations until it passes the applicable governance gate.

## 13. Locked Test, Sample, Configuration, and Observation Model

GAL represents equipment testing using:

`Product/Variant -> Physical Sample -> Tested Configuration -> Test Session -> Test Run/Observation -> Derived Equipment Characteristic`

### Physical Sample
Represents the actual equipment unit or lot GAL possessed, inspected, measured, or tested, preserving canonical identity, GAL sample ID, serial/lot when appropriate, acquisition/source/date, condition/prior use, measured physical properties, history/disposition, and provenance. A sample is evidence context, not a new product identity.

### Tested Configuration
Freezes the exact assembly/settings used to produce observations. A material fitting-relevant configuration change creates a distinct tested-configuration record rather than rewriting prior history.

### Test Session
Captures date/time, facility, tester/panel/robot, instrumentation, calibration, ball/consumable controls, environmental conditions, protocol/methodology version, and anomalies as applicable.

### Test Run / Observation
Preserves raw or minimally normalized qualifying observations. Raw observations are append-oriented/immutable after validation. Corrections use auditable correction/supersession records.

### Exclusions
Rejected/excluded observations remain auditable with exclusion reason, governing protocol/rule, and actor where appropriate.

### Derived and Aggregate Characteristics
Aggregates preserve contributing observations/tests, physical samples, tested configurations, methodology/aggregation version, context constraints, sample/run counts where material, effective date, and evidence/claim state.

### Scope-of-Generalization Rule
**GAL never attributes a measured result to an entire product family when the evidence was generated from only one specific sample/configuration unless an approved methodology explicitly supports that generalization.**

## 14. Locked Versioning and Product Lifecycle Model

GAL separates **stable product identity**, **commercial lifecycle**, and **knowledge version**.

### Stable Product Identity
A product family, variant, or component remains the same historical identity even after discontinuation. GAL does not create a new identity merely because availability or GAL knowledge changes.

### Commercial Lifecycle
Lifecycle is time-based metadata independent of product identity. Governed states may include:
- `ANNOUNCED`
- `CURRENT`
- `PRIOR_GENERATION`
- `DISCONTINUED`
- `HISTORICAL`

Availability is separate from lifecycle because a discontinued product may still be available new, used, or through secondary markets.

### Time-Bounded Published Specifications
Manufacturer changes to stock components, regional offerings, settings, or other published details are effective-dated rather than overwritten. Prior qualifying specifications remain reproducible and auditable.

### Versioned GAL Knowledge
GAL-derived characteristics carry methodology version, evidence references, and effective dates. When GAL methodology or evidence changes, a new derivation version is created rather than rewriting historical analytical results.

### Governing Rule
**Products are never rewritten to match the present. GAL preserves what the product was, what was known about it at the time, and how GAL's understanding evolved.**

This supports My Bag and longitudinal analysis of older equipment without forcing current-generation assumptions onto historical products.

## 15. Locked Rules-Based Configuration Engine

GAL uses a rules-based configuration engine between the canonical equipment catalog and AI Fitting:

`Components + Settings + Compatibility Rules + Build Constraints -> Valid GAL Configuration`

### Hard Compatibility Gates
Hard rules determine whether a configuration can legitimately exist. Examples include adapter/head compatibility, shaft-tip requirements, available loft/lie settings, supported playing-length ranges, iron/set availability, wedge loft/bounce/grind combinations, putter head/hosel combinations, and other category-specific constraints.

A candidate that fails a hard compatibility rule cannot enter AI Fitting as a valid recommendation.

### Configuration Support States
Valid/invalid configurations remain distinguishable as:
- `FACTORY_STANDARD` — officially offered stock configuration.
- `FACTORY_CUSTOM` — manufacturer-supported custom-order configuration.
- `AFTERMARKET_VALID` — technically valid configuration assembled outside the standard manufacturer catalog.
- `UNVERIFIED / INVALID` — compatibility has not been established or is known not to work.

Unknown compatibility is not treated as compatible.

### Manufacturer vs Aftermarket
GAL may recommend technically valid aftermarket configurations when supported by evidence and compatibility rules, but must not imply the manufacturer offers that exact build when it does not.

### Dependent-Effect Rules
Configuration variables may affect other equipment characteristics. Where defensible, GAL must represent dependencies such as adapter-setting effects on loft/lie/face orientation, shaft-length effects on swing weight and delivery, iron bending effects on bounce, or wedge loft changes on effective bounce. Configuration optimization must not silently improve one characteristic while degrading another.

### Structured / Whole-Bag Configurations
The rule engine must support category structures such as iron set composition, combo sets, wedge progression, wood/hybrid replacement architecture, and other multi-club structures where the fitting problem is not a single isolated club.

### Current-Equipment Optimization
Compatibility/configuration rules are a first-class foundation for `keep`, `adjust`, `reconfigure`, or `replace` recommendations. GAL may recommend optimizing a current club through a valid setting/component/configuration change instead of requiring replacement.

### Governing Rules
**GAL recommends only configurations whose compatibility is established. Unknown compatibility is not treated as compatible. Manufacturer-standard, manufacturer-custom, and valid aftermarket configurations remain distinguishable.**

**Configuration changes must carry their known dependent effects so GAL does not optimize one equipment characteristic while silently degrading another.**

## 16. Locked AI Fitting Eligibility and Equipment Knowledge Completeness

GAL evaluates equipment readiness against the specific use case rather than assigning a single generic completeness percentage.

### Governed Readiness States
- **`CATALOG_READY`** — identity and core published specifications are sufficiently complete for product display, search, and canonical resolution.
- **`GUIDE_READY`** — enough governed attributes exist for inclusion in the applicable GAL Buyers Guide.
- **`AI_FIT_LIMITED`** — GAL can evaluate the product against some target characteristics, but one or more important fitting attributes remain unavailable, conditional, stale, or insufficiently supported. Recommendation scope must be explicitly qualified.
- **`AI_FIT_READY`** — all category-specific attributes required for the applicable AI Fitting use case are available, governed, and eligible for analytical matching.

These states are use-case and category specific. A product may be Guide Ready while remaining AI Fit Limited.

### Attribute Criticality by Use Case
Each category/use case defines equipment attributes as:
- **Required** — absence blocks the applicable readiness state or fitting decision.
- **Conditionally Required** — required only when a particular golfer target, configuration path, or analytical claim depends on it.
- **Optional** — useful enrichment that does not block the applicable readiness state.

GAL must not use arbitrary percentage thresholds such as "80% complete" as the primary readiness rule. A single missing critical attribute may matter more than many completed optional fields.

### Category-Specific Readiness
Readiness requirements differ by category. For example, Driver AI Fitting may require validated product/configuration identity, loft/adjustability, compatibility rules, launch tendency, spin tendency, forgiveness/stability, and other governed performance characteristics. Directional tendency may be conditionally required when the golfer target includes directional correction. Exact CG coordinates may remain optional unless an approved methodology explicitly requires them.

Wedges, irons, putters, balls, fairway woods, and hybrids must define their own Required / Conditional / Optional attribute sets according to the shared AI Fitting framework.

### Limited-Evidence Behavior
Missing critical evidence narrows the recommendation rather than being filled with assumptions. GAL may present a candidate as a qualified or potential match only when the Evidence Ladder and readiness policy permit that wording.

A product with incomplete analytical evidence may therefore remain visible as **Potential Match — additional evidence needed** or an equivalent governed state rather than being falsely ranked as fully understood.

### Separation from Media and Commerce Completeness
Retail imagery, affiliate links, promotional metadata, commission data, and other commercial/display fields do not determine analytical AI Fitting readiness. Analytical readiness depends only on governed equipment knowledge required by the use case.

### Governing Rule
**Missing critical equipment evidence narrows or blocks the recommendation; it is never filled with assumptions.**

## 17. Locked Equipment Media Asset Governance

GAL maintains equipment imagery and media in a governed presentation layer separate from analytical Equipment Knowledge and commerce influence.

The canonical relationship is:

`Equipment Entity -> Media Asset -> Source / Rights -> Approved Uses -> Effective Period`

### Media Rights / Provenance States
Every production media asset must carry a governed rights/provenance state:
- **`GAL_OWNED`** — created or photographed by GAL under rights GAL controls.
- **`MANUFACTURER_AUTHORIZED`** — supplied or licensed by a manufacturer for the applicable use.
- **`PARTNER_LICENSED`** — supplied under a partner, retailer, photographer, agency, or other third-party license with explicit permitted scope.
- **`PUBLIC_REFERENCE_ONLY`** — usable for internal research/reference where lawful, but not approved for golfer-facing redistribution.
- **`UNVERIFIED_RIGHTS`** — rights are not sufficiently established; the asset cannot be used in golfer-facing production.

### Required Media Metadata
A governed media record should preserve, where applicable:
- equipment/product/variant/component/configuration or physical-sample linkage;
- asset type and role;
- source/provider;
- ownership/license status;
- source URL/document/reference where permitted;
- acquisition/import date;
- approved products/surfaces/use cases;
- attribution requirements;
- crop/transform/edit permissions;
- territory or channel restrictions;
- effective/expiration dates;
- reviewer/approval state;
- supersession/replacement relationship.

### Media Roles
GAL may maintain multiple media roles instead of one generic product image, including hero, thumbnail, address/topline, face, sole, crown, detail, shaft, grip, configuration-specific, comparison, test/sample, and other approved presentation roles.

### Physical-Sample Imagery
GAL test photography showing a specific physical sample or tested configuration must retain that sample/configuration linkage. It must not silently be represented as universal imagery of an entire product family when meaningful visible differences could mislead the golfer.

### Analytical Firewall
**An equipment record can be analytically complete without approved imagery, and approved imagery can never increase analytical confidence, evidence strength, readiness, or candidate rank.**

AI Fitting uses imagery only for presentation and explanation after analytical candidate evaluation. Media presence, quality, source relationship, advertising value, and visual appeal do not influence analytical ranking.

### Commerce Separation
Equipment Knowledge, Media Assets, and Commerce Assets remain separate concerns:

`Equipment Knowledge = analytical truth`

`Media Assets = governed presentation`

`Commerce Assets = downstream merchandising / transaction support`

A retailer or partner providing superior imagery does not receive analytical advantage.

### Governing Rule
**Only media with established rights for the intended use may appear in golfer-facing production. Media provenance and permitted-use scope must be auditable, and media has zero analytical influence.**

## 18. Locked Update Cadence and New-Model Onboarding

GAL uses a progressive, event-driven onboarding model so new equipment can become discoverable quickly without being treated as analytically complete before the evidence supports that conclusion.

The canonical progression is:

`Discovered -> Identity Verified -> CATALOG_READY -> GUIDE_READY -> AI_FIT_LIMITED -> AI_FIT_READY -> Monitored`

Readiness remains governed by the category/use-case rules in Section 16. Progression is not automatic merely because time has passed or a product is commercially important.

### Progressive Onboarding
A newly announced product may reach `CATALOG_READY` once GAL verifies canonical identity, relevant variants, qualifying published specifications, and source provenance. That state does not imply GAL knows the product's performance characteristics.

The product may advance to `GUIDE_READY`, `AI_FIT_LIMITED`, or `AI_FIT_READY` only as the required governed equipment knowledge becomes available for those use cases.

GAL may therefore publish verified facts about a new product before it has enough evidence to make a full AI Fitting recommendation.

### Event-Driven Re-Evaluation
The following events should trigger equipment-knowledge reevaluation where relevant:
- manufacturer product launch or revision;
- corrected identity or specification data;
- new variant, shaft, grip, adapter, grind, hosel, set composition, or other component/configuration option;
- new GAL test result;
- qualifying partner or independent evidence;
- methodology or aggregation revision;
- compatibility-rule change;
- source conflict or conflict resolution;
- commercial lifecycle change;
- material evidence correction or supersession.

Routine monitoring may supplement these events, but GAL does not rely only on calendar-based refreshes.

### Separate Freshness Concepts
GAL distinguishes:
- **Source freshness** — when the underlying source was last verified or observed.
- **Knowledge freshness** — whether the approved characteristic remains valid for the product/configuration and current approved methodology.
- **Coverage freshness** — whether GAL has evaluated the latest relevant variants, components, and configuration options.

Age alone does not make qualifying evidence stale. Historical test evidence remains valid within its original scope unless a material product, methodology, configuration, source, or context change affects its applicability.

### New-Model Onboarding Package
Each new product family/variant should accumulate a governed onboarding package containing, where applicable:
- canonical identity and aliases;
- category/product family linkage;
- variants;
- published specifications;
- components and factory-supported configurations;
- compatibility rules;
- lifecycle/release information;
- source provenance;
- media-rights status;
- Required / Conditionally Required / Optional attribute coverage;
- unresolved conflicts;
- current readiness by use case;
- testing/research/evidence gaps.

### Evidence Gap Queue
GAL maintains an explicit Evidence Gap Queue for information preventing a product from reaching a desired readiness state.

A gap should identify, where applicable:
- equipment entity/configuration;
- target use case/readiness state;
- missing or insufficient attribute;
- required evidence type or methodology;
- priority/materiality;
- source/research/test action needed;
- status and owner/workstream where operationally assigned.

The queue is an operational prioritization tool. It does not itself change analytical readiness.

### Launch-Day Governance
**A new-model launch does not reset GAL's evidence standards. New equipment progresses through the same readiness and evidence gates as existing equipment, regardless of market attention, manufacturer relationship, retailer pressure, or commercial importance.**

### Published Facts vs Performance Knowledge
**GAL may publish what is known immediately, but must clearly distinguish published specifications from GAL-measured, independent-observed, or GAL-derived performance knowledge.**

Manufacturer launch language remains subject to the marketing-separation rule and cannot substitute for qualifying performance evidence.

## 19. Current Locked Decisions

The following #4 architectural decisions are approved and locked:
1. Multi-source equipment evidence with preserved provenance.
2. Manufacturer data supports qualifying published specifications, not automatic performance claims.
3. GAL measured/tested evidence supports GAL-observed performance characteristics.
4. Independent/partner evidence may coexist when credible and permitted.
5. GAL-derived characteristics require traceable evidence and methodology versioning.
6. Canonical `Product Family -> Variant -> Component -> Configuration` structure.
7. GAL fits configurations rather than merely product names.
8. GAL owns the universal + category-specific equipment ontology.
9. Manufacturer terminology maps into GAL concepts and does not define them.
10. Four evidence classes: Published Specification, GAL Measured, Independent Observed, GAL Derived.
11. Three claim states: Known, Derived, Unknown / Insufficient Evidence.
12. A derived claim cannot exceed the strength of supporting evidence.
13. Unknown is preferable to fabricated or unsupported precision.
14. Analytical equipment knowledge is separated from commerce influence.
15. Governed staging/promotion pipeline controls production knowledge.
16. Raw/source evidence is preserved and does not automatically become production knowledge.
17. No new equipment characteristic is eligible for AI Fitting until it passes governance/promotion gates.
18. Conflicts are preserved and resolved with characteristic-specific rules; newest-record-wins is prohibited.
19. Individual test runs remain immutable; aggregate characteristics reference contributing evidence and methodology.
20. Research/experimental knowledge remains separated from golfer-facing production knowledge.
21. Testing uses `Product/Variant -> Physical Sample -> Tested Configuration -> Test Session -> Test Run/Observation -> Derived Equipment Characteristic`.
22. Physical samples preserve actual-unit history without becoming separate product identities.
23. Tested configurations freeze fitting-relevant assembly/settings.
24. Test sessions preserve instrumentation, protocol, environment, calibration, and tester/robot context.
25. Raw qualifying observations are append-oriented/immutable; exclusions remain auditable.
26. Aggregate characteristics preserve contributing evidence, methodology, context, and scope.
27. GAL does not generalize a sample/configuration to an entire product family without approved methodology.
28. Product identity, lifecycle, and knowledge version are independent.
29. Historical products/specifications remain preserved for My Bag and reproducibility.
30. Published specifications and GAL derivations use effective dating/versioning rather than overwrite.
31. Rules-based configuration validation sits between Equipment Knowledge and AI Fitting.
32. Hard compatibility failures exclude candidates.
33. Factory-standard, factory-custom, aftermarket-valid, and unverified/invalid configurations remain distinguishable.
34. Unknown compatibility is not compatible.
35. Configuration dependencies must be represented where defensible.
36. Keep/adjust/reconfigure/replace are peer analytical outcomes; replacement is not assumed.
37. Equipment readiness is evaluated by category and use case rather than one generic completeness percentage.
38. Readiness states are `CATALOG_READY`, `GUIDE_READY`, `AI_FIT_LIMITED`, and `AI_FIT_READY`.
39. Category attributes are classified as Required, Conditionally Required, or Optional for each use case.
40. Missing critical evidence narrows or blocks recommendation scope; GAL does not fill missing equipment knowledge with assumptions.
41. Media and commerce completeness do not determine analytical AI Fitting readiness.
42. Equipment media is governed separately from analytical Equipment Knowledge and commerce.
43. Media rights states are `GAL_OWNED`, `MANUFACTURER_AUTHORIZED`, `PARTNER_LICENSED`, `PUBLIC_REFERENCE_ONLY`, and `UNVERIFIED_RIGHTS`.
44. Only media with established rights for the intended use may appear in golfer-facing production.
45. GAL test/sample imagery preserves its physical-sample/configuration linkage where relevant.
46. Media cannot increase analytical confidence, evidence strength, readiness, or candidate rank.
47. Retailer/manufacturer/partner media quality or availability creates no analytical advantage.
48. New-model onboarding is progressive and event-driven rather than release-day full-trust or full-test-before-discovery.
49. Readiness progression is `Discovered -> Identity Verified -> CATALOG_READY -> GUIDE_READY -> AI_FIT_LIMITED -> AI_FIT_READY -> Monitored`.
50. Source freshness, Knowledge freshness, and Coverage freshness are independent concepts.
51. Age alone does not invalidate qualifying historical equipment evidence.
52. Material equipment/source/methodology/configuration events trigger readiness reevaluation.
53. New products maintain an explicit Evidence Gap Queue identifying what blocks higher readiness.
54. Market attention and commercial importance do not relax GAL evidence standards.
55. Launch-day published facts must remain distinguishable from measured, observed, or derived performance knowledge.

## 20. Design Status / Next Sections

The Equipment Knowledge Layer design is not yet complete. Remaining design topics should include:
- public Buyers Guide reuse;
- schema implications and Supabase gap analysis.

No production schema changes are authorized by this design document alone.
