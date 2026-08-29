# GAL Golfer Intelligence Data Model v1.1 — Design Specification

**Status:** Design approved in sections; consolidated for final user review  
**Design date:** 2026-08-28  
**Consolidated:** 2026-08-29  
**Target branch:** `feature/golfer-intelligence-v1`  
**Schema family:** `GI-1.1`  
**Implementation status:** Not started. This document authorizes planning only after final user approval.

## 0. Executive Design Contract

GAL will extend its existing Supabase data backbone into a longitudinal Golfer Intelligence platform without replacing the existing canonical user, bag, event, catalog, decision-snapshot, valuation, consent, or intelligence-state tables.

The core architecture is **current state + append-only history + deterministic scoring + explainable AI**.

The governing platform rule is:

> **Algorithms decide. AI interprets, converses and teaches.**

The governing data rule is:

> **Current truth is convenient. History is permanent. Provenance explains why.**

The governing learning rule is:

> **Ask once. Remember it. Reuse it. Ask again only when the answer is missing, stale, uncertain, conflicting, or materially important.**

The governing business/privacy rule is:

> **Golfer data exists first to serve the golfer. Commercial intelligence is a governed secondary use of permitted, de-identified aggregates—not a resale of individual profiles.**

The governing implementation rule is:

> **Extend what already works. Add only what is missing. Preserve compatibility first.**

The governing release rule is:

> **Nothing advances because it merely exists. It advances because it works, is secure, is reproducible, and has been verified against the complete GAL experience.**

---

# 1. Core Architecture

## 1.1 Decision

GAL will **extend the existing schema additively** rather than create a parallel v2 golfer platform.

Existing current-state/source-of-truth tables remain authoritative:

- `gal_users`
- `gal_profile_facts`
- `gal_intelligence_state`
- `gal_bags`
- `gal_bag_items`
- `gal_buyer_events`
- `gal_decision_snapshots`
- `gal_valuation_snapshots`
- `gal_consent_records`
- `gal_catalog_products`

New companion entities provide governance, history, inference, questions, bag scenarios, scoring, recommendations, model/version traceability, connected services, and milestone snapshots.

## 1.2 Current-state + history pattern

`gal_profile_facts` is the fast current best-known value for each canonical golfer fact. Historical values are written to `gal_profile_fact_history` and are never silently rewritten.

`gal_intelligence_state` is a **rebuildable computed cache**, not source-of-truth history.

`gal_bags` + `gal_bag_items` remain the authoritative current equipment state. Current ownership is not duplicated as golfer facts.

`gal_buyer_events` remains the canonical behavior-event table. A second generic behavior-event table is prohibited.

## 1.3 Rejected alternatives

- **Snapshot-only profile history:** rejected because it makes field-level change history, source authority, and targeted recomputation difficult.
- **Pure event sourcing:** rejected for GI-1.1 because it adds operational complexity beyond current GAL needs.
- **Parallel “v2” tables:** rejected because they would fragment identity, bag, event, recommendation, and privacy semantics.

## 1.4 Universal provenance model

A governed golfer fact must be capable of carrying:

- `user_id`
- `fact_key`
- value + value state
- unit where relevant
- source type
- source detail
- confidence
- golfer confirmation
- captured/observed/effective timestamps
- staleness/refresh information
- model version where derived
- question version where collected
- privacy classification
- commercial classification

---

# 2. Canonical Golfer Fact Taxonomy

## 2.1 Fact Catalog

Create `gal_fact_catalog` as the semantic authority for reusable golfer facts.

Purpose:

- `gal_profile_facts` answers **what GAL currently knows**.
- `gal_fact_catalog` answers **what that fact means and how it may be used**.

No production feature, Buyer’s Guide, AI process, or dashboard may create a golfer fact key unless that key first exists in the Fact Catalog.

## 2.2 Canonical key style

Use hierarchical keys, for example:

- `golfer.display_name`
- `physical.height`
- `experience.years_playing`
- `game.handicap_index`
- `game.typical_score`
- `swing.driver.speed_mph`
- `swing.driver.carry_yards`
- `swing.iron_7.carry_yards`
- `swing.driver.shot_shape`
- `swing.driver.typical_miss`
- `preference.performance.forgiveness`
- `preference.appearance.irons`
- `preference.value.price_sensitivity`
- `goal.primary_game_goal`
- `goal.equipment_priority`
- `environment.primary_region`
- `behavior.brand_consideration`

Tool-specific duplicates such as `seven_iron_distance`, `7i_carry`, and `iron_distance_7` are prohibited.

## 2.3 Profile domains

The canonical golfer taxonomy is organized into eight primary domains:

1. Physical
2. Experience
3. Game
4. Swing
5. Preferences
6. Value
7. Environment
8. Goals

Equipment ownership remains in the bag model rather than becoming a ninth fact domain.

## 2.4 Fact source classes

The system preserves the distinction between:

- `DECLARED`
- `MEASURED`
- `OBSERVED`
- `INFERRED`
- `IMPORTED`
- `SYSTEM`

A confirmed inference remains an inference by provenance. Confirmation does not rewrite its origin as declared or measured.

## 2.5 Refresh classes

Facts may use:

- stable
- seasonal
- dynamic
- event-driven

A stale important fact should trigger a targeted confirmation rather than a full questionnaire reset.

## 2.6 Unknown-state semantics

The data model distinguishes:

- known
- unknown
- not answered
- not applicable
- inferred only

`NULL` alone is not sufficient to represent these meanings.

## 2.7 Initial high-value golfer information

Initial onboarding/profile learning should focus on approximately 10–15 high-value interactions including:

- age or age band where appropriate
- gender optional
- height
- handedness
- years playing
- rounds per year
- instruction/lesson status
- handicap or typical score
- driver speed or distance proxy
- 7-iron carry
- shot shape
- typical miss
- performance priority
- primary golf goal
- progressive current-equipment capture

## 2.8 Privacy/commercial classifications

Examples:

- **Aggregate eligible:** handicap band, speed band, typical miss, equipment preference, purchase intention.
- **Restricted aggregate:** age band, gender, only in sufficiently large cohorts.
- **Personal only:** display name, individual dashboard context.
- **Excluded:** sensitive physical/health accommodations and equivalent sensitive free text.

---

# 3. Fact History + Inference Provenance

## 3.1 Permanent history

Create `gal_profile_fact_history` as append-only longitudinal history.

Each historical fact captures at minimum:

- user
- canonical fact key
- scope
- prior value/value state
- source type/detail
- confidence
- golfer confirmation
- model/question version when relevant
- effective range
- observation time
- supersession reason
- created time

## 3.2 Change workflow

When a material current fact changes:

1. preserve the previous current state in history;
2. update the current row in `gal_profile_facts`;
3. determine which intelligence domains/recommendations are affected;
4. recompute only affected derived intelligence;
5. explain material downstream consequences when useful.

Recommended supersession reasons include:

- golfer update
- measurement update
- correction
- model recalculation
- normal variation
- equipment change
- swing change
- seasonal refresh
- source upgrade

## 3.3 Source authority

General source authority starts from:

1. verified measurement
2. golfer-confirmed value
3. golfer-reported estimate
4. GAL inference
5. behavioral observation

This is **not** a rigid newest-wins hierarchy. Current truth should consider:

`Source Quality × Confidence × Recency × Golfer Confirmation × Context Match`

Exact weights are deterministic and versioned later.

## 3.4 Inferences

Create `gal_inferences` with immutable provenance including:

- inference key/value
- confidence
- status
- model ID/version
- evidence snapshot
- explanation
- timestamps for creation, confirmation, rejection, supersession, expiration

Statuses:

- candidate
- active
- confirmed
- rejected
- superseded
- expired

Confidence bands for UI interpretation may be:

- 0.90–1.00 Very High
- 0.75–0.89 High
- 0.55–0.74 Moderate
- 0.35–0.54 Low
- below 0.35 Insufficient

Confidence never converts inference into truth by itself.

## 3.5 Conflict rules

1. Never silently overwrite historical golfer intelligence.
2. Declared, measured, observed, imported, and inferred origins remain distinguishable forever.
3. Newer does not automatically mean better.
4. Golfer correction supersedes GAL interpretation about that golfer.
5. Material contradictions trigger targeted clarification.
6. Low-confidence inference never masquerades as known information.
7. Every material recommendation must be reproducible from stored profile/model/data snapshots.

## 3.6 Profile snapshots

Create immutable `gal_profile_snapshots` for recommendation-time and milestone state.

A recommendation audit chain must be able to trace:

- profile snapshot
- declared/measured/imported facts
- inferences
- bag snapshot
- equipment dataset version
- Buyer’s Guide/model version
- Fit Engine version
- AI explanation version

---

# 4. Question + Learning Engine

## 4.1 Questions are governed data

Buyer’s Guides and onboarding must not independently hardcode the meaning of golfer questions.

Create:

- `gal_question_catalog`
- `gal_question_responses`

Question wording may evolve while semantic `question_key`, version, and fact mapping remain durable.

## 4.2 Question Catalog contract

Each question can define:

- stable question key/version
- active/retired status
- golfer-facing wording
- help text
- “why GAL asks” explanation
- response type + validation
- primary/secondary fact mappings
- category/domain
- required level
- skip/unknown behavior
- proxy group
- refresh class
- confidence rule
- deterministic branching rule
- visual asset key
- output type
- commercial classification

## 4.3 Response history

Question responses are durable historical evidence. Corrections create newer responses; prior responses are not deleted or silently rewritten.

Each response preserves:

- exact question/version shown
- user
- structured response
- response state
- source context
- session
- related recommendation run if any
- resulting fact link where applicable
- confidence contribution
- timestamps

## 4.4 Resolution states

Before asking, the Question Engine evaluates the associated fact as:

- missing
- known current
- known stale
- known low confidence
- unknown declared
- inference available
- conflicting
- not applicable

Expected behavior:

- known current → skip
- stale → confirm/refresh
- low confidence → ask higher-quality question if material
- unknown → use proxy where appropriate
- inference available → show/confirm when useful
- conflicting → targeted clarification
- not applicable → suppress

## 4.5 “I don’t know” is valid

“I don’t know” must be a first-class response, not an error condition.

Example driver-speed proxy path:

1. measured/known swing speed
2. driver carry
3. driver total distance
4. 7-iron carry
5. 150-yard club
6. weaker secondary evidence only when justified

Each proxy produces different confidence.

## 4.6 Expected information value

Question priority should conceptually use:

`Recommendation Impact × Current Uncertainty × Answer Reliability ÷ Golfer Effort`

The system should stop asking when additional precision is unlikely to materially improve the task.

## 4.7 Critical/helpful/enrichment

Workflows classify information as:

- **Critical:** material to recommendation quality.
- **Helpful:** improves ranking but is not necessary.
- **Enrichment:** useful longitudinally but should not interrupt the task.

## 4.8 Cross-guide reuse

The same canonical fact is reused across all compatible GAL experiences.

If the bag already knows the current driver, the Driver Guide does not ask “What driver do you play?” again.

## 4.9 AI role

AI may:

- make transitions conversational;
- explain why questions matter;
- interpret free-form responses;
- choose among **allowed** next-question paths;
- summarize what GAL learned.

AI may not invent new fact semantics, validation rules, confidence rules, or ungoverned question mappings.

---

# 5. Jerry’s Bag, Bag History + What-If Scenarios

## 5.1 Authoritative current bag

Retain:

- `gal_bags`
- `gal_bag_items`
- `gal_valuation_snapshots`
- `gal_decision_snapshots`
- `gal_catalog_products`

A golfer may have multiple real bags, but the existing one-active-bag constraint remains the default/current bag rule.

## 5.2 Bag lifecycle

Add longitudinal equipment history via `gal_bag_item_history` rather than deleting/replacing old ownership state.

History distinguishes:

- added
- replaced
- reconfigured
- removed
- sold
- lost
- retired
- unknown disposition

Product identity and configuration remain separate. A shaft/loft change can be a configuration event without changing the canonical head/product.

## 5.3 Partial identification

Unknown exact product identity is valid.

`canonical_product_id` may remain null while category, brand, club type, and display snapshot are stored.

GAL must never invent a precise product identity simply to complete a bag.

## 5.4 Bag snapshots

Create immutable `gal_bag_snapshots` so historical recommendations can be reproduced after the golfer changes equipment.

## 5.5 GAL Optimization Score

The whole-bag score is distinct from individual product Fit Score.

Initial components:

- Personal Fit
- Gapping
- Bag Structure
- Confidence
- Value

Equipment age is not automatically a negative-fit factor.

Gapping analysis distinguishes observed, declared, estimated, and unknown carry data; confidence must be visible when estimates dominate.

Value means economic sensibility relative to fit, condition, usefulness, alternatives, and replacement cost—not simply low price.

## 5.6 Try It in My Bag

Create:

- `gal_bag_scenarios`
- `gal_bag_scenario_items`

A scenario can add/remove/replace/reconfigure equipment without modifying the actual bag.

Scenario and current bag comparisons must use the same:

- golfer snapshot
- equipment data version
- Fit Engine version
- Bag Optimization version
- comparable market/pricing context where practical

Projected improvements are labeled as projections, not guaranteed measured outcomes.

## 5.7 Scenario adoption

Adoption follows a governed lifecycle:

scenario → golfer confirmation → close prior item history → activate new configuration/item → create bag snapshot → recalculate bag score → record event.

Affiliate click or reported purchase does not automatically equal bag ownership.

## 5.8 Trust rule

GAL must be able to recommend:

- keep what you have;
- optimize what you own;
- investigate/test;
- replace.

Perpetual upgrade pressure is prohibited.

---

# 6. Recommendation Runs, Fit Score + Auditability

## 6.1 Recommendation Run

Create `gal_recommendation_runs` as a first-class execution object for guide, fitter, scenario, and bag-review recommendation work.

Every completed run freezes or references:

- user
- run type/category
- profile snapshot
- bag snapshot
- optional scenario
- normalized inputs
- market/currency
- equipment-data version
- Fit Engine version
- category/guide model version
- Bag Optimization version where relevant
- Question Engine version
- AI explanation version
- timestamps/status

## 6.2 Candidate evaluation

Create:

- `gal_recommendation_items`
- `gal_fit_score_components`

Each finalist/meaningful exclusion can preserve:

- product/configuration
- eligibility/exclusion
- Fit Score
- rank
- confidence
- component scores
- strengths
- tradeoffs
- current-equipment delta
- relevant price/availability snapshot

## 6.3 Fit Score

GAL Fit Score answers:

> How well does this product/configuration fit this golfer for this category?

It is not universal product quality.

User-facing scores may use 0–100, while underlying components and model versions remain stored.

## 6.4 Determinism

Given the same:

- profile snapshot
- bag snapshot
- normalized inputs
- product dataset version
- Fit Engine version
- category model version

GAL must produce the same deterministic scores/ranking.

LLM provider, temperature, wording, or explanation changes must not change ranking.

## 6.5 Model Registry

Create `gal_model_registry` for fit, inference, optimization, question, explanation, and privacy model families.

Production model versions are immutable and linked to Git source commit/release governance.

## 6.6 Fit vs confidence

Fit Score and recommendation confidence are separate.

A high Fit Score can coexist with moderate confidence when golfer or product configuration data is incomplete.

## 6.7 Current-equipment comparison

Recommendation output should compare against current equipment where possible.

A small score increase does not automatically justify replacement.

Separate `upgrade_value` incorporates fit improvement, whole-bag improvement, golfer goal relevance, confidence, cost burden, and switching risk.

## 6.8 Keep/reconfigure as valid results

`KEEP_CURRENT` and `KEEP + RECONFIGURE` are valid successful outcomes.

## 6.9 Commerce boundary

Recommendation ranking is completed **before** commerce routing.

GAL payout, affiliate network, commission rate, and retailer priority are prohibited Fit Engine inputs.

Golfer-relevant price/value constraints are legitimate inputs.

## 6.10 Structured explanations

Strengths/tradeoffs are structured before AI renders prose.

AI can explain supported evidence only. It cannot fabricate performance claims that are absent from governed product facts, measurements, or model outputs.

## 6.11 Existing decision snapshots

`gal_decision_snapshots` remains useful as the immutable golfer-facing decision snapshot and should link to the normalized recommendation audit chain rather than be replaced.

---

# 7. Behavior Events + Longitudinal Intelligence

## 7.1 Canonical event foundation

Retain `gal_buyer_events` as the event anchor.

Create `gal_event_catalog` to govern event semantics.

Recommended naming style:

`domain.object.action`

Examples:

- `guide.started`
- `guide.question.answered`
- `recommendation.viewed`
- `recommendation.saved`
- `product.viewed`
- `product.compared`
- `bag.item.added`
- `scenario.created`
- `commerce.route.clicked`

## 7.2 Behavior is evidence, not truth

A product view does not create a brand preference fact.

Behavior becomes profile intelligence only through a governed inference model with evidence, confidence, and model version.

## 7.3 Event classes

Useful classes include:

- navigation
- engagement
- intent
- commitment
- outcome

Signal strength is contextual and should consider frequency, recency, duration, diversity, sequence, and context.

## 7.4 Sessions and journeys

Add `session_id`; support optional `journey_id` for multi-session equipment-decision journeys.

Where relevant, events link to recommendation run, bag, decision snapshot, canonical product/brand, source tool, and source tool version.

## 7.5 Event immutability

Material events are append-only. Incorrect events are invalidated with reason rather than rewritten into different history.

Store both `occurred_at` and ingestion/creation time.

## 7.6 Intelligence state

`gal_intelligence_state` may summarize current brand affinities, replacement readiness, decision patterns, and other computed signals, but source evidence remains in durable event/fact/bag/recommendation records.

## 7.7 Data minimization

Do not store meaningless micro-events such as cursor movement or trivial hover data unless a defined product/analytical purpose exists.

## 7.8 Longitudinal outcome focus

Outcome signals such as adopted club, kept/returned club, and satisfaction are more important long-term validation signals than affiliate clicks.

---

# 8. Privacy, Consent + Commercial Data Boundary

## 8.1 Four logical data layers

1. **Operational golfer data** — individual/pseudonymous records used to operate GAL.
2. **Equipment intelligence** — product-centered catalog/specification/provenance/commerce data.
3. **Analytics/derived intelligence** — internal governed cohorts/trends.
4. **Commercial intelligence** — approved aggregate outputs for subscribers/customers.

The customer portal consumes Layer 4, not Layer 1.

## 8.2 Hard technical boundary

Industry/customer systems must never receive direct permissions to raw golfer operational tables such as:

- `gal_profile_facts`
- `gal_buyer_events`
- `gal_intelligence_state`
- raw recommendation history
- individual bags

Pseudonymous user IDs are still personal data and are not customer-facing anonymous records.

## 8.3 Privacy classes

Recommended:

- public
- operational
- personal
- sensitive
- restricted
- aggregate only

Commercial-use classes remain separate:

- personal only
- aggregate eligible
- restricted aggregate
- excluded from commercial use

## 8.4 Consent ledger

Retain `gal_consent_records` as authoritative append-only consent history.

Consent types should evolve beyond the existing baseline toward:

- terms of service
- privacy policy
- personalization
- product analytics
- commercial aggregate analytics
- marketing email
- research participation
- data import

Consent records are version-specific and retain source/interface/jurisdiction where appropriate.

**Physical-policy requirement:** the live baseline currently allows authenticated golfers `ALL` operations on their own `gal_consent_records` rows. GI-1.1 must tighten this so consent history is not arbitrarily mutable. Normal golfer access should be limited to reading own consent history and appending a new consent/withdrawal decision through a governed path. Normal user `UPDATE` and `DELETE` of prior consent records must be denied. Legal/privacy administration may use a separate controlled privileged workflow where required.

## 8.5 Consent lineage

Derived intelligence inherits restrictions from the underlying evidence. Transformation does not erase upstream consent/provider restrictions.

## 8.6 Sensitive information

Voluntarily supplied physical/health accommodations may support individual fitting but are classified sensitive and excluded from commercial analytics.

Age/gender are restricted-aggregate dimensions and should normally be banded and used only with adequate cohort protections.

Precise location should not be collected when coarse region/state/climate market is sufficient.

## 8.7 Cohort protection

Initial governed commercial privacy floor:

- baseline minimum cohort approximately **50 golfers**;
- larger thresholds for more granular dimension combinations.

Commercial analytics must support small-cell and complementary suppression and limit arbitrary slicing that increases re-identification risk.

## 8.8 Separate analytics/commercial layers

Long-term database architecture should separate operational, internal analytics, and commercial outputs. Customer-facing services query only final approved commercial views/services, never intermediate small-cohort tables.

## 8.9 Export/deletion readiness

Design for user export and governed deletion/anonymization workflows across profile, bag, questions, inferences, recommendations, behavior, consent, and derived state.

Privacy deletion is distinct from normal profile edits.

## 8.10 Development data

Development/preview environments use synthetic/test data. Staging uses synthetic or explicitly sanitized data. Unsanitized production golfer data is not copied into normal non-production environments.

## 8.11 Connected apps + external sources

Connected services are a first-class extension to Section 8.

Create:

- `gal_external_source_catalog`
- `gal_data_connections`
- `gal_data_sync_runs`

Potential categories include:

- handicap services
- official golf-association handicap systems
- launch monitors
- shot tracking
- GPS/course management
- fitting platforms
- approved equipment/purchase sources

### Connected-app rules

1. Explicit golfer authorization is required.
2. GAL does not store another service’s user password.
3. Use OAuth/delegated authorization where available.
4. Request minimum necessary scopes.
5. Imported values map through canonical GAL fact/event semantics.
6. Imported data retains provider, timestamps, integration/mapping version, and provenance.
7. Provider authority is data-type specific.
8. A disconnected provider stops future synchronization and credentials are invalidated/removed.
9. Imported data is not automatically commercially eligible.
10. Both golfer consent and provider contractual/API restrictions must allow a use.
11. A read connection does not authorize GAL to send the golfer’s broader GAL profile back to the provider.
12. GAL remains provider-neutral through adapters.

### Example handicap flow

connected provider → authorized API → adapter → validation/normalization → canonical `game.handicap_index` → current-truth resolver → fact/history provenance.

A current verified external handicap may outrank an older self-reported handicap while both remain in history.

### Connected data and questions

A current connected handicap suppresses the repeated “What is your handicap?” question. Current launch-monitor data may similarly eliminate proxies and raise confidence.

---

# 9. Model Registry, Versioning + Release Governance

## 9.1 Independent version families

A website release is not the same as a Fit Engine, schema, question, dataset, or explanation version.

Examples of separate version families:

- `GI-*` — Golfer Intelligence schema
- `FACT-*` — Fact Catalog
- `QUESTION-*` — Question Engine
- `FIT-*` — shared Fit Engine
- category fit models such as Driver/Iron/Wedge/Putter
- `BAG-OPT-*` — Bag Optimization
- `INFER-*` — inference models
- `EXPLAIN-*` — AI explanation contract
- `PRIVACY-AGG-*` — privacy/cohort logic
- equipment master/release datasets

## 9.2 Immutable released versions

Once a model/version reaches production, its semantics are immutable. Output-affecting changes require a new version.

Historical recommendation runs always retain the original versions used.

## 9.3 Database migrations

Schema identity `GI-1.1` is separate from individual migration files.

Migration code lives in Git under the repository’s Supabase migration structure. Production schema changes are not undocumented dashboard-only edits.

Preferred evolution is additive expand → migrate → verify → contract later.

## 9.4 Branch/release flow

Existing governed branch flow remains:

`feature/* → develop → release/* → protected main`

GI development branch:

`feature/golfer-intelligence-v1`

## 9.5 Immutable release candidates

Every RC maps to one exact source commit and exact component versions. Any material change creates a new RC.

## 9.6 Release manifest

Every RC/production release should identify:

- release version/RC
- source commit
- schema/migration versions
- Fact Catalog version
- Question Engine version
- Fit Engine/category model versions
- Bag Optimization version
- equipment data versions
- privacy model/version
- AI explanation version
- brand version

## 9.7 Regression expectations

Use synthetic “golden” golfer personas to detect scoring drift, wrong-handed equipment leakage, price-cap failures, missing-data crashes, and commerce influence.

Database tests cover RLS, constraints, history immutability, snapshot integrity, and cross-user denial.

## 9.8 Guide regression gate

Every production Buyer’s Guide must pass before promotion.

Fairway Woods & Hybrids receives explicit regression testing because previous release candidates experienced hanging/failure behavior.

## 9.9 Portal synchronization

Changes to shared product/data/personalization contracts affecting both golfer and industry/customer experiences are updated and verified together.

This does not require identical UI deployments, but shared canonical contracts must remain compatible.

## 9.10 Rollback/roll-forward

Every production release requires a known recovery strategy. Code/model/data releases may be rolled back; database schema may require a corrective roll-forward migration when reverse migration is unsafe.

---

# 10. Golfer Intelligence State + Personalization Orchestration

## 10.1 Existing state table

Retain and extend `gal_intelligence_state`.

It is the computed current personalization layer and remains client read-only.

It summarizes, but does not replace:

- profile facts/history
- inferences
- question responses
- current bag/history
- recommendation history
- behavior
- consent
- connected-source state

## 10.2 State contract

Recommended domains include:

- identity context
- physical
- experience
- game
- swing
- preferences
- value
- environment
- goals
- bag
- behavior
- inferences
- recommendations
- learning
- connections
- data quality
- privacy

Add explicit `state_schema_version` separate from `engine_version`.

## 10.3 Current-truth resolver

All GAL surfaces consume one governed current-truth resolution service/state rather than independently deciding which source “wins.”

Applications should receive value plus provenance summary including source type, confidence, freshness, and golfer confirmation where relevant.

## 10.4 Personalization Orchestrator

The orchestrator determines **what GAL should do next**, not which product scores highest.

Potential structured actions:

- ask question
- confirm fact
- update bag
- show existing recommendation
- refresh recommendation
- try product in bag
- review gapping
- connect service
- keep current
- no action

The initial orchestrator should be deterministic/rule-driven where practical.

## 10.5 Insight handling

Create `gal_insights` for material, persistent personalization insights.

Insight lifecycle may include:

- new
- shown
- acknowledged
- acted on
- dismissed
- resolved
- expired

Equivalent insights from multiple subsystems should be deduplicated into one golfer-facing insight.

## 10.6 State recomputation

Material events trigger targeted domain recomputation. Low-value events should not force global rebuilds.

The state should support health/status such as healthy, stale, partial, rebuilding, error and a `state_generation_id` for traceability.

## 10.7 AI context package

AI receives a purpose-specific minimum context package, not an uncontrolled dump of the golfer record.

Context preserves whether information is declared, measured/imported, observed, or inferred so AI can say “you told us,” “your connected source shows,” or “we estimate” accurately.

Consent/privacy filtering happens **before** data enters AI context.

## 10.8 Cross-device continuity

Registered-user truth is server-backed. Local storage may improve UX but does not become the authoritative registered-user profile.

## 10.9 Commercial separation

Customer/subscriber personalization uses a separate customer context and never reuses the golfer Intelligence State.

---

# 11. Physical Database Schema + GI-1.1 Migration Map

## 11.1 Verified live baseline

The live Supabase schema was inspected during design. The core public tables have RLS enabled. Relevant verified baseline properties include:

- `gal_users.id` UUID canonical user PK linked separately to `auth.users`.
- `gal_current_user_id()` resolves active GAL identity from `auth.uid()`.
- `gal_profile_facts` has a unique `(user_id, fact_key, scope)` current-state constraint.
- `gal_bags` enforces one active bag per user with a partial unique index.
- `gal_buyer_events` already has user/time/category/product/event indexes appropriate for longitudinal behavior.
- `gal_profile_facts` and `gal_buyer_events` contained zero rows at inspection, providing a favorable window to govern fact/event semantics before longitudinal production data accumulates.
- `gal_catalog_products` contains the cross-category canonical product layer.
- `gal_intelligence_state` is already user-read/system-write by policy.
- `gal_consent_records` currently has a broad authenticated self-`ALL` policy; this is intentionally tightened by GI-1.1 to match the append-only consent-history contract in Section 8.

No production schema mutation was performed during design.

## 11.2 RETAIN

Retain initially without destructive redesign:

- `gal_users`
- `gal_catalog_products`
- `gal_valuation_snapshots`
- `gal_guest_migrations`
- existing category equipment registries
- existing release registries/artifacts

## 11.3 EXTEND

Extend additively:

- `gal_profile_facts`
- `gal_bags`
- `gal_bag_items`
- `gal_buyer_events`
- `gal_decision_snapshots`
- `gal_intelligence_state`
- `gal_consent_records`

### `gal_profile_facts` additions

Add compatible fields for:

- explicit value state
- unit
- governed source type/detail
- fact-catalog version
- effective timestamp
- last-confirmed timestamp
- model/question versions
- privacy/commercial classes
- external data-source reference where applicable

Do not add `superseded_at` to current facts; supersession belongs in history.

Existing `source`/`source_category` remain during an expand-and-contract transition.

### `gal_bags`

Potential additions limited to real-bag metadata such as bag type/archive timestamp. Scenarios are not stored as actual bags.

### `gal_bag_items`

Potential additions include identification status/confidence and effective-from timestamp. Current nullable canonical product ID remains important for partial identity.

### `gal_buyer_events`

Add event version, session, optional journey, recommendation-run link, signal class, and invalidation metadata without duplicating existing event/category/product/source/timestamp fields.

### `gal_decision_snapshots`

Link to recommendation run/item and profile/bag snapshots while preserving existing JSON and reason fields for backward compatibility.

### `gal_intelligence_state`

Add state schema version, generation ID, status, latest-source timestamp, and domain status.

### `gal_consent_records`

Extend consent categories/metadata additively; do not destructively rename existing enum values in GI-1.1. Replace the current broad authenticated self-`ALL` policy with explicit policies that support reading one’s own consent history and appending new governed consent/withdrawal records while denying normal authenticated `UPDATE` and `DELETE` of prior rows.

## 11.4 ADD — Foundational

- `gal_fact_catalog`
- `gal_profile_fact_history`
- `gal_inferences`
- `gal_question_catalog`
- `gal_question_responses`
- `gal_profile_snapshots`
- `gal_event_catalog`
- `gal_model_registry`

## 11.5 ADD — Jerry’s Bag

- `gal_bag_item_history`
- `gal_bag_snapshots`
- `gal_bag_scenarios`
- `gal_bag_scenario_items`
- `gal_bag_score_snapshots`

## 11.6 ADD — Recommendation

- `gal_recommendation_runs`
- `gal_recommendation_items`
- `gal_fit_score_components`

## 11.7 ADD — Intelligence

- `gal_intelligence_snapshots`
- `gal_insights`

## 11.8 ADD — Connected services

- `gal_external_source_catalog`
- `gal_data_connections`
- `gal_data_sync_runs`

Provider credentials/passwords are not stored as normal application-readable fields.

## 11.9 DEFER until feature implementation requires them

- `gal_personalization_actions`
- dedicated bag-value snapshot table
- recommendation outcomes
- commercial aggregate tables/views

## 11.10 Physical design rules

- UUIDs remain relational PK/FK identity.
- Existing GAL public IDs/prefix style continues for durable external/audit IDs where useful.
- Reuse existing `gal_category` where semantics match.
- Avoid enums for rapidly evolving fact/event/question/model keys; govern these through catalogs.
- Use relational columns for identity, ownership, status, version, timestamps, category, and common filters.
- Use JSONB for variable configuration, evidence, snapshots, structured reasons, and model configuration.
- Important JSON snapshots always carry an interpreting schema/model/data version.
- New confidence values standardize on numeric 0–1 where possible.
- Fit/bag scores standardize on 0–100.
- New currency fields use three-character currency codes.
- Canonical products should be retired/inactivated rather than physically deleted once referenced.

## 11.11 RLS access classes

### Class A — Golfer CRUD

Examples: current bag, bag items, selected current profile inputs, draft/saved scenarios.

### Class B — Golfer read / trusted write

Examples: inferences, recommendation runs/items, bag scores, Intelligence State, insights.

### Class C — Append-only golfer evidence

Examples: fact history, question responses, buyer events, consent history.

For consent specifically, “append-only” means prior consent rows are immutable to normal golfer clients; a new withdrawal/decision is represented by a new row rather than mutation of the historical grant/decline row.

### Class D — System/reference

Examples: Fact Catalog, Question Catalog, Event Catalog, Model Registry, External Source Catalog.

Ownership policies use `TO authenticated` plus `user_id = gal_current_user_id()` (or equivalently governed parent ownership), with explicit `USING` and `WITH CHECK` for updates where updates are permitted.

Where direct `user_id` denormalization on a private child table materially simplifies secure/indexable RLS, it is acceptable.

## 11.12 Migration sequence

GI-1.1 should be split into reviewable migrations:

A. Governance catalogs  
B. Profile provenance/history  
C. Jerry’s Bag intelligence  
D. Recommendation audit chain  
E. Longitudinal intelligence  
F. Consent + connected services, including consent-policy tightening  
G. Seed + contract validation  
H. Deprecation preparation/documentation

The migration is additive. GI-1.1 must not drop/rename core golfer tables, rewrite canonical IDs, remove existing guide datasets, or destructively migrate equipment registries.

---

# 12. Implementation Phases + Acceptance Tests

## 12.1 Definition of done

GI-1.1 is not done when tables merely exist. It is done when:

- schema and governance catalogs exist;
- RLS/security work;
- fact lifecycle/history works;
- questions reuse known facts;
- bag history/scenarios work;
- recommendations are deterministic/reproducible;
- Intelligence State is rebuildable;
- connected-source architecture is validated;
- privacy boundary is proven;
- existing Buyer’s Guides remain functional;
- staging/RC verification passes.

## 12.2 Phase order

0. Baseline preservation
1. Governance catalogs
2. Current facts + historical provenance
3. Question & Learning Engine
4. Jerry’s Bag history + scenarios
5. Recommendation audit chain
6. Behavior + longitudinal intelligence
7. Golfer Intelligence State
8. Insights + bounded personalization orchestration
9. Connected-app framework
10. Consent + privacy enforcement
11. Existing Buyer’s Guide integration
12. Registered golfer experience
13. Customer portal contract verification
14. Full integration regression
15. Immutable release candidate and staging/production promotion

## 12.3 Baseline gate

Before implementation, capture exact Git commit, schema/RLS/index state, equipment release versions, guide versions, and current application build.

Verify all applicable guides:

- Golf Ball
- Driver
- Fairway Woods
- Hybrids
- Irons
- Wedges
- Putter

Fairway Woods & Hybrids is a standing explicit regression gate because of prior hanging/failure behavior.

## 12.4 Minimum acceptance suite

### Facts

- `GI-FACT-001` Current fact uniqueness
- `GI-FACT-002` Historical supersession
- `GI-FACT-003` Unknown state semantics
- `GI-FACT-004` Source provenance
- `GI-FACT-005` Inference confirmation
- `GI-FACT-006` Inference rejection

### Security/RLS

- `GI-RLS-001` Own profile read
- `GI-RLS-002` Other profile denied
- `GI-RLS-003` History update denied
- `GI-RLS-004` Intelligence-state write denied
- `GI-RLS-005` Customer raw golfer access denied
- `GI-RLS-006` Prior consent update/delete denied

### Questions

- `GI-QUESTION-001` Known answer reused
- `GI-QUESTION-002` Stale answer confirmed
- `GI-QUESTION-003` Unknown triggers proxy
- `GI-QUESTION-004` Question version retained
- `GI-QUESTION-005` Cross-guide reuse

### Bag

- `GI-BAG-001` Current bag integrity
- `GI-BAG-002` Replacement history
- `GI-BAG-003` Configuration history
- `GI-BAG-004` Scenario isolation
- `GI-BAG-005` Scenario adoption
- `GI-BAG-006` 14-club count

### Recommendations

- `GI-REC-001` Determinism
- `GI-REC-002` Score components reconcile
- `GI-REC-003` Historical reproducibility
- `GI-REC-004` Keep current
- `GI-REC-005` Reconfigure current
- `GI-REC-006` Commerce independence

### Events

- `GI-EVENT-001` Canonical event enforcement
- `GI-EVENT-002` Behavior does not automatically become fact
- `GI-EVENT-003` Journey sequencing
- `GI-EVENT-004` Event invalidation

### Intelligence

- `GI-STATE-001` State rebuild
- `GI-STATE-002` Provenance summary
- `GI-STATE-003` Conflict behavior
- `GI-STATE-004` Partial degradation

### Connected services

- `GI-CONNECT-001` Provider normalization
- `GI-CONNECT-002` Scope enforcement
- `GI-CONNECT-003` Revocation
- `GI-CONNECT-004` Provider-use restriction

### Privacy

- `GI-PRIVACY-001` Consent withdrawal
- `GI-PRIVACY-002` Sensitive-data commercial exclusion
- `GI-PRIVACY-003` Customer raw-data denial
- `GI-PRIVACY-004` Small cohort suppression

### Guides

- `GI-GUIDE-001` Golf Ball completes
- `GI-GUIDE-002` Driver completes
- `GI-GUIDE-003` Fairway Woods completes
- `GI-GUIDE-004` Hybrid completes
- `GI-GUIDE-005` Irons completes
- `GI-GUIDE-006` Wedges completes
- `GI-GUIDE-007` Putter completes

## 12.5 Core implementation behaviors to prove

### Fact lifecycle

14.2 handicap → update to 12.8 → 12.8 becomes current; 14.2 remains in immutable history with provenance.

### Question reuse

Known current handicap suppresses repeated handicap question. Stale 7-iron carry becomes “still about 150?” rather than a fresh interrogation.

### Proxy behavior

Unknown swing speed routes to driver carry/approved proxies and stores uncertainty instead of fabricating exact speed.

### Bag history

Replacing a club preserves prior item/configuration history. A scenario does not touch current ownership until explicit adoption.

### Recommendation determinism

Same frozen inputs + same data/model versions = same eligibility, component scores, Fit Scores, and ranking.

### Commerce independence

Changing commission/affiliate retailer priority does not alter Fit Score/rank. Changing golfer budget may legitimately alter eligibility/value.

### Intelligence rebuild

Deleting only the derived state in a safe test environment and rebuilding from durable sources produces meaningfully equivalent current intelligence.

### Connected provider

Synthetic current handicap response normalizes through provider adapter into canonical fact/provenance, suppresses redundant questions, and obeys provider commercial-use restrictions.

### Privacy

A simulated customer role cannot read raw profile facts, events, Intelligence State, recommendation runs, or individual bag data. Small cohorts fail the commercial privacy gate.

### Consent immutability

A golfer can record a new consent or withdrawal decision through the governed path and read their own consent history. A normal authenticated client cannot rewrite or delete an earlier consent record.

## 12.6 Guide integration strategy

Migrate guides individually after the intelligence foundation is stable. Existing deterministic scoring should be preserved unless an intentional versioned model change is part of the release.

For identical inputs and unchanged model version, post-migration recommendation behavior should be materially equivalent. Any difference must have a documented cause.

## 12.7 Synthetic test personas

Maintain representative non-personal personas including:

- new golfer with sparse facts
- returning golfer with strong profile/bag
- golfer who does not know technical data
- golfer with connected current handicap
- improving/changing golfer
- price-sensitive golfer
- golfer whose current equipment is already excellent
- golfer with partially identified bag equipment

## 12.8 Failure/fallback behavior

Simulate AI explanation unavailable, stale Intelligence State, unavailable connected provider, missing price/product image, and partial profile.

Core Buyer’s Guide and deterministic recommendation utility must degrade gracefully rather than fail.

## 12.9 RC gate

Only after full integration regression passes may the release branch/RC be created.

Every RC is immutable and includes a verification sheet covering:

- migrations + replay
- constraints/indexes
- RLS positive/negative cases
- fact/question/bag/recommendation/intelligence workflows
- consent/privacy
- connected-service framework
- every guide
- Jerry’s Bag
- mobile
- customer portal contract when affected
- Supabase security/performance advisor findings

Any material FAIL blocks promotion.

## 12.10 Production promotion

Production remains unchanged during design/implementation planning.

Approved flow:

feature branch → development/preview DB → tests → develop integration → release branch → staging → immutable RC verification → user approval → protected main → production migration/deploy → production smoke test → Git release/tag → Drive governance archive.

---

# 13. Cross-Cutting Locked Rules

The following rules are normative across all sections.

1. **Algorithms decide. AI interprets, converses and teaches.**
2. One canonical GAL user identity is used for operational golfer data.
3. Authentication identity remains separate from golfer profile/intelligence.
4. One canonical cross-category equipment identity layer is retained.
5. Current fact and durable fact history are separate responsibilities.
6. Current bag ownership and hypothetical scenarios are separate responsibilities.
7. Behavior is evidence, not automatically truth.
8. Inference remains distinguishable from declared/measured/imported data.
9. Known current information is reused instead of repeatedly asked.
10. “I don’t know” is valid information.
11. The deterministic Fit Engine controls ranking.
12. AI cannot silently override ranking or invent unsupported golfer/product facts.
13. Current equipment participates in recommendation decisions; “keep” and “reconfigure” are valid outcomes.
14. Recommendation ranking is independent of GAL affiliate/manufacturer economics.
15. Product price may affect ranking only through golfer value/preferences and governed model logic.
16. Historical recommendations are immutable and tied to exact profile/bag/data/model versions.
17. Individual golfer data is never a customer/subscriber portal dataset.
18. Commercial intelligence is consent-compatible, de-identified, aggregate-first, and cohort-protected.
19. Connected-app data retains provenance and provider-use restrictions.
20. Sensitive physical/health fitting information is excluded from commercial analytics.
21. `gal_intelligence_state` is a rebuildable computed state, not source-of-truth history.
22. All GAL surfaces use the same governed current-truth resolution.
23. AI receives minimum necessary purpose-specific user context.
24. Existing core tables are extended additively rather than replaced by parallel equivalents.
25. New public/exposed tables require explicit RLS, grants, policies, indexes, and access tests.
26. Consent history is append-only to normal golfer clients; withdrawal is a new historical record, not mutation of an earlier consent row.
27. Development/preview environments do not contain unsanitized production golfer data.
28. Migrations live in Git; production is a promotion target, not a design environment.
29. Release candidates are immutable and map to one exact source commit.
30. All Buyer’s Guides must pass before production promotion.
31. Fairway Woods & Hybrids receives explicit regression verification before every release candidate.
32. Shared golfer/customer data contracts are updated and verified across both experiences when affected.
33. No GI-1.1 implementation work begins until this written spec is finally reviewed and approved, after which a separate detailed implementation plan is required.

---

# 14. Scope Boundary

GI-1.1 proves five visible outcomes:

1. **GAL Remembers** — known information is reused across guides.
2. **GAL Learns** — changes create governed longitudinal history.
3. **Jerry’s Bag Persists** — current equipment, history, and what-if scenarios remain durable and distinct.
4. **GAL Can Explain** — recommendations are deterministic, reproducible, versioned, and explainable.
5. **GAL Respects the Golfer** — provenance, consent, connected-source restrictions, and commercial privacy boundaries are explicit.

GI-1.1 does **not** require advanced machine learning, autonomous AI fitting, full customer analytics, dozens of live third-party integrations, complete historic backfill, or complex marketing automation.

Likely post-GI-1.1 candidates include live handicap-provider integration, launch-monitor integration, recommendation outcomes, annual “State of Your Bag,” deeper valuation history, customer aggregate analytics, model shadow testing, and more advanced adaptive personalization.

---

# 15. Self-Review Record

The consolidated spec was reviewed against the approved Sections 1–12 for the required brainstorming-spec checks.

## Placeholder scan

No `TBD` or `TODO` requirements remain. Deferred features are explicitly labeled as out-of-scope/deferred rather than unresolved.

## Internal consistency

Resolved/confirmed:

- `gal_profile_facts` is current state; history is separate.
- `gal_intelligence_state` is a rebuildable cache; recommendation reproducibility uses immutable snapshots instead.
- `gal_buyer_events` remains canonical; no duplicate behavior-event table is introduced.
- `gal_bags`/`gal_bag_items` remain real ownership state; scenarios are separate.
- `gal_decision_snapshots` remains compatible while normalized recommendation entities are added.
- connected-app imported data is both provenance-rich and constrained by golfer consent + provider terms.
- price/value can influence golfer recommendations, but affiliate payout cannot.
- production models/history are immutable while current state may be recomputed under newer versions.
- live consent policy mismatch identified during self-review is resolved normatively: GI-1.1 must replace broad self-`ALL` consent access with append-only consent history semantics for normal golfer clients.

## Scope check

GI-1.1 is large but coherent as one architecture because its implementation is explicitly phased and each phase depends on shared canonical identity/provenance semantics. Commercial analytics and advanced personalization are deferred to prevent the implementation plan from becoming unbounded.

## Ambiguity check

The following design choices are explicit:

- Existing physical tables are extended rather than replaced.
- Current facts use one row per `(user_id, fact_key, scope)`.
- Current equipment is not duplicated into fact keys.
- “Newer” data does not automatically outrank more authoritative data.
- User correction outranks conflicting GAL interpretation about the user.
- Recommendation runs use frozen snapshots and explicit model/data versions.
- AI explanation and deterministic ranking are separate layers.
- Customer systems never receive direct raw golfer-table access.
- Provider credentials do not live in normal application-readable tables.
- Consent history is immutable to normal golfer clients; new decisions are appended.
- GI-1.1 is additive; destructive cleanup is deferred to later expand-and-contract phases.

No contradiction remains that should block implementation planning.
