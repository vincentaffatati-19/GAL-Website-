# GAL Equipment Knowledge Governance & AI-Fitting Eligibility

Status: APPROVED / LOCKED — EXTENSION TO EQUIPMENT KNOWLEDGE LAYER
Date: 2026-09-03
Applies to: GAL Equipment Knowledge Layer, AI Fitting, Buyers Guides, Equipment Testing, My Bag, Comparisons, and production data promotion.

## 1. Source Ingestion & Governance

GAL uses a controlled equipment-evidence pipeline:

`Source -> Raw Observation -> Normalize -> Validate -> Review -> Promote -> Derive -> Publish to AI Fitting`

No manufacturer feed, retailer feed, spreadsheet, scrape, partner import, or GAL lab result may write directly into production fitting characteristics without passing through governed normalization and promotion.

### Raw Observation
Preserves what the source actually said or measured, including source provider/type, source reference, retrieved/imported time, effective/model year, original value/text, units where present, sample/configuration context, and rights/licensing metadata where required.

### Normalized Observation
Maps source data into GAL's owned ontology and standard units while preserving the raw observation and provenance. Normalization does not automatically make a claim analytically trusted.

### Promoted Knowledge
Only reviewed/validated knowledge in ACTIVE status may feed production AI Fitting.

Approved lifecycle states:
`INGESTED -> NORMALIZED -> VALIDATED -> APPROVED -> ACTIVE`

Exception states:
`REJECTED | SUPERSEDED | QUARANTINED | NEEDS_REVIEW`

### Source-Specific Trust Policy
- Manufacturer/authoritative documentation may directly support factual published specifications and officially offered configurations.
- Manufacturer performance/marketing claims are retained as source claims but do not automatically become GAL analytical truth.
- GAL Lab may support measured GAL observations when the sample, method, environment, instrumentation, and methodology version are preserved.
- Licensed/credible partner evidence may contribute according to source quality and usage rights.
- Retailer data is primarily suitable for SKU identity, availability, pricing, and commerce metadata; retailer marketing copy does not establish analytical performance characteristics.
- Community/user observations may inform future aggregate evidence, but individual anecdotes do not become product characteristics by themselves.

### Conflicts
Conflicting source observations are preserved, not overwritten. A governed GAL derivation may resolve or qualify the conflict only through a versioned method with traceable supporting evidence. If evidence remains inadequate, the characteristic stays Unknown / Insufficient Evidence.

### Versioning
Material equipment knowledge is temporally/versioned. Corrections create new knowledge versions or supersession relationships rather than silently rewriting historical fitting inputs. Historical fittings must remain reproducible against the equipment-knowledge version used at the time.

### Automated Validation
The ingestion pipeline should flag at minimum:
- impossible/out-of-range values;
- missing or incompatible units;
- duplicate product identities;
- model-year/variant conflicts;
- incompatible component combinations;
- suspiciously large changes from prior versions;
- missing provenance;
- stale source material;
- marketing language represented as measurement;
- unsupported derived claims;
- orphan variants/components;
- insufficient fitting attributes.

Human review should focus primarily on exceptions and material analytical claims rather than routine factual imports.

### Governing Editorial Rule
**GAL distinguishes a source's claim from GAL's conclusion. Manufacturer and retailer marketing statements may be preserved as evidence, but they do not become GAL analytical characteristics unless independently supported or produced through a governed GAL derivation.**

## 2. Equipment Knowledge Completeness & AI-Fitting Eligibility

A product/configuration does not become recommendation-eligible merely because GAL knows its identity, price, or a small number of published specifications.

GAL uses three governed eligibility levels.

### Catalog Eligible
May appear in public guides/reference/catalog experiences when minimum identity and factual-specification requirements are satisfied.

Typical requirements:
- verified product identity;
- equipment category;
- variant/model-year/lifecycle status where relevant;
- minimum core published specifications;
- source provenance.

### Comparison Eligible
May participate in analytical side-by-side comparisons when enough normalized category-relevant attributes exist to support a meaningful comparison.

### AI Fitting Eligible
May enter a personalized AI Fitting candidate pool only when the configuration has sufficient evidence for the target characteristics relevant to that fitting.

Eligibility is **characteristic-specific, not merely product-specific**.

Conceptually:
`product/configuration x target characteristic x evidence sufficiency x freshness x claim state -> fitting eligibility`

A configuration may be eligible for one fitting problem but ineligible for another if a material target characteristic is insufficiently supported.

### Unknown Handling
Unknowns do not all behave the same way:
- Non-material unknown: candidate may remain with the limitation disclosed.
- Material unknown: candidate cannot be ranked for the affected fitting target.
- Critical unknown: candidate is excluded from the recommendation pool.

### Hard Exclusion Conditions
A candidate is excluded when any applicable critical condition exists, including:
- unresolved product/variant identity conflict;
- materially stale critical specification;
- missing required compatibility information;
- unsupported marketing language standing in for a required analytical characteristic;
- known data-quality defect;
- unverified/non-buildable configuration;
- critical target characteristic lacking sufficient evidence.

### Category-Specific Minimum Evidence Profiles
Driver, woods, hybrids, irons, wedges, putters, and balls have distinct minimum evidence profiles because their fitting problems and target characteristics differ. GAL must not force one universal checklist onto all categories.

### Governing Principle
**GAL only recommends equipment when it has enough evidence to support the specific characteristics that matter for that golfer. Missing data is surfaced as uncertainty, never filled with assumption.**

## 3. Relationship to Characteristics Before Brands

Eligibility is evaluated only after the golfer's target-characteristic set has been established and frozen. The analytical flow remains:

`Golfer Evidence -> Golfer Need -> Frozen Target Characteristics -> Eligible Candidate Configurations -> Analytical Matching/Ranking -> Brands/Models -> Commerce`

Commerce metadata and affiliate economics are not inputs to eligibility or analytical ranking.

## 4. Implementation Boundary

This document locks the governance and eligibility architecture only. It does not authorize production schema changes. Concrete tables, constraints, functions, validation jobs, ingestion tools, and Supabase migrations require a later schema-gap analysis and implementation plan.