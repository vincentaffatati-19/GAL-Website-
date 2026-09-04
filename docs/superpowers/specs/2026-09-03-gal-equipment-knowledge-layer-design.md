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
Lifecycle is time-based metadata independent of product identity. Governed states may include `ANNOUNCED`, `CURRENT`, `PRIOR_GENERATION`, `DISCONTINUED`, and `HISTORICAL`. Availability is separate from lifecycle because a discontinued product may still be available new, used, or through secondary markets.

### Time-Bounded Published Specifications
Manufacturer changes to stock components, regional offerings, settings, or other published details are effective-dated rather than overwritten. Prior qualifying specifications remain reproducible and auditable.

### Versioned GAL Knowledge
GAL-derived characteristics carry methodology version, evidence references, and effective dates. When GAL methodology or evidence changes, a new derivation version is created rather than rewriting historical analytical results.

### Governing Rule
**Products are never rewritten to match the present. GAL preserves what the product was, what was known about it at the time, and how GAL's understanding evolved.**

## 15. Locked Rules-Based Configuration Engine

GAL uses a rules-based configuration engine:

`Components + Settings + Compatibility Rules + Build Constraints -> Valid GAL Configuration`

Hard compatibility failures exclude candidates. Configuration support states are `FACTORY_STANDARD`, `FACTORY_CUSTOM`, `AFTERMARKET_VALID`, and `UNVERIFIED / INVALID`. Unknown compatibility is not treated as compatible. Configuration dependencies must be represented where defensible, and GAL may recommend `keep`, `adjust`, `reconfigure`, or `replace` as peer analytical outcomes rather than assuming replacement.

## 16. Locked AI Fitting Eligibility and Equipment Knowledge Completeness

GAL evaluates equipment readiness against the specific use case rather than assigning a single generic completeness percentage.

Readiness states are `CATALOG_READY`, `GUIDE_READY`, `AI_FIT_LIMITED`, and `AI_FIT_READY`. Each category/use case defines attributes as Required, Conditionally Required, or Optional. Missing critical evidence narrows or blocks the recommendation; it is never filled with assumptions. Media and commerce completeness do not determine analytical AI Fitting readiness.

## 17. Locked Equipment Media Asset Governance

GAL maintains equipment imagery and media in a governed presentation layer separate from analytical Equipment Knowledge and commerce influence:

`Equipment Entity -> Media Asset -> Source / Rights -> Approved Uses -> Effective Period`

Media-rights states are `GAL_OWNED`, `MANUFACTURER_AUTHORIZED`, `PARTNER_LICENSED`, `PUBLIC_REFERENCE_ONLY`, and `UNVERIFIED_RIGHTS`. Only media with established rights for the intended use may appear in golfer-facing production. GAL test/sample imagery preserves physical-sample/configuration linkage where relevant. Media cannot increase analytical confidence, evidence strength, readiness, or candidate rank.

## 18. Locked Update Cadence and New-Model Onboarding

GAL uses a progressive, event-driven onboarding model:

`Discovered -> Identity Verified -> CATALOG_READY -> GUIDE_READY -> AI_FIT_LIMITED -> AI_FIT_READY -> Monitored`

Progression is governed by evidence and use-case readiness, not by time, market attention, or commercial importance. Relevant product, source, configuration, testing, lifecycle, conflict, and methodology events trigger reevaluation.

GAL separately tracks Source freshness, Knowledge freshness, and Coverage freshness. Age alone does not invalidate qualifying historical evidence.

Each new-model onboarding package preserves canonical identity, variants, published specifications, components/configurations, compatibility rules, lifecycle/release information, provenance, media-rights status, attribute coverage, unresolved conflicts, readiness, and testing/research gaps.

GAL maintains an explicit Evidence Gap Queue for missing or insufficient knowledge blocking a desired readiness state. A new-model launch does not reset GAL's evidence standards, and published facts must remain distinguishable from measured, observed, or derived performance knowledge.

## 19. Locked Public Buyers Guide Reuse of the Equipment Knowledge Layer

GAL uses one governed Equipment Knowledge Layer for both public Buyers Guides and authenticated GAL AI Fitting. Buyers Guides and AI Fitting consume different approved views of the same canonical equipment truth rather than maintaining separate product-truth databases.

The canonical relationship is:

`GAL Equipment Knowledge Layer -> Public Buyers Guide View -> Authenticated AI Fitting View`

### One Equipment Truth
Canonical equipment identity, published specifications, GAL ontology, evidence provenance, lifecycle, configuration rules, readiness state, media governance, and approved analytical characteristics are shared. A specification or analytical characteristic is not copied into an independent Buyers Guide database merely to support a public experience.

The same governed equipment fact must therefore resolve consistently in Buyers Guides, My Bag, comparisons, and AI Fitting unless the surface intentionally presents a different approved level of detail.

### Public Buyers Guide Eligibility
Normal analytical inclusion in a public Buyers Guide requires the applicable equipment entity/configuration to satisfy at least `GUIDE_READY` for that category/use case.

A public guide may use approved characteristics such as construction, forgiveness/stability class, launch/spin tendency, role, configuration availability, price/value classification where governed, and qualifying GAL-tested findings. Manufacturer marketing claims remain subject to GAL's evidence and marketing-separation rules.

### Different Product Experience, Not Different Equipment Facts
Public Buyers Guides are lightweight discovery and education products. They may collect temporary/self-reported golfer answers and use those answers to generate a useful shortlist, but the public experience does not imply the depth of evidence available to an authenticated persistent GAL Profile and AI Fitting workflow.

A Buyers Guide result is therefore a **guide recommendation / shortlist**, not automatically a full GAL AI Fit.

### Tell GAL Once Continuity
When a golfer authenticates, semantically compatible Buyers Guide answers may become golfer evidence with preserved provenance, source surface, time, and self-reported status. Those answers can be reused by the Golfer Profile and AI Fitting rather than asking the golfer for the same valid information again.

Conceptually:

`Public Guide -> Useful Shortlist -> Build My GAL Fit -> Sign In/Register -> Reuse Compatible Guide Answers -> Add Profile/Connected Evidence -> Ask Only Missing Inputs -> Target Characteristics -> Full AI Fitting`

Reused values remain editable and subject to the same freshness, semantic-compatibility, and evidence-quality rules as other golfer evidence.

### Why Recommendations May Differ
A public Buyers Guide and authenticated AI Fitting may legitimately produce different recommendations because AI Fitting has more golfer-specific evidence, contextual evidence, My Bag information, measured/connected performance, or configuration detail.

They must not differ because the two products maintain contradictory equipment facts.

**The public Buyers Guide and GAL AI Fitting may differ in recommendation because AI Fitting knows more about the golfer—not because they use different equipment facts.**

### Commerce Separation
Commerce remains downstream in both experiences. Retailer availability, affiliate eligibility, commission, paid placement, sponsorship, or inventory may determine which transaction options can be shown after analytical selection, but cannot change the underlying equipment characteristic, guide analytical rank, or AI Fitting analytical rank.

### Governing Rule
**There is one governed Equipment Knowledge Layer. Buyers Guides and AI Fitting consume different approved views of that same truth; neither maintains an independent product-truth database.**

## 20. Current Locked Decisions

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
43. Only media with established rights for the intended use may appear in golfer-facing production.
44. Media cannot increase analytical confidence, evidence strength, readiness, or candidate rank.
45. New-model onboarding is progressive and event-driven.
46. Source freshness, Knowledge freshness, and Coverage freshness are independent concepts.
47. Evidence Gap Queue identifies what blocks higher equipment readiness.
48. Market attention and commercial importance do not relax evidence standards.
49. Launch-day published facts remain distinguishable from performance knowledge.
50. Public Buyers Guides and authenticated AI Fitting use one governed Equipment Knowledge Layer.
51. `GUIDE_READY` is the normal minimum analytical readiness for public Buyers Guide inclusion.
52. Buyers Guides provide lightweight recommendations/shortlists and do not imply full authenticated AI Fitting evidence depth.
53. Semantically compatible Buyers Guide answers may flow into authenticated golfer evidence under Tell GAL Once with provenance and freshness preserved.
54. Public Guide and AI Fitting recommendations may differ because AI Fitting knows more about the golfer, not because equipment facts differ.
55. Buyers Guides do not maintain an independent product-truth database.
56. Commerce remains downstream and cannot alter analytical guide or AI Fitting rank.

## 21. Design Status / Next Section

The Equipment Knowledge Layer architecture is now complete through the product/evidence/governance, test representation, lifecycle/versioning, configuration validation, readiness, media governance, new-model onboarding, and Buyers Guide reuse layers.

The remaining architectural activity is:
- schema implications and Supabase gap analysis against the existing GAL staging/production data model;
- identification of what already exists, what can be reused, what requires extension, and what should remain outside the operational database;
- a proposed migration boundary and implementation sequence.

No production schema changes are authorized by this design document alone. The schema-gap review must be completed and separately approved before implementation planning or database migration work begins.
