# GAL Shared AI Fitting Framework

Status: USER-APPROVED ARCHITECTURAL DIRECTION / DESIGN SPEC FOR REVIEW
Date: 2026-09-03
Applies to: Driver, Fairway Woods, Hybrids, Irons, Wedges, Putter, Ball, My GAL, My Bag, Buyers Guides, Equipment Intelligence, Progress, and future Fit My Bag orchestration.

## 1. Architectural Decision

GAL will implement **one shared AI Fitting Core with category-specific fitting intelligence**.

GAL will not build seven disconnected fitters, and it will not force every category through identical fitting logic.

The shared architecture is:

`Golfer Profile + Connected/Measured Evidence + My Bag + Playing Environment + Equipment Knowledge`

`-> Identify Golfer Need`

`-> Determine Target Characteristics`

`-> Match Equipment Configurations`

`-> Explain Why`

`-> Compare / Test / Optimize / Buy`

`-> Measure Outcome`

`-> Longitudinal Learning`

The shared core owns common product, evidence, governance, editorial-integrity, and outcome rules. Category intelligence determines what inputs matter, what characteristics are fitted, how evidence is interpreted, and which outcomes define success for a specific equipment category.

## 2. Shared AI Fitting Core Responsibilities

The shared fitting core owns:

- Tell GAL Once / Connect It Once behavior;
- profile/evidence lookup and semantic reuse;
- provenance, source, measurement date, import date, freshness, and data-quality handling;
- missing/stale/context-specific input detection;
- golfer need formulation;
- target-characteristic representation;
- Characteristics Before Brands sequencing;
- candidate configuration matching/ranking framework;
- evidence-strength handling;
- Evidence Ladder enforcement;
- recommendation explainability;
- editorial-integrity and commerce separation;
- recommendation comparison framework;
- optimize-current-equipment path;
- action tracking;
- post-change outcome measurement;
- resolution/regression handling;
- longitudinal learning handoff;
- consistent authenticated UX contracts across categories;
- subscriber entitlement hooks without separate portal implementations.

## 3. Shared Fitting Contract

Each category fitter must provide a common contract to the shared core.

### Inputs
The category declares:
- required evidence domains;
- optional evidence domains;
- context-specific inputs;
- freshness requirements;
- minimum evidence for each type of conclusion;
- equipment attributes required from the Equipment Knowledge Layer.

### Need Model
The category declares the golfer problems/opportunities it can legitimately identify.

Examples include distance opportunity, directional dispersion, launch/spin mismatch, gapping issue, turf interaction problem, strike inconsistency, stopping-power need, speed-control issue, or whole-bag performance tradeoff.

### Target Characteristics
The category converts the identified golfer need into brand-neutral equipment characteristics and supported fitting ranges.

### Candidate Matching
The category determines how actual equipment configurations are evaluated against the target characteristics after the target is established.

### Explanation
The category supplies golfer-safe reasons showing how a configuration matches or fails the target.

### Outcomes
The category defines the post-change evidence needed to determine whether the fitting action helped.

## 4. Universal Fitting Flow

Every authenticated GAL AI Fitting experience follows the same conceptual sequence:

1. **What GAL Already Knows** — reuse valid profile, connected, My Bag, and environmental evidence.
2. **What GAL Still Needs** — ask only what is genuinely missing, stale, or context-specific.
3. **What GAL Sees** — describe supported golfer/equipment need or performance opportunity.
4. **What GAL Is Fitting For** — display brand-neutral target characteristics.
5. **Recommended Configurations** — introduce brands/models only after the target exists.
6. **Why This Fit** — show how each candidate maps to the target and what evidence supports the recommendation.
7. **Compare** — compare alternatives against the same target, not against arbitrary popularity rankings.
8. **What’s Next** — optimize current equipment, test, find a fitter, buy, save, or defer.
9. **Outcome Tracking** — collect/ingest qualifying post-change evidence.
10. **Progress** — show whether the targeted issue improved, remained, regressed, or remains unresolved.

Mobile implementations may split these into additional screens but may not reorder brands ahead of target characteristics.

## 5. Editorial Integrity

The mandatory sequence is:

`Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`

Never:

`Brand/Product -> Find reasons to recommend it -> Affiliate link`

Commercial factors such as affiliate commission, sponsorship, free equipment, retailer availability, advertising, or manufacturer relationships must not alter the target characteristics or analytical product ranking.

Commerce availability may be shown after analytical ranking as a separate action/availability dimension.

GAL must be able to recommend:
- keep current equipment;
- optimize current equipment;
- test before purchase;
- defer a purchase;
- replace equipment;
when each is the strongest supported path.

## 6. Evidence Ladder Integration

The shared core enforces the locked Evidence Ladder:

### Level 1 — Profile Fit
Profile + current equipment + Equipment Knowledge.

Permits configuration-review or compatibility conclusions, not quantified causal performance claims.

### Level 2 — Performance Opportunity
Adds qualifying observed/measured performance evidence.

Permits supported performance-opportunity conclusions and, where methodology allows, quantified modeled opportunity.

### Level 3 — Equipment Attribution
Requires stronger evidence linking the opportunity to equipment/configuration, preferably controlled comparative evidence or sufficiently strong multi-source evidence.

Permits stronger causal equipment claims when supported.

No category may bypass these levels with category-specific language.

## 7. Category Intelligence — Driver

### Core fitting question
What driver configuration best supports the golfer’s distance, launch, spin, strike, directional, forgiveness, and consistency needs?

### Important evidence
- club speed;
- ball speed;
- launch angle;
- spin rate;
- attack angle;
- face/path where available;
- strike location;
- carry/total distance;
- dispersion and miss tendency;
- current head/loft/settings;
- shaft/flex/weight/profile/length where known;
- golfer priorities;
- environment.

### Target-characteristic dimensions
- forgiveness/MOI need;
- launch tendency/window;
- spin tendency/window;
- bias/directional support;
- effective loft range;
- head adjustability needs;
- shaft profile/weight/flex range where supported;
- playing-length range;
- grip characteristics where relevant.

### Outcome examples
- carry/total distance;
- dispersion;
- fairway performance;
- launch/spin relationship;
- strike consistency;
- ball-speed efficiency;
- targeted miss reduction.

## 8. Category Intelligence — Fairway Woods

### Core fitting question
What fairway-wood role and configuration best fits the golfer’s tee, turf, launch, gapping, forgiveness, and stopping needs?

### Important evidence
- current bag gaps;
- use from tee vs turf;
- club/ball speed where available;
- launch/carry;
- strike consistency;
- turf interaction;
- typical lies;
- ability to elevate the ball;
- preferred trajectory;
- miss pattern;
- intended role.

### Target-characteristic dimensions
- loft/gapping role;
- launch/ease of elevation;
- head size/forgiveness;
- turf-friendly sole characteristics;
- spin/stopping profile;
- bias;
- shaft/length characteristics where supported;
- tee-versus-turf role.

### Outcome examples
- carry gap consistency;
- launch success from turf;
- dispersion;
- stopping ability;
- strike quality;
- useful-shot percentage by intended role.

## 9. Category Intelligence — Hybrids

### Core fitting question
What hybrid or iron-replacement configuration best solves long-club gaps while preserving launch, stopping power, forgiveness, and playable miss patterns?

### Important evidence
- long-iron/wood gaps;
- typical lie/rough use;
- launch/carry;
- strike pattern;
- miss tendency;
- ability to hold greens;
- golfer preference for hybrid vs iron-like look/flight;
- intended role.

### Target-characteristic dimensions
- loft/gapping role;
- launch/ease;
- stopping profile;
- head/sole forgiveness;
- directional bias;
- iron-like vs wood-like behavior;
- shaft/length characteristics where supported.

### Outcome examples
- gap consistency;
- green-holding performance;
- dispersion;
- rough/turf success;
- strike consistency;
- confidence/useful-shot rate for intended role.

## 10. Category Intelligence — Irons

### Core fitting question
What iron set architecture and configuration best fits the golfer’s launch, carry gaps, dispersion, strike, forgiveness, turf interaction, and shot-making priorities?

### Important evidence
- height;
- wrist-to-floor;
- hand/grip measurements where relevant;
- 7-iron speed/carry and broader iron distances;
- launch/spin where available;
- strike location and fat/thin/toe/heel patterns;
- directional dispersion;
- turf/divot characteristics where supported;
- handicap/context/goals;
- current set makeup;
- transition points to hybrids/woods;
- playing environment.

### Target-characteristic dimensions
- set architecture/composition;
- head category/forgiveness;
- launch window;
- spin/stopping profile;
- length range;
- lie-angle range where evidence supports it;
- shaft weight/profile/flex range where supported;
- sole/turf characteristics;
- grip sizing;
- long-iron replacement boundary.

### Outcome examples
- carry-gap consistency;
- front/back and left/right dispersion;
- strike consistency;
- green-holding performance;
- targeted miss improvement;
- useful launch/stopping;
- transition-gap quality to hybrids/woods and wedges.

## 11. Category Intelligence — Wedges

### Core fitting question
What wedge loft, bounce, grind/sole, and configuration best supports the golfer’s gapping, delivery, turf/sand conditions, and typical short-game shots?

### Important evidence
- iron-set ending loft/carry;
- current wedge lofts/carries;
- full vs partial-shot use;
- delivery/attack characteristics where available;
- turf firmness;
- sand conditions;
- common short-game shots;
- face-opening tendency;
- miss pattern;
- bunker technique/context.

### Target-characteristic dimensions
- loft matrix/gapping;
- bounce range;
- grind/sole characteristics;
- leading-edge/turf interaction needs;
- full-shot vs finesse role;
- shaft/length/lie/grip characteristics where supported.

### Outcome examples
- carry-gap consistency;
- proximity/dispersion by shot type;
- turf interaction;
- bunker success;
- strike consistency;
- launch/spin/stopping behavior;
- useful-shot coverage across wedge roles.

## 12. Category Intelligence — Putter

### Core fitting question
What putter configuration best supports aim, face delivery, strike consistency, speed control, setup, and stroke characteristics?

### Important evidence
- handedness;
- eye/setup context where validated;
- stroke path/face rotation where measured;
- impact location;
- start-line consistency;
- speed control;
- typical miss;
- green speeds/conditions;
- current putter length/lie/head/hosel;
- golfer feel/alignment preferences.

### Target-characteristic dimensions
- head shape/stability;
- hosel/toe-hang/face-balance characteristics where supported;
- alignment system;
- length;
- lie;
- loft where supported;
- grip characteristics;
- head weight/swing feel where supported.

### Outcome examples
- start-line consistency;
- face/impact consistency;
- speed-control dispersion;
- make percentage by distance where data quality permits;
- three-putt/lag performance where contextually useful;
- targeted miss reduction.

Putter fitting must not reuse driver/iron evidence logic mechanically. Its instrumentation and evidence model are category-specific.

## 13. Category Intelligence — Ball

### Core fitting question
What golf-ball performance profile best supports the golfer across the entire bag, balancing driver flight, iron flight/stopping, wedge/greenside performance, feel, durability, and cost priorities?

### Important evidence
- driver speed/launch/spin;
- iron launch/spin/carry;
- wedge/greenside performance where measured;
- preferred feel;
- trajectory preference;
- environmental conditions;
- current ball;
- durability/cost priorities;
- golfer skill/context;
- whole-bag performance tradeoffs.

### Target-characteristic dimensions
- compression/performance relationship;
- construction;
- cover type;
- driver spin/flight tendency;
- iron flight/spin/stopping tendency;
- greenside spin/feel;
- durability;
- price/value.

### Outcome examples
- driver flight/dispersion;
- iron stopping behavior;
- wedge/greenside control;
- feel preference satisfaction;
- durability/value;
- whole-bag performance consistency.

Ball fitting is inherently cross-bag and should not optimize one club at the expense of the golfer’s overall performance without explicitly showing the tradeoff.

## 14. Shared Target-Characteristic Model

The system should represent target characteristics as structured, explainable fitting requirements rather than free-form AI prose.

Each target characteristic should support:
- category;
- characteristic identifier;
- desired value/range/class;
- importance/priority;
- golfer-safe rationale;
- supporting evidence references;
- evidence level;
- uncertainty or evidence-strength state;
- freshness/context requirements;
- whether the characteristic is hard constraint, strong preference, or exploratory fitting window.

This structure allows multiple candidate products to be evaluated against the same target without changing the target after a brand is known.

## 15. Candidate Configuration Matching

Candidate ranking must evaluate **configurations**, not only model names.

A candidate can include category-appropriate components/settings such as:
- model/head;
- loft;
- settings;
- shaft/component;
- flex/weight/profile;
- length;
- lie;
- grip;
- set composition;
- wedge grind/bounce;
- putter hosel/head/alignment;
- ball model/profile.

The matching engine should produce separate analytical fit information from commercial metadata.

Conceptually:

`Analytical Fit = match(candidate characteristics, golfer target characteristics, evidence context)`

Commercial data such as price, retailer, inventory, affiliate eligibility, promotion, or commission is attached only after analytical fit has been computed.

## 16. Comparison Contract

All candidates shown in a comparison must be compared against the same target-characteristic set.

The comparison should answer:
- where each candidate strongly matches;
- where each is acceptable;
- where each has tradeoffs;
- where evidence is insufficient;
- why one may rank ahead of another;
- whether the current club remains competitive.

Popularity, review score, sponsor status, or commission cannot substitute for target match.

## 17. Optimize Current Equipment

Before replacement, the category fitter must consider whether an adjustment to current equipment could reasonably address the identified need when the category and known equipment support adjustment.

Examples:
- driver loft/hosel setting or length test;
- fairway/hybrid setting or role change;
- iron lie/length/grip/set-composition change;
- wedge gapping or configuration change;
- putter setup/length/lie/grip change;
- ball change without replacing clubs.

GAL may recommend a lower-revenue action when it is the stronger supported golfer outcome.

## 18. Fitting Evidence Strength

Until a governed numeric confidence methodology exists, use explainable qualitative evidence states rather than fabricated percentages.

Potential shared vocabulary:
- Limited;
- Developing;
- Strong.

The state must reflect category-specific evidence requirements, not a universal simple count of completed fields.

The UI should show what would materially improve the fitting evidence.

## 19. Fit My Bag — Future Orchestration Layer

GAL should support a future **Fit My Bag** orchestration layer above individual category fitters.

Fit My Bag does not replace category fitting. It determines whole-bag priorities and interactions.

The orchestration model should evaluate:
- bag composition;
- distance gaps;
- overlapping roles;
- missing roles;
- category-level evidence-backed opportunities;
- cross-category tradeoffs;
- golfer goals;
- value/economic context where governed;
- urgency/materiality.

Potential output:

`Next Equipment Priority -> Why It Matters -> Recommended Category Fit -> Outcome Follow-up`

Example: wedges may rank ahead of driver if the evidence suggests the wedge gap/short-game issue is more material even when a smaller driver opportunity exists.

## 20. Cross-Category Rules

Category fitters must not optimize locally in ways that create obvious whole-bag conflicts without surfacing the tradeoff.

Examples:
- Driver optimization should consider the top-end bag role where relevant.
- Fairway woods/hybrids/long irons must share gapping context.
- Iron set architecture must consider hybrid/wood transition and wedge transition.
- Wedge fitting begins from the actual iron-set endpoint.
- Ball fitting evaluates whole-bag effects by design.

A category recommendation may still proceed when other-category data is missing, but the system must qualify the uncertainty when that missing context could materially affect the recommendation.

## 21. Public Buyers Guides vs Authenticated AI Fitting

Public Buyers Guides remain lightweight educational/discovery experiences and may collect limited answers.

Authenticated AI Fitting:
- consumes the shared Golfer Profile/Evidence Layer;
- consumes My Bag;
- consumes connected data;
- uses the shared fitting core;
- uses category intelligence;
- applies the Evidence Ladder;
- uses target characteristics before brands;
- tracks actions/outcomes longitudinally.

Public and authenticated products should share the same governed Equipment Knowledge Layer to avoid conflicting product truth.

## 22. Subscriber Architecture

Registered and subscriber users should use the same fitting components and data contracts. Entitlements are additive.

Potential future subscriber differentiation may include:
- deeper evidence analysis;
- advanced comparisons;
- longer fitting history;
- outcome analytics;
- expanded connected-data integrations;
- Fit My Bag orchestration;
- advanced valuation/economic optimization;
- premium testing/fitter workflows.

Final entitlement decisions remain a separate business/product decision.

## 23. Error and Partial-Data Behavior

The shared framework must support:
- no profile data;
- partial profile data;
- stale measurements;
- disconnected source;
- contradictory observations;
- unsupported equipment configuration;
- insufficient evidence for performance claim;
- no meaningful opportunity detected;
- no candidate meeting all target characteristics;
- commercial data unavailable;
- recommendation exists but outcome evidence is not yet sufficient.

When evidence is insufficient, GAL should degrade gracefully to a weaker supported conclusion rather than invent certainty.

## 24. Testing Requirements

Implementation must validate at minimum:
- characteristics are computed before candidate brands/models are ranked;
- commercial metadata cannot alter analytical rank;
- known semantically compatible data is reused instead of re-asked;
- stale/context-incompatible values are not silently reused;
- category-specific evidence requirements are enforced;
- Evidence Ladder prevents stronger claims than evidence permits;
- current-equipment optimization can outrank replacement;
- comparisons use a fixed shared target for all candidates;
- outcome logic uses qualifying pre/post evidence;
- category fitters cannot write conflicting golfer profile truth;
- cross-category shared inputs remain consistent;
- RLS/security prevents cross-user fitting data access;
- no service-role secrets are exposed browser-side.

## 25. Initial Implementation Scope

The first production category is **Driver**.

The shared framework should be designed so Driver proves the common contracts without prematurely implementing all seven category models.

Initial build should establish:
- shared fitting-session contract;
- shared evidence lookup/reuse;
- shared target-characteristic structure;
- shared candidate-match/explanation contract;
- Driver category adapter/intelligence;
- current-driver optimization path;
- action/outcome hooks;
- mobile/desktop UI contracts already approved.

Other categories should be added through the category contract rather than by copying Driver implementation.

## 26. Explicit Non-Goals for First Driver Release

Do not require for initial Driver release:
- complete Fit My Bag orchestration;
- production ML trained on large GAL longitudinal cohorts;
- numeric fitting-confidence score;
- fully automated commercial inventory across all retailers;
- every launch-monitor/API integration;
- autonomous causal attribution beyond governed evidence;
- implementation of all category fitters.

The architecture must support these future capabilities without pretending they exist at launch.

## 27. Acceptance Criteria

This design is satisfied when:

1. GAL has one shared fitting architecture rather than separate questionnaire applications.
2. Driver is implemented as the first category adapter/intelligence model.
3. Every fitting visibly follows Characteristics Before Brands.
4. Commerce is downstream of analytical fit.
5. The same profile/evidence is reused across categories through Tell GAL Once / Connect It Once.
6. Evidence Ladder rules are enforced across all category experiences.
7. Each category can define its own evidence, targets, matching logic, and outcomes without breaking the shared core.
8. Current-equipment optimization is a first-class outcome.
9. Post-change results feed the longitudinal outcome system.
10. Future Fit My Bag can orchestrate category priorities without replacing category-specific fitting models.

## 28. Product Principle

**One golfer. One evidence foundation. One GAL fitting system. Category-specific intelligence. Characteristics before brands. Outcomes over transactions.**
