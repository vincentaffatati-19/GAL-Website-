# GAL Consumer Integration Design

Date: 2026-09-03 / 2026-09-04 UTC
Status: USER-APPROVED DESIGN — INCLUDING INDUSTRY INTELLIGENCE MONETIZATION BOUNDARY
Target branch: `portal-integration-plan`
Implementation branch: to be created from current `portal-integration-plan`
Production deployment: NOT AUTHORIZED

## 1. Purpose

Connect GAL consumer experiences to the governed Equipment Knowledge Layer without creating duplicate product truth, recommendation logic, or portal implementations.

The consumer phase covers:
- My GAL / Today / Insights / Progress
- My Bag
- Public Buyers Guides
- Logged-in Buyers Guides
- Authenticated GAL AI Fitting
- Registered and subscriber experiences using shared components and shared data contracts
- Preservation of a future privacy-safe B2B Industry Intelligence monetization path

The rollout strategy is a compromise between category-by-category implementation and an all-at-once release: build the shared consumer architecture for every equipment category now, but activate and acceptance-test Driver first as the complete vertical slice.

The architecture must also preserve the business value of GAL longitudinal data by structuring consented evidence, fitting activity, equipment actions, and outcomes so that eligible records can later contribute to privacy-safe aggregate industry intelligence without redesigning the consumer data model.

## 2. Governing Product Rules

The implementation must preserve these locked GAL rules:

1. One governed Equipment Knowledge Layer is the analytical source of truth for Buyers Guides and AI Fitting.
2. My Bag, Buyers Guides, and AI Fitting must not maintain independent product mappings.
3. Characteristics Before Brands:
   `Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`
4. Missing critical evidence narrows or blocks recommendations; assumptions do not fill gaps.
5. Unknown compatibility is not compatible.
6. `AI_FIT_LIMITED` must remain visibly and behaviorally distinct from `AI_FIT_READY`.
7. Absence of an insight or recommendation does not imply good fit.
8. Commerce metadata and compensation have zero analytical influence on ranking.
9. Tell GAL Once applies across My Bag, Guides, fitting workflows, and profile data when values are semantically compatible.
10. Registered and subscriber experiences use the same components and contracts. Entitlements add depth or capability; they do not create a parallel portal or a different equipment truth.
11. Commercial aggregate-data participation is explicit opt-in and separate from ordinary GAL product-use consent.
12. Industry customers may purchase access to GAL intelligence and may commission research questions, but may not purchase a desired conclusion, recommendation, rank, methodology outcome, suppression of unfavorable results, or access to an identifiable golfer.
13. B2B industry intelligence must be generated through a governed privacy/aggregation boundary rather than through direct access to golfer operational data.
14. No production deployment or production Supabase migration is authorized by this design.

## 3. Consumer Integration Architecture

The shared flow is:

`Supabase governed Equipment Knowledge contracts`
-> `GAL consumer data client`
-> `shared equipment read model`
-> `category adapter`
-> `shared golfer-facing components`
-> `My Bag / Guides / AI Fitting / My GAL`

### 3.1 Shared Consumer Data Client

The browser application must have one consumer data-access boundary rather than surface-specific Supabase calls.

Responsibilities:
- call `gal_public_equipment_guide()` for public Guide data;
- call `gal_authenticated_equipment_ai_fit()` only for authenticated AI Fit data;
- attach authenticated session context where required;
- normalize RPC/network failures into explicit consumer states;
- preserve readiness, provenance, freshness, compatibility, and equipment identity data returned by governed contracts;
- never expose or require service-role credentials in browser code.

No My Bag, Guide, Today, Insight, Progress, or AI Fit component may implement its own direct equipment-knowledge query path.

### 3.2 Shared Equipment Read Model

The frontend receives governed database contracts and converts them into stable consumer objects.

The core consumer objects are:
- `EquipmentItem`
- `EquipmentConfiguration`
- `EquipmentOpportunity`
- `EquipmentRecommendation`

These objects are related but must not be collapsed into one another. An equipment item can exist without an opportunity; an opportunity can exist without sufficient attribution for a replacement recommendation; a recommendation is not equivalent to a product record.

The consumer model must preserve at least:
- canonical equipment identity;
- current governed characteristics only;
- configuration identity and support state;
- readiness state;
- limited-evidence state;
- compatibility eligibility;
- provenance/freshness metadata needed for material golfer-facing claims;
- allowed next actions.

Raw governance internals that are not useful to golfers should remain behind the consumer boundary.

### 3.3 Category Adapter Layer

The shared architecture must support all seven GAL equipment categories from day one:
- Driver
- Fairway Wood
- Hybrid
- Iron
- Wedge
- Putter
- Golf Ball

Each category adapter declares:
- category identifier;
- fitting-relevant fields;
- consumer labels;
- category-specific configuration presentation;
- category-specific evidence requirements;
- category-specific explanation mappings;
- category activation state.

Driver is the first active category.

The other six adapters may exist as structurally valid inactive contracts, but they must not claim full fitting support until their category-specific acceptance gate passes.

If a later category requires a new shared concept, that change must be reviewed as a shared-architecture change rather than silently embedded in a category adapter.

## 4. Surface Responsibilities and Data Ownership

### 4.1 My Bag

My Bag is the golfer's equipment inventory and equipment-state surface.

It must:
- show the golfer's actual governed equipment/configuration when known;
- show missing configuration detail as missing rather than inferred;
- distinguish unknown from good fit;
- surface governed equipment opportunities;
- link the golfer into the appropriate fitting flow;
- preserve legacy bag configuration JSON only as a migration bridge, not permanent product truth.

My Bag does not independently generate fitting recommendations.

### 4.2 Buyers Guides

Public Buyers Guides remain educational/discovery/SEO/AEO acquisition surfaces and use the public governed Guide contract.

Logged-in Buyers Guides use the same equipment truth plus Tell GAL Once profile reuse. Known semantically compatible answers may be prefilled, but must be visible and editable.

Recommended copy pattern:

> Using what GAL already knows about you.

A Buyers Guide shortlist remains a lightweight guide recommendation and must not be presented as equivalent to a full AI Fit.

Guide data may flow back into the golfer profile only with source/provenance/freshness semantics intact.

### 4.3 GAL AI Fitting

AI Fitting is authenticated and persistent.

It may consume:
- golfer profile;
- My Bag;
- governed Equipment Knowledge;
- environment/context;
- connected/measured evidence;
- governed category-specific fitting policy.

Driver is the first fully activated fitter.

Driver output must preserve the locked sequence:

`Golfer Need -> Target Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`

Keep Current, Adjust Current, Reconfigure, and Replace must be peer analytical outcomes where evidence supports them.

### 4.4 My GAL / Today / Insights / Progress

These surfaces consume results from My Bag, Equipment Intelligence, and fitting workflows rather than recreating fitting logic.

Examples:
- Today may surface `GAL Sees a Driver Opportunity` and link to Driver Fit.
- Insights may display golfer-safe governed opportunity states.
- Progress records what happened after a recommendation/change and the later outcome/resolution state.

These surfaces must never fabricate Bag Health, savings, confidence scores, fit labels, or recommendations that are not supported by governed methodology/data.

### 4.5 Registered vs Subscriber

Registered and subscriber users share the same UI components and same data model.

Entitlements may add:
- greater history depth;
- advanced evidence/explanation detail;
- additional fitter capabilities;
- premium workflows.

Entitlements must never:
- alter canonical equipment facts;
- change analytical rank;
- create a separate recommendation implementation;
- create a separate copy of My Bag, Guide, or AI Fit logic.

## 5. Consumer Data Flow and State Handling

The runtime flow is:

`Consumer surface request`
-> `shared client`
-> `public Guide RPC or authenticated AI Fit RPC`
-> `normalize into shared read model`
-> `category adapter`
-> `golfer-facing state`
-> `action`

### 5.1 Required Consumer States

The shared model and UI must distinguish:
- ready;
- limited evidence;
- missing required golfer/profile data;
- missing equipment configuration;
- stale evidence;
- compatibility unresolved;
- not Guide-ready;
- not AI-Fit-ready;
- disconnected evidence source;
- authorization failure;
- service/network failure.

No state may collapse into a misleading recommendation.

### 5.2 Trust Rules

Consumer behavior must enforce:

- Unknown is not good fit.
- Missing critical evidence narrows or blocks recommendations.
- `AI_FIT_LIMITED` is visibly different from `AI_FIT_READY`.
- A configuration must pass governed compatibility eligibility before appearing as an AI Fit candidate.
- Only current effective unsuperseded production characteristics are presented as current equipment truth.
- Historical characteristic versions remain available for audit/history but are not mixed into current recommendations.
- Material recommendations expose provenance/freshness when the golfer needs to understand why GAL is making the claim.
- Commerce cannot alter analytical ranking.
- Logged-in guide reuse is visible and editable.
- Subscriber entitlement cannot change equipment truth.

### 5.3 Safe Failure Behavior

Public Guide personalization failure must not destroy the basic educational Guide experience.

My Bag must still show known equipment if AI Fit is temporarily unavailable.

AI Fitting must never silently fall back to product-first ranking when evidence/readiness/compatibility requirements are not satisfied.

Service failures must expose a safe user-facing state and preserve a retry/resume path where appropriate.

## 6. Driver-First Vertical Slice

The first fully functional consumer integration is Driver.

The acceptance journey is:

`My Bag`
-> `Driver opportunity`
-> `AI Driver Fit`
-> `Target Characteristics`
-> `Governed Configuration Candidates`
-> `Why This Fit`
-> `Next Action`
-> `Outcome / Progress`

The public and logged-in Driver Buyers Guide must use the same current equipment truth as Driver AI Fitting.

The Guide and AI Fit may produce different golfer-specific outputs because AI Fit knows more about the golfer, but they must not disagree about canonical equipment facts.

## 7. Testing Strategy

Testing occurs at three layers.

### 7.1 Contract Tests

Verify:
- public Guide RPC is accessible to anon and authenticated roles;
- AI Fit RPC is accessible only to authenticated users;
- only governed eligible data reaches consumer contracts;
- readiness and compatibility states are preserved;
- current governed characteristic selection is stable;
- direct internal equipment views remain non-browser-readable.

### 7.2 Shared Consumer Model Tests

Verify:
- normalization into stable consumer types;
- category registry contains all seven categories;
- only Driver is initially active;
- unknown/missing/stale/limited states remain distinct;
- provenance/freshness is retained;
- incompatible or unready candidates cannot be promoted to recommendations;
- adapters cannot fabricate fields absent from governed data;
- entitlement changes do not alter equipment truth.

### 7.3 Surface/E2E Tests

Driver acceptance must verify:
- current equipment displays correctly in My Bag;
- missing configuration prompts correctly;
- `AI_FIT_LIMITED` vs `AI_FIT_READY` presentation;
- unresolved compatibility blocks candidate presentation;
- Characteristics Before Brands ordering;
- Keep/Adjust/Reconfigure/Replace peer actions;
- provenance visibility;
- no commerce influence on rank;
- logged-in Guide reuse;
- anonymous Guide continuity;
- registered/subscriber component synchronization;
- Today/Insights/Progress links use the same opportunity/fitting state.

## 8. Rollout Sequence

1. Reconcile the existing My GAL shell work from PR #25 onto the current `portal-integration-plan` state.
2. Add the shared consumer data client and shared equipment read model.
3. Add the category registry and all seven category adapter contracts; activate Driver only.
4. Integrate My Bag with the shared model.
5. Integrate authenticated Driver AI Fit.
6. Integrate public and logged-in Driver Buyers Guide.
7. Connect Driver opportunity/results to Today, Insights, and Progress.
8. Run full staging acceptance across anonymous, registered, and subscriber states.
9. Expand through independent category activation gates in this order unless later product evidence justifies reordering:
   - Fairway Wood
   - Hybrid
   - Irons
   - Wedges
   - Putter
   - Golf Ball

Each category activation is an extension of the shared architecture, not a new product-truth stack.

## 9. My GAL Shell Reconciliation Prerequisite

PR #25 (`my-gal-task1`) was created against an earlier `portal-integration-plan` base and is no longer mergeable after the Equipment Knowledge integration advanced the base branch.

Before consumer implementation begins, the My GAL shell must be reconciled onto current `portal-integration-plan` without losing:
- `/portal/` default Today route;
- Today / My Bag / Insights / Guides / Progress route contract;
- approved Option 7A Motion / Stylized Option B: Motion Arc brand asset;
- public-only Supabase configuration contract;
- no browser service-role material;
- no fabricated Bag Health placeholder;
- portal CI checks.

This reconciliation is source integration only and does not authorize production deployment.

## 10. Release and Production Gate

Consumer integration is implemented and validated in development/staging first.

Production remains separately gated.

Before any production release, require:
- current branch/PR review;
- successful unit/contract/E2E CI;
- staging Driver acceptance across anonymous, registered, and subscriber states;
- staging Supabase security/performance advisor review;
- production read-only baseline verification;
- explicit production migration/release approval;
- post-release acceptance and rollback procedure.

No implementation task under this design implicitly authorizes a production database migration or website production promotion.

## 11. Success Criteria

The Driver-first consumer integration is successful when a golfer can:

1. See the Driver currently represented in My Bag using governed equipment identity/configuration.
2. Understand whether GAL sees an equipment opportunity and the evidence state supporting it.
3. Enter AI Driver Fitting without re-entering semantically compatible information GAL already knows.
4. See target equipment characteristics before any brand/model recommendation.
5. See only governed eligible configurations.
6. Understand why each recommended action is presented and what evidence is missing or limited.
7. Choose Keep, Adjust, Reconfigure, Replace, Compare/Test, or Buy only when analytically supported.
8. Return later and see the resulting outcome reflected in Progress/longitudinal intelligence.
9. Use a public or logged-in Driver Buyers Guide that relies on the same equipment truth.
10. Receive the same underlying equipment truth regardless of registered/subscriber entitlement level.

The architecture is also successful when the remaining six categories can be added through category-specific adapters and acceptance gates without creating a second consumer data stack or redesigning the shared product model.

## 12. Industry Intelligence & Data Monetization Boundary

GAL will preserve a separate B2B monetization architecture while keeping golfer trust, privacy, and analytical independence intact.

### 12.1 Revenue Model Separation

GAL recognizes four distinct monetization paths:

1. **B2C Golfer Membership** — premium personalization, My Bag intelligence, AI Fitting, Progress, history, and advanced golfer workflows.
2. **B2B GAL Industry Intelligence** — recurring subscriptions or licenses to privacy-safe aggregate intelligence, benchmarking, category trends, configuration demand, replacement cycles, consideration patterns, and outcome trends.
3. **B2B GAL Custom Research** — commissioned aggregate studies for manufacturers, brands, component companies, retailers, PR/marketing agencies, and other qualified industry customers.
4. **Commerce / Affiliate / Referral** — downstream monetization after the analytical decision; never an input to analytical rank.

These revenue models may reinforce one another, but they must remain logically and technically separable.

### 12.2 Editorial and Analytical Firewall

The governing principle is:

> **Industry customers can buy intelligence from GAL. They cannot buy influence over GAL intelligence.**

A paying company may purchase access to approved intelligence or fund a research question. Payment may not influence:
- golfer need determination;
- target characteristics;
- candidate eligibility;
- candidate or product ranking;
- recommendation wording;
- evidence strength;
- methodology result;
- publication of an analytically required caveat;
- suppression or alteration of unfavorable findings.

A customer commissions the question, not the answer.

Commercial agreements may define confidentiality, embargo, delivery format, or publication rights where appropriate, but must not permit the sponsor to modify GAL's underlying findings or methodology record.

GAL should ordinarily retain ownership of its underlying methodologies, generalized learnings, and derived aggregate intelligence. Customers normally purchase access or a license unless a specific agreement explicitly grants different rights.

### 12.3 Explicit Opt-In Consent

Commercial aggregate-data participation is separate from ordinary GAL product use.

A golfer may use GAL products without agreeing that eligible golfer data contributes to commercial aggregate intelligence.

Commercial-use eligibility must be based on an explicit opt-in consent record that is versioned and auditable.

At minimum, each eligible source record or governed contribution path must be resolvable to:
- permitted-use status;
- consent version;
- effective time window;
- source/provenance class;
- withdrawal state where applicable.

Consent withdrawal must be honored in future aggregate generation and in existing aggregate artifacts where technically and legally required by the governing policy.

### 12.4 Privacy and Aggregation Boundary

Industry customers must never query individual golfer operational records directly.

The approved flow is:

`Golfer / Profile / Bag / Fitting / Action / Outcome Data`
-> `Consent + Permitted-Use Check`
-> `Privacy / De-identification`
-> `Minimum Cohort / Disclosure-Risk Gate`
-> `Governed Aggregate Dataset`
-> `Approved Intelligence Product / Research Output`

The B2B layer must enforce:
- no identifiable golfer exports;
- no direct row-level access to operational golfer records;
- minimum cohort/privacy thresholds before release;
- suppression of slices that create re-identification risk;
- no customer-defined filters that bypass those thresholds;
- reproducible aggregate dataset versions;
- provenance back to governed source classes;
- explicit separation of raw evidence, GAL-derived intelligence, and customer-facing outputs;
- entitlement isolation between golfer subscriptions and industry subscriptions.

### 12.5 B2B Product Tiers

GAL may develop three B2B product classes from the governed aggregate layer:

**GAL Industry Intelligence Subscription**
- recurring access to approved dashboards and predefined aggregate intelligence products;
- entitlement-controlled views;
- no access to individual golfer records.

**GAL Intelligence Reports / Benchmarking**
- periodic or one-time reports covering categories, product launches, golfer segments, fitting needs, configuration trends, or market shifts;
- may be sold individually or bundled into subscription tiers.

**GAL Custom Research**
- commissioned research where the sponsor may define the business question and proposed cohort criteria;
- GAL controls final inclusion rules, methodology, statistical treatment, privacy thresholds, evidence standards, interpretation, and findings;
- sponsor receives only approved aggregate outputs, not raw golfer-level data.

### 12.6 Initial Customer Access Model

Initial B2B access will be limited to:
- dashboards;
- GAL-generated reports;
- GAL-generated approved exports.

Direct downloadable row-level aggregate datasets and external customer-queryable APIs are explicitly deferred until GAL has mature privacy governance, redistribution controls, contractual protections, and sufficient scale.

This is a staged capability decision, not a permanent prohibition.

### 12.7 Longitudinal Intelligence Asset

The consumer architecture should preserve the future ability to analyze the full outcome chain:

`Golfer Need`
-> `GAL Recommendation`
-> `Equipment Considered`
-> `Configuration Selected`
-> `Purchase / Adjustment / Change`
-> `Observed Outcome`
-> `Resolved / Ineffective / Regressed`

When records are properly consented and privacy-safe, this longitudinal structure can support differentiated GAL industry intelligence about equipment needs, configuration behavior, market demand, and measured post-change outcomes.

The system must therefore preserve provenance and linkage across fitting sessions, recommendations, actions, outcomes, and longitudinal resolution without exposing those links to B2B customers at golfer level.

### 12.8 B2B Success Criteria

The architecture preserves the GAL business model when:

1. Golfer subscription features and industry subscription features remain entitlement-separated.
2. A golfer can use GAL without opting into commercial aggregate-data participation.
3. Only explicitly opted-in eligible data can contribute to commercial aggregate products.
4. No industry customer can directly access an identifiable golfer or operational golfer-level row.
5. Minimum cohort and disclosure-risk rules block unsafe slices.
6. Aggregate datasets and reports are reproducible and versioned.
7. A sponsor can commission a research question without controlling the answer.
8. Commercial relationships cannot alter recommendation ranking or analytical conclusions.
9. GAL can build future dashboards, benchmarking, launch tracking, demand signals, outcome studies, and licensed intelligence products from the same governed aggregate layer without changing the consumer product-truth architecture.
10. B2B data monetization increases the value of GAL's privacy-safe longitudinal intelligence asset without compromising golfer trust or editorial independence.
