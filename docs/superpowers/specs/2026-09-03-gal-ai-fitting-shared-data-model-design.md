# GAL AI Fitting Shared Data Model

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: Golfer Profile, GAL Evidence Layer, My Bag, AI Fitting, Equipment Intelligence, Recommendations, Outcomes, Progress, and future longitudinal learning.

## Architectural Decision

GAL will use a **hybrid normalized, evidence-first data model**.

GAL will not use one giant profile table as the system of record for all golfer-fitting data, and it will not create disconnected category-specific data silos. GAL will also not adopt full event sourcing for launch.

The model combines:
- stable golfer/profile entities;
- stable equipment and bag entities;
- append-oriented evidence observations;
- derived/reproducible profile values;
- persistent fitting sessions and snapshots;
- frozen target characteristics;
- candidate configurations and analytical matches;
- recommendations and golfer actions;
- post-change outcomes and longitudinal status.

## Governing Principle

**Raw evidence is preserved. Derived values are products of that evidence, not replacements for it.**

When sources disagree, GAL retains the observations and resolves context-specific values through governed selection/derivation logic rather than destructively overwriting one source with another.

## Top-Level Entity Groups

### Golfer Identity / Profile
Stores relatively stable golfer attributes and preferences such as:
- golfer identity key;
- handedness;
- age band/context where product-approved;
- presentation preference where provided;
- physical measurements and profile context where appropriate;
- goals and priorities;
- home/default playing environment;
- profile presentation settings.

Profile fields that originate as measured, observed, self-reported, imported, or inferred values should remain traceable to evidence records.

### Evidence Observation
Represents a meaningful golfer/game/performance/environment observation.

Minimum conceptual fields:
- evidence_id;
- golfer_id;
- metric/domain identifier;
- semantic context;
- category/equipment context when relevant;
- value;
- unit;
- source_type;
- source_provider;
- source_reference where permitted;
- quality/provenance state;
- observed_at/measured_at;
- imported_at;
- session/environment reference when relevant;
- freshness policy/state;
- golfer correction/override state;
- supersession/correction relationship if needed;
- privacy/consent applicability where required.

Representative quality states may include Measured/Verified, Observed, Self-Reported, Inferred, and Missing, subject to governed definitions.

### Derived Profile Value
Represents a context-specific value GAL selects or derives from underlying evidence for a particular use.

It should reference:
- golfer;
- metric/domain;
- semantic context;
- chosen/derived value;
- unit;
- supporting evidence IDs;
- derivation policy/version;
- effective date/freshness;
- confidence/evidence-strength state where governed.

Derived values must be reproducible when the same evidence and policy version are available.

### My Bag
The bag model distinguishes equipment products from the golfer's owned/played equipment instances.

Conceptual structure:
`golfer -> bag -> equipment_instance -> equipment_model/component/configuration`

An equipment instance may include:
- category;
- model/head;
- loft/effective loft;
- adjustable settings;
- shaft/component;
- flex;
- weight/profile;
- playing length;
- lie where relevant;
- grip;
- set composition;
- wedge bounce/grind;
- putter configuration;
- ball model;
- acquisition/in-play dates where useful;
- status such as current/retired/tested;
- provenance for each known configuration attribute.

Unknown specifications remain unknown and must not be fabricated.

## Fitting Session Model

A fitting is a persistent analytical event, not merely a transient screen flow.

Conceptual chain:
`fitting_session -> fitting_input_snapshot -> golfer_need -> target_characteristic -> candidate_configuration -> candidate_match -> recommendation -> golfer_action -> outcome_measurement -> resolution/regression`

### Fitting Session
Includes:
- fitting_session_id;
- golfer_id;
- equipment category;
- initiated_at/completed_at;
- fitting purpose/context;
- current equipment instance reference when relevant;
- methodology/policy version;
- status;
- entitlement/context metadata as needed.

### Fitting Input Snapshot
Captures the exact evidence and derived values used by the fitting at the time it was run.

This allows later audit/reproduction even if the golfer profile changes afterward.

The snapshot should reference:
- evidence IDs;
- derived profile value IDs;
- My Bag equipment/configuration IDs;
- playing environment/context;
- equipment-knowledge version/reference;
- fitting-engine/methodology version.

### Golfer Need
Represents the supported golfer/equipment problem or opportunity identified by the fitting.

Examples include:
- distance opportunity;
- launch/spin mismatch;
- directional dispersion;
- gapping issue;
- strike inconsistency;
- turf interaction need;
- stopping-power need;
- speed-control issue.

Each need should include:
- need identifier/type;
- golfer-safe explanation;
- supporting evidence references;
- applicable Evidence Ladder level;
- materiality/severity state when governed;
- uncertainty/evidence-strength state.

### Target Characteristic
Target characteristics are structured, brand-neutral requirements produced before candidate products are evaluated.

Minimum fields:
- category;
- characteristic identifier;
- desired value/range/class;
- importance/priority;
- constraint type: hard constraint / strong preference / exploratory window;
- golfer-safe rationale;
- supporting evidence IDs;
- Evidence Ladder level;
- evidence-strength/uncertainty state;
- freshness/context requirements;
- creation timestamp;
- frozen target-set/version reference.

## Editorial Integrity Auditability

The target-characteristic set must be **frozen before brand/model candidate ranking begins**.

The persisted model must make it possible to demonstrate the sequence:
`Golfer Evidence -> Golfer Need -> Target Characteristics -> Candidate Matching -> Brands/Models -> Commerce`

The system must not silently mutate target characteristics after learning which brand/model has stronger commercial economics.

Any legitimate re-fit must create a new target-set version or fitting session rather than rewriting history.

## Equipment Knowledge Layer Separation

Analytical equipment data and commerce data are separate domains.

### Analytical Equipment Knowledge
Contains product/component/configuration attributes needed to determine fit.

Examples:
- model/head identity;
- category;
- available lofts/settings;
- forgiveness/MOI-related characteristics where sourced;
- launch/spin tendencies where evidence-backed;
- bias/directional characteristics;
- shaft/component characteristics;
- dimensions/configuration options;
- set composition;
- sole/bounce/grind;
- putter head/hosel/alignment characteristics;
- ball construction/cover/performance profile;
- provenance;
- effective/freshness dates;
- source/version.

### Commerce Metadata
Contains:
- retailer;
- price;
- inventory/availability;
- affiliate eligibility;
- affiliate destination;
- promotion;
- commercial relationship metadata.

Commerce metadata must not be an input to analytical fit ranking.

The analytical ranking function should not need access to commission values.

## Candidate Configuration

A candidate is a concrete category-appropriate configuration, not merely a model name.

It may include:
- head/model;
- loft;
- setting;
- shaft/component;
- flex;
- weight/profile;
- length;
- lie;
- grip;
- iron set composition;
- wedge loft/bounce/grind;
- putter head/hosel/alignment;
- ball model/profile.

Each candidate should reference the equipment-knowledge records supporting its characteristics.

## Candidate Match

Each candidate is evaluated against the frozen target-characteristic set.

A candidate match should preserve:
- candidate ID;
- target-set ID;
- per-characteristic match result;
- tradeoffs;
- unknown/insufficient-data states;
- supporting equipment-knowledge references;
- analytical rank or tier where governed;
- explanation artifacts;
- fitting-engine/methodology version.

Candidate ranking must be reproducible from the same target set, candidate knowledge, and methodology version.

## Recommendation

A recommendation is the golfer-facing analytical conclusion from a fitting session.

Recommendation types may include:
- keep current equipment;
- optimize current equipment;
- test configuration;
- find a fitter;
- replace with recommended configuration;
- defer action pending better evidence.

Recommendation records should reference:
- fitting session;
- golfer need;
- target set;
- selected candidate/current-equipment action;
- evidence strength;
- golfer-safe rationale;
- created_at;
- methodology version;
- status.

## Golfer Action

Tracks what the golfer actually did after a recommendation.

Examples:
- adjusted current club;
- tested configuration;
- booked fitter;
- purchased equipment;
- saved recommendation;
- declined/deferred;
- changed to another configuration.

Actions should be distinguishable from recommendations so GAL does not infer a change occurred merely because it was recommended.

## Outcome Measurement

Post-change observations remain evidence records and may be grouped into outcome evaluations.

Outcome evaluation should reference:
- action/change;
- pre-change baseline evidence/snapshot;
- qualifying post-change evidence;
- outcome metric;
- before/after or modeled comparison where permitted;
- measurement window;
- methodology version;
- evidence strength;
- golfer-safe interpretation.

## Resolution / Regression

Outcome evaluations feed the existing longitudinal state model and may produce governed states such as resolved, evidence pending, ineffective, or regressed.

Status changes must reference the evidence and outcome evaluation that justified them.

## Append-Only Evidence and Corrections

Raw imported/measured/observed evidence should be append-oriented.

Corrections should generally be represented as:
- correction/override records;
- supersession links;
- validity state changes;
- source revocation/consent effects;
rather than silently editing historical observations.

This protects auditability and longitudinal analysis.

## Source Conflicts

Conflicting observations must be preserved.

Context-specific selection rules determine which observation/derived value is appropriate for a fitting question.

Examples:
- launch monitor may be preferred for launch/spin/delivery;
- on-course tracking may be preferred for actual playing distance/dispersion;
- authoritative handicap source may be preferred for Handicap Index;
- golfer estimate may remain useful when no measured value exists.

No universal source priority applies to all metrics.

## Methodology Versioning

Every material derived product should reference the method/model/rules version used to create it.

This applies to:
- derived profile values;
- identified golfer needs;
- target characteristics;
- candidate match/rank;
- recommendations;
- modeled opportunities;
- outcome evaluations;
- future aggregate-learning predictions.

This allows GAL to improve methodology without rewriting historical decisions.

## Security / RLS Boundary

Golfer-readable profile, My Bag, fitting results, recommendations, and appropriate outcome data remain protected by golfer-scoped RLS and authenticated read contracts.

Sensitive analytical mutation, governance, aggregate learning, internal evaluation, and service-only derivation remain behind trusted server/Edge Function/service paths.

The browser must not receive service-role credentials or generic privileged RPC access.

Production and staging evidence remain environment-isolated. Production golfer data must not be copied to development/staging except under approved anonymization/sanitization policy.

## Privacy / Consent

Evidence imported from connected sources must remain attributable to the connection/consent context that authorized collection.

Disconnecting a source stops future synchronization. Retention/deletion/revocation effects on already-imported evidence must follow the broader privacy/retention policy.

Consent withdrawal may invalidate evidence, downstream aggregates, or learning candidates under existing longitudinal-governance rules.

## Reproducibility Requirement

For any material GAL fitting recommendation, the system should ultimately be able to answer:
- which golfer evidence was used;
- which My Bag configuration was assumed;
- which environment/context was used;
- which equipment-knowledge records were used;
- which methodology version ran;
- what target characteristics were frozen;
- which candidates were evaluated;
- why the selected recommendation ranked as it did;
- what action occurred afterward;
- whether qualifying outcome evidence showed improvement.

## Data Model Success Criteria

The shared model succeeds when:
- Tell GAL Once can be enforced across products;
- conflicting evidence is preserved rather than overwritten;
- target characteristics can be proven to precede brand ranking;
- commerce cannot silently influence analytical ranking;
- fittings are reproducible/auditable;
- My Bag reflects actual golfer-owned configurations;
- recommendations and golfer actions are distinct;
- before/after outcomes are attributable;
- longitudinal learning can be built without destroying source history;
- category fitters share one core contract without losing category-specific semantics.

## Decision

The hybrid normalized, evidence-first model described here is the locked GAL data architecture direction for AI Fitting and related Golfer Profile / My Bag / Equipment Intelligence workflows. Implementation details and concrete Supabase migrations require a separate schema-gap review and implementation plan before production changes.