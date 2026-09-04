# GAL Equipment Knowledge Layer — Supabase Schema Gap Design

Status: USER-APPROVED ARCHITECTURAL DIRECTION / DESIGN SPEC FOR REVIEW
Date: 2026-09-03
Branch: `portal-integration-plan`
Applies to: GAL Equipment Knowledge Layer, AI Fitting, Buyers Guides, My Bag, Equipment Intelligence, Equipment Testing, Valuation, Longitudinal Insights, Staging/Production Governance.

## 1. Purpose

This document translates the locked GAL Equipment Knowledge Layer architecture into a concrete Supabase schema-gap assessment. It does not authorize database migrations or production changes.

The governing architecture is defined in:

`docs/superpowers/specs/2026-09-03-gal-equipment-knowledge-layer-design.md`

The goal of this review is to determine:
- what already exists and should be reused;
- what exists but should become migration/source input rather than permanent analytical authority;
- what normalized structures are missing;
- how staging and production should be reconciled before implementation;
- the migration boundary and sequencing needed to preserve current behavior and data.

## 2. Read-Only Environment Findings

A read-only Supabase review found a material environment split.

### Production currently includes useful first-generation equipment foundations

Production contains, among other structures:
- `gal_catalog_products` with approximately 955 canonical product rows;
- `gal_driver_registry` and `gal_driver_master_registry` with approximately 64 driver rows;
- driver market/release/source/commerce support tables;
- `gal_bags` and `gal_bag_items`;
- `gal_profile_facts`;
- `gal_decision_snapshots`;
- `gal_valuation_snapshots`;
- release registries/artifacts;
- longitudinal insight, response, outcome, resolution, and learning structures.

### Staging currently includes the longitudinal architecture but does not mirror the older catalog/bag/profile equipment foundation

The observed staging schema contains the current longitudinal insight/learning stack, but the production catalog, driver registry, bag, profile, valuation, and release structures are not presently represented there in equivalent form.

### Consequence

Staging is not yet a complete rehearsal environment for the combined GAL architecture. This must be corrected through version-controlled schema reconciliation, not by copying production golfer data into staging.

## 3. Architectural Decision — Evolve, Normalize, and Govern

GAL will evolve the existing database rather than discard it.

Existing valid data is preserved and migrated into a normalized governed Equipment Knowledge model. Legacy registries and JSON payloads may remain as historical/source records during transition, but they do not become the permanent analytical truth layer.

**Governing rule:**

> GAL evolves the existing database rather than discarding it, but legacy catalog registries and JSON payloads do not become the permanent Equipment Knowledge architecture. Existing valid data is preserved, normalized, governed, and migrated into the new model.

## 4. Structures to Reuse and Extend

### 4.1 `gal_catalog_products`

Use as the starting point for canonical product identity because it already contains:
- `canonical_product_id`;
- `canonical_brand_id`;
- category;
- display brand/model;
- dataset/version provenance;
- active/sync metadata.

Gap: the table is too flat for the locked:

`Product Family -> Product Variant -> Component -> Compatible Configuration`

architecture.

Decision: preserve canonical IDs where valid, but introduce normalized family/variant/component/configuration relationships rather than expanding this table into a catch-all record.

### 4.2 `gal_bags` and `gal_bag_items`

These are good foundations for golfer-owned equipment and should remain separate from global Equipment Knowledge.

Current `gal_bag_items` already contains:
- user/bag ownership;
- category/slot/grouping;
- canonical product/brand identity;
- display snapshot;
- JSON configuration;
- purchase and ownership fields;
- decision snapshot link.

Decision: retain the golfer-owned equipment layer. During migration, `configuration` may continue as a compatibility bridge, but exact known builds should ultimately reference a governed configuration identity plus a golfer-specific snapshot where necessary.

### 4.3 `gal_profile_facts`

This aligns strongly with the locked Tell GAL Once / Connect It Once model because it already supports:
- fact key/value;
- source and source category;
- confidence;
- golfer confirmation;
- scope;
- staleness controls;
- observed/updated timestamps.

Decision: extend/reconcile this architecture rather than replacing it.

### 4.4 `gal_decision_snapshots`

Useful as immutable historical decision/recommendation evidence.

Decision: retain as an audit/history concept, but future AI Fitting decisions should reference structured fitting sessions, frozen target sets, candidate configurations, methodology versions, and evidence references rather than using decision snapshots as the fitting engine itself.

### 4.5 `gal_valuation_snapshots`

This already reflects much of the locked Bag Value provenance model: valuation type, condition, amount/currency, market, source, observation date, confidence, method note.

Decision: preserve it as a valuation subsystem and keep valuation analytically separate from fit ranking unless a golfer-declared value constraint explicitly invokes price/value through a governed rule.

### 4.6 Longitudinal insight and learning tables

The existing `gal_insights`, signals, exposures, responses, outcomes, resolution, learning snapshots/candidates, governance actors, and evaluation policies remain the downstream lifecycle for golfer-facing equipment opportunities and post-change outcomes.

Decision: do not merge Equipment Knowledge into these tables. Equipment Knowledge produces governed analytical facts/candidates; the longitudinal system manages golfer-specific insight lifecycle, outcomes, resolution/regression, and aggregate learning.

## 5. Legacy Structures to Treat as Source/Migration Inputs

Production currently contains overlapping driver structures including:
- `gal_driver_registry`;
- `gal_driver_master_registry`;
- `gal_driver_brand_intelligence`;
- `gal_driver_sources`;
- related release/market/commerce registries.

These structures contain useful existing data, but much of their analytical information is represented in JSON `payload` fields.

### Decision

They are migration/source datasets, not the permanent Equipment Knowledge schema.

Reasons:
- provenance is difficult to govern at individual attribute level inside opaque payloads;
- product family/variant/component/configuration boundaries are not first-class;
- effective dating and lifecycle semantics are limited;
- compatibility rules are not first-class;
- source conflict preservation is harder;
- readiness/eligibility by use case is not explicit;
- test/sample/session/observation evidence cannot be represented rigorously;
- attribute-level methodology versioning is not reliably enforced.

Migration must preserve historical rows/source payloads until reconciliation and verification are complete.

## 6. Required New Logical Layers

The target Supabase architecture should contain six logical layers.

### Layer A — Canonical Equipment

Required concepts:
- manufacturers/brands;
- product families;
- product variants;
- components;
- aliases/identity resolution;
- lifecycle events/effective periods;
- officially supported options.

### Layer B — Equipment Evidence

Required concepts:
- source records/documents/datasets;
- normalized source observations;
- GAL ontology attribute definitions;
- attribute observations;
- evidence class;
- claim state;
- effective date/window;
- source freshness;
- conflict state/resolution;
- review/promotion state;
- underlying source references.

Raw/source evidence must remain distinct from approved production knowledge.

### Layer C — Configurations and Compatibility

Required concepts:
- governed equipment configurations;
- configuration components/settings;
- support state: `FACTORY_STANDARD`, `FACTORY_CUSTOM`, `AFTERMARKET_VALID`, `UNVERIFIED/INVALID`;
- compatibility rules;
- hard constraints;
- dependent-effect rules;
- structured set/bag relationships where category-specific fitting requires them.

Unknown compatibility is not compatible.

### Layer D — Testing and Derivations

This is a current first-class schema gap.

Required chain:

`Product/Variant -> Physical Sample -> Tested Configuration -> Test Session -> Test Run/Observation -> Derived Equipment Characteristic`

Required concepts include:
- physical sample identity/history;
- exact tested configuration;
- test session context;
- protocol/methodology version;
- instrumentation/calibration/environment;
- immutable observations;
- exclusion records/reasons;
- derived/aggregate characteristics;
- contributing evidence IDs;
- scope of generalization.

### Layer E — Readiness and Governance

Readiness must not be a single product column.

Required concepts:
- equipment/configuration entity;
- category/use case;
- readiness state: `CATALOG_READY`, `GUIDE_READY`, `AI_FIT_LIMITED`, `AI_FIT_READY`;
- governing readiness policy/version;
- Required / Conditionally Required / Optional attribute rules;
- evaluation timestamp;
- blocking conditions;
- Evidence Gap Queue items;
- promotion/review history.

### Layer F — Approved Consumer Views

The same approved knowledge should feed:
- public Buyers Guide read views/contracts;
- authenticated AI Fitting read views/contracts;
- My Bag equipment detail;
- comparisons;
- Equipment Intelligence.

There must not be duplicate physical product-truth databases for Buyers Guides versus AI Fitting.

## 7. Media and Commerce Boundaries

Media records and commerce routing remain separate from analytical Equipment Knowledge.

Media needs explicit rights/provenance and approved-use controls but does not affect analytical readiness/rank.

Commerce may attach after analytical candidate selection. Affiliate commission, sponsorship, retailer relationship, inventory economics, and paid placement remain excluded from analytical ranking.

Existing commerce-route and price tables can remain downstream support structures during migration.

## 8. Recommended Schema Parity Rule

Before a release can safely change Equipment Knowledge in production, staging must contain the full schema required to rehearse that release.

**Governing rule:**

> Staging must contain the complete production schema required for a release before production implementation; production golfer data is not copied to staging to achieve that parity.

Parity is achieved through:
- version-controlled migrations;
- schema verification;
- sanitized fixtures/test records;
- reproducible seed/reference data where appropriate;
- environment-specific secrets/configuration;
- no unsanitized production golfer-data copy.

## 9. Migration Boundary

The implementation should be divided into controlled waves.

### Wave A — Preserve and Reconcile

Objective: establish a safe known baseline before new Equipment Knowledge structures become authoritative.

Includes:
- inventory current production/staging schema;
- reconcile migration history;
- establish staging schema parity for required existing catalog/bag/profile/release structures;
- create sanitized fixtures;
- classify each legacy equipment table as retain, extend, migrate-source, or retire-after-cutover;
- add non-destructive verification queries/tests.

No consumer behavior change.

### Wave B — Add Equipment Knowledge Core

Objective: add normalized product/evidence/governance structures without changing current public behavior.

Includes:
- family/variant/component identity;
- ontology definitions;
- source/provenance records;
- attribute observations;
- derived characteristics;
- lifecycle/effective dating;
- source governance/conflict handling.

Legacy registries remain readable during this wave.

### Wave C — Add Configuration, Testing, and Readiness

Objective: support exact fitting configurations and evidence-driven eligibility.

Includes:
- configuration entities/components/settings;
- compatibility/dependency rules;
- physical samples;
- tested configurations;
- test sessions/observations/exclusions;
- derived test characteristics;
- readiness policies/states;
- Evidence Gap Queue.

### Wave D — Migrate Consumers and Retire Analytical Authority

Objective: move golfer-facing consumers to approved governed views.

Sequence:
1. normalize/import existing driver data into the new Equipment Knowledge layer;
2. reconcile source-to-normalized counts and identity mappings;
3. verify analytical equivalence where equivalence is expected;
4. switch public Buyers Guides to approved governed views first;
5. verify guide functionality/consistency;
6. connect AI Fitting/My Bag to the same approved truth;
7. verify longitudinal outcome links;
8. remove legacy registries from analytical authority only after rollback-safe acceptance;
9. retain historical/source records according to governance/retention policy.

## 10. Data-Migration Safety Rules

Implementation must preserve the following:
- existing canonical IDs wherever valid and unambiguous;
- no destructive deletion of source records before reconciliation and retention approval;
- no silent reinterpretation of a legacy payload into a stronger evidence claim;
- marketing language does not become GAL analytical truth during migration;
- unresolved source conflicts remain unresolved until governed resolution;
- unknown values remain unknown;
- derived claims must reference supporting evidence and methodology version;
- readiness must be recalculated from governed evidence rather than copied from marketing/product status;
- production golfer data remains environment-isolated;
- every migration must have rollback/recovery strategy and verification queries.

## 11. Proposed Ownership Boundaries

### Global/reference Equipment Knowledge
Primarily system/governance-managed, not golfer-owned:
- products/variants/components;
- ontology;
- source observations;
- test data;
- compatibility rules;
- readiness policies/states;
- media provenance;
- approved analytical characteristics.

Browser clients should normally consume approved read views/contracts rather than mutate these tables directly.

### Golfer-owned data
Protected by golfer-scoped RLS:
- profile facts;
- My Bag/bag items;
- fitting sessions where golfer-specific;
- saved decisions/actions;
- insight exposures/responses/outcomes;
- applicable valuation records.

Trusted mutations remain behind approved RPC/Edge Function/server paths where governance requires them.

## 12. Primary Gap Summary

### Strong existing foundations
- canonical product IDs/category table;
- My Bag ownership structures;
- Tell GAL Once-style profile fact structure;
- decision snapshots;
- valuation snapshots;
- release registry concepts;
- longitudinal insight/outcome/governance framework.

### Material gaps
- normalized product family/variant/component model;
- first-class ontology/attribute evidence records;
- attribute-level source provenance/conflicts/effective dating;
- governed configuration identities;
- compatibility/dependent-effect rules;
- physical sample/test session/observation model;
- derived-characteristic evidence links;
- use-case-specific readiness policy/state;
- Evidence Gap Queue;
- approved shared Buyers Guide/AI Fitting read views;
- complete staging/production schema parity.

### Legacy transition risk
The JSON-heavy driver registry system contains useful data but should not be extended into the final architecture. It must be migrated non-destructively and verified before its analytical authority is retired.

## 13. Acceptance Gates Before Implementation Planning

Before writing executable migration tasks, the written schema-gap design should be reviewed and approved for:
- evolution-not-replacement strategy;
- reuse of `gal_catalog_products`, bags, profile facts, decision snapshots, valuation, and longitudinal systems;
- classification of driver registries as migration/source inputs rather than permanent truth;
- six-layer target architecture;
- readiness as use-case-specific governance rather than a product flag;
- first-class testing/sample/configuration subsystem;
- one approved Equipment Knowledge truth for Guide + AI Fit;
- schema-parity requirement;
- four-wave migration boundary;
- production-data isolation.

No migration SQL, DDL, data mutation, or production promotion is authorized by this document.

## 14. Recommended Next Step

After user review/approval of this written schema-gap specification, create a detailed implementation plan under:

`docs/superpowers/plans/2026-09-03-gal-equipment-knowledge-schema-migration.md`

The plan should break the migration into independently reviewable/testable tasks, use TDD/verification-first sequencing, specify exact migration files and SQL tests, stage all changes before production, and include rollback gates for each wave.
