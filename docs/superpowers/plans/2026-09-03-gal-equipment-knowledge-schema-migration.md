# GAL Equipment Knowledge Schema Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evolve GAL's existing Supabase equipment/catalog foundation into the governed Equipment Knowledge architecture while preserving valid legacy data, establishing staging/production schema parity, and keeping all golfer-facing behavior rollback-safe until approved cutover.

**Architecture:** Implement the approved six-layer model in four controlled waves: preserve/reconcile, add normalized equipment knowledge, add configuration/testing/readiness, then migrate consumers. Existing `gal_catalog_products`, bags, profile facts, decision snapshots, valuation, longitudinal insight/outcome tables, and release structures are preserved where their concepts remain valid. Legacy driver registries remain read-only migration/source inputs until normalized reconciliation and consumer acceptance prove the new read contracts are safe.

**Tech Stack:** PostgreSQL/Supabase migrations, SQL verification tests, Row Level Security, version-controlled GitHub migrations, Supabase staging + production, existing GAL public-ID and governance conventions.

**Spec:** `docs/superpowers/specs/2026-09-03-gal-equipment-knowledge-schema-gap-design.md`

## Global Constraints

- Staging must contain the complete production schema required for a release before production implementation.
- Production golfer data must not be copied into staging; use sanitized fixtures/reference data only.
- Preserve valid canonical IDs and historical/source records; do not destructively delete legacy equipment data during migration.
- Legacy driver JSON payloads are migration/source inputs, not permanent analytical truth.
- Unknown values remain unknown; migration must not strengthen unsupported evidence or manufacturer marketing claims.
- Target analytical sequence remains `Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`.
- Equipment readiness is use-case specific: `CATALOG_READY`, `GUIDE_READY`, `AI_FIT_LIMITED`, `AI_FIT_READY`.
- Configuration support states remain `FACTORY_STANDARD`, `FACTORY_CUSTOM`, `AFTERMARKET_VALID`, `UNVERIFIED_INVALID`.
- Media and commerce data remain analytically firewalled from candidate ranking.
- Browser clients consume approved read contracts; global Equipment Knowledge writes remain trusted/governed server operations.
- Every migration task must include a RED verification test before implementation, GREEN verification after implementation, staging acceptance, rollback/recovery instructions, and a distinct commit.
- No production promotion occurs in this plan until the explicit final production gate is approved.

---

## File Structure

### Existing paths to preserve
- `supabase/migrations/` — authoritative version-controlled database migrations.
- `supabase/tests/` — SQL verification and security tests.
- `docs/superpowers/specs/2026-09-03-gal-equipment-knowledge-layer-design.md` — locked #4 architecture.
- `docs/superpowers/specs/2026-09-03-gal-equipment-knowledge-schema-gap-design.md` — approved schema-gap design.

### New migration files
- `supabase/migrations/20260904010000_equipment_wave_a_schema_parity.sql`
- `supabase/migrations/20260904011000_equipment_wave_b_canonical_core.sql`
- `supabase/migrations/20260904012000_equipment_wave_b_evidence_ontology.sql`
- `supabase/migrations/20260904013000_equipment_wave_c_configuration_compatibility.sql`
- `supabase/migrations/20260904014000_equipment_wave_c_testing_derivations.sql`
- `supabase/migrations/20260904015000_equipment_wave_c_readiness_governance.sql`
- `supabase/migrations/20260904016000_equipment_media_governance.sql`
- `supabase/migrations/20260904017000_equipment_consumer_views.sql`
- `supabase/migrations/20260904018000_equipment_driver_legacy_normalization.sql`
- `supabase/migrations/20260904019000_equipment_bag_profile_links.sql`
- `supabase/migrations/20260904020000_equipment_security_performance_hardening.sql`

### New SQL verification files
- `supabase/tests/equipment_wave_a_schema_parity.sql`
- `supabase/tests/equipment_canonical_core.sql`
- `supabase/tests/equipment_evidence_ontology.sql`
- `supabase/tests/equipment_configuration_compatibility.sql`
- `supabase/tests/equipment_testing_derivations.sql`
- `supabase/tests/equipment_readiness_governance.sql`
- `supabase/tests/equipment_media_governance.sql`
- `supabase/tests/equipment_consumer_views.sql`
- `supabase/tests/equipment_driver_legacy_normalization.sql`
- `supabase/tests/equipment_bag_profile_links.sql`
- `supabase/tests/equipment_security_performance.sql`
- `supabase/tests/equipment_release_acceptance.sql`

---

### Task 1: Wave A — Establish Schema Parity Baseline Without Copying Golfer Data

**Files:**
- Create: `supabase/tests/equipment_wave_a_schema_parity.sql`
- Create: `supabase/migrations/20260904010000_equipment_wave_a_schema_parity.sql`

**Interfaces:**
- Consumes: existing production definitions of `gal_catalog_products`, `gal_bags`, `gal_bag_items`, `gal_profile_facts`, `gal_decision_snapshots`, `gal_valuation_snapshots`, release tables, and driver registry/source tables.
- Produces: staging-compatible definitions for required legacy/reference structures, preserving names and compatible columns so later normalized migrations can read them safely.

- [ ] **Step 1: Write the RED schema-parity verification test**

Create `supabase/tests/equipment_wave_a_schema_parity.sql` with explicit required-table assertions:

```sql
do $$
declare
  missing text[];
begin
  select array_agg(t)
  into missing
  from unnest(array[
    'gal_catalog_products',
    'gal_bags',
    'gal_bag_items',
    'gal_profile_facts',
    'gal_decision_snapshots',
    'gal_valuation_snapshots',
    'gal_release_registry',
    'gal_release_artifacts',
    'gal_driver_registry',
    'gal_driver_master_registry',
    'gal_driver_sources'
  ]) as t
  where to_regclass('public.' || t) is null;

  if missing is not null then
    raise exception 'equipment schema parity missing tables: %', missing;
  end if;
end $$;
```

Add column assertions for the migration-critical bridge fields:

```sql
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_catalog_products'
      and column_name='canonical_product_id'
  ) then raise exception 'gal_catalog_products.canonical_product_id missing'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_bag_items'
      and column_name='configuration'
  ) then raise exception 'gal_bag_items.configuration missing'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_profile_facts'
      and column_name='fact_key'
  ) then raise exception 'gal_profile_facts.fact_key missing'; end if;
end $$;
```

- [ ] **Step 2: Run the parity test against staging and verify RED**

Run the SQL through the staging Supabase project. Expected: failure identifying the catalog/bag/profile/legacy equipment tables currently absent from staging.

- [ ] **Step 3: Capture exact production DDL before writing parity migration**

Use read-only catalog queries against production for each required table, enum, index, FK, trigger, RLS policy, and supporting function. Compare against Git migration history. The migration must reproduce the current required schema, not reconstruct it from memory or copy production rows.

Required inventory query:

```sql
select table_name, column_name, data_type, udt_name, is_nullable, column_default
from information_schema.columns
where table_schema='public'
  and table_name in (
    'gal_catalog_products','gal_bags','gal_bag_items','gal_profile_facts',
    'gal_decision_snapshots','gal_valuation_snapshots','gal_release_registry',
    'gal_release_artifacts','gal_driver_registry','gal_driver_master_registry',
    'gal_driver_sources'
  )
order by table_name, ordinal_position;
```

Also inventory constraints/indexes/policies before implementing.

- [ ] **Step 4: Implement the non-destructive schema-parity migration**

Create `20260904010000_equipment_wave_a_schema_parity.sql` using `create table if not exists`, guarded enum/type creation, indexes/FKs/policies matching the production baseline, and no `insert ... select` from production data. Existing staging objects must remain untouched when already compatible.

- [ ] **Step 5: Add sanitized fixture rows only where later tests require data**

Use deterministic test IDs and clearly synthetic names such as `GAL-TEST-PRODUCT-001`; never use production golfer IDs, bag rows, profile facts, or purchase history.

- [ ] **Step 6: Run RED→GREEN parity verification**

Run `equipment_wave_a_schema_parity.sql` in staging. Expected: PASS. Then compare table/column/constraint fingerprints between production and staging for the reconciled legacy structures.

- [ ] **Step 7: Rollback/recovery check**

Because Wave A is additive, recovery is: restore staging from branch reset or explicitly drop only objects newly created by this migration in a disposable verification branch. Do not drop production objects.

- [ ] **Step 8: Commit**

```bash
git add supabase/migrations/20260904010000_equipment_wave_a_schema_parity.sql supabase/tests/equipment_wave_a_schema_parity.sql
git commit -m "feat: establish equipment schema parity baseline"
```

---

### Task 2: Wave B — Add Canonical Equipment Family, Variant, Component, Alias, and Lifecycle Core

**Files:**
- Create: `supabase/tests/equipment_canonical_core.sql`
- Create: `supabase/migrations/20260904011000_equipment_wave_b_canonical_core.sql`

**Interfaces:**
- Consumes: existing `gal_catalog_products.canonical_product_id`, `canonical_brand_id`, category and display identity.
- Produces: normalized stable identities used by all later evidence/configuration/readiness tables.

- [ ] **Step 1: Write RED structural tests**

Assert these new tables do not yet exist and then define expected PK/FK relationships:

```sql
do $$
begin
  if to_regclass('public.gal_equipment_families') is null then
    raise exception 'gal_equipment_families missing';
  end if;
  if to_regclass('public.gal_equipment_variants') is null then
    raise exception 'gal_equipment_variants missing';
  end if;
  if to_regclass('public.gal_equipment_components') is null then
    raise exception 'gal_equipment_components missing';
  end if;
  if to_regclass('public.gal_equipment_aliases') is null then
    raise exception 'gal_equipment_aliases missing';
  end if;
  if to_regclass('public.gal_equipment_lifecycle_events') is null then
    raise exception 'gal_equipment_lifecycle_events missing';
  end if;
end $$;
```

- [ ] **Step 2: Verify RED on staging**

Expected: failure at `gal_equipment_families missing`.

- [ ] **Step 3: Implement normalized identity tables**

Create tables with these minimum columns and invariants:

```sql
create table public.gal_equipment_families (
  id uuid primary key default gen_random_uuid(),
  equipment_family_id text not null unique default gal_public_id('GAL-EQF'),
  canonical_brand_id text not null,
  canonical_product_id text,
  category text not null,
  family_name text not null,
  lifecycle_state text not null check (lifecycle_state in ('ANNOUNCED','CURRENT','PRIOR_GENERATION','DISCONTINUED','HISTORICAL')),
  source_dataset text,
  source_dataset_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.gal_equipment_variants (
  id uuid primary key default gen_random_uuid(),
  equipment_variant_id text not null unique default gal_public_id('GAL-EQV'),
  family_id uuid not null references public.gal_equipment_families(id),
  variant_key text not null,
  display_name text not null,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, variant_key, effective_from)
);

create table public.gal_equipment_components (
  id uuid primary key default gen_random_uuid(),
  equipment_component_id text not null unique default gal_public_id('GAL-EQC'),
  component_type text not null,
  manufacturer_key text,
  display_name text not null,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Add alias and lifecycle-event tables with unique identity mappings and effective dates. Do not yet deprecate `gal_catalog_products`.

- [ ] **Step 4: Add indexes for canonical lookup**

At minimum: family by `(canonical_brand_id, category)`, family by `canonical_product_id`, variant by `family_id`, aliases by normalized alias key, lifecycle by entity/effective date.

- [ ] **Step 5: Seed only identity mappings from existing catalog records**

Map `gal_catalog_products` into families conservatively. Where family/variant split is ambiguous, create only the family and leave variant unresolved rather than guessing.

- [ ] **Step 6: Verify GREEN and identity preservation**

Assert every migrated row retains the original `canonical_product_id` where one exists, and no legacy canonical ID maps to multiple families unless explicitly documented as a conflict.

- [ ] **Step 7: Commit**

```bash
git add supabase/migrations/20260904011000_equipment_wave_b_canonical_core.sql supabase/tests/equipment_canonical_core.sql
git commit -m "feat: add canonical equipment identity core"
```

---

### Task 3: Wave B — Add Equipment Ontology, Sources, Attribute Evidence, Conflicts, and Approved Characteristics

**Files:**
- Create: `supabase/tests/equipment_evidence_ontology.sql`
- Create: `supabase/migrations/20260904012000_equipment_wave_b_evidence_ontology.sql`

**Interfaces:**
- Consumes: canonical family/variant/component identities from Task 2.
- Produces: attribute-level provenance and approved analytical characteristics for fitting/readiness.

- [ ] **Step 1: Write RED tests for required structures and support states**

Require:
`gal_equipment_attribute_definitions`, `gal_equipment_sources`, `gal_equipment_observations`, `gal_equipment_conflicts`, `gal_equipment_characteristics`.

Test evidence classes exactly:

```sql
select 1
where not exists (
  select 1
  from unnest(array['PUBLISHED_SPECIFICATION','GAL_MEASURED','INDEPENDENT_OBSERVED','GAL_DERIVED']) v
  where v not in ('PUBLISHED_SPECIFICATION','GAL_MEASURED','INDEPENDENT_OBSERVED','GAL_DERIVED')
);
```

Use table CHECK constraints to enforce the same state values.

- [ ] **Step 2: Verify RED**

Expected: missing evidence tables.

- [ ] **Step 3: Implement ontology and source tables**

Attribute definitions must include `attribute_key`, category/use scope, value type/unit metadata, fitting relevance, and active/version metadata. Sources must include source type, provider/reference, observed/published dates, license/use metadata where relevant, and raw source reference.

- [ ] **Step 4: Implement append-oriented observations**

Each observation must identify exactly one governed subject (family, variant, component, configuration later via nullable mutually-exclusive FKs or a validated subject-type/key pair), attribute definition, value JSON, unit, evidence class, source, observed/effective time, claim state, and review status.

Claim states are `KNOWN`, `DERIVED`, `UNKNOWN_INSUFFICIENT_EVIDENCE`.

- [ ] **Step 5: Implement conflicts and approved characteristics**

Conflicts preserve competing observation IDs. Approved characteristics contain the production-facing selected/derived value, methodology version where derived, evidence references, effective interval, governance status, and supersession lineage. No newest-record-wins trigger is allowed.

- [ ] **Step 6: Add immutability guard for approved source observations**

Validated observations must not be overwritten. Corrections use supersession/correction records.

- [ ] **Step 7: GREEN verification**

Tests must prove two conflicting observations can coexist and that one cannot silently overwrite the other.

- [ ] **Step 8: Commit**

```bash
git add supabase/migrations/20260904012000_equipment_wave_b_evidence_ontology.sql supabase/tests/equipment_evidence_ontology.sql
git commit -m "feat: add governed equipment evidence ontology"
```

---

### Task 4: Wave C — Add Governed Configurations and Compatibility Rules

**Files:**
- Create: `supabase/tests/equipment_configuration_compatibility.sql`
- Create: `supabase/migrations/20260904013000_equipment_wave_c_configuration_compatibility.sql`

**Interfaces:**
- Consumes: variants/components and approved characteristics.
- Produces: validated configuration identities and compatibility rules used by AI Fitting and My Bag exact-build references.

- [ ] **Step 1: RED tests**

Require `gal_equipment_configurations`, `gal_equipment_configuration_components`, `gal_equipment_configuration_settings`, `gal_equipment_compatibility_rules`, and `gal_equipment_dependency_rules`.

- [ ] **Step 2: Implement configuration tables**

A configuration must include:

```sql
support_state text not null check (
  support_state in ('FACTORY_STANDARD','FACTORY_CUSTOM','AFTERMARKET_VALID','UNVERIFIED_INVALID')
)
```

A configuration may not be recommendation-eligible when `support_state='UNVERIFIED_INVALID'`.

- [ ] **Step 3: Implement hard compatibility rules**

Rules identify subject/component types, predicate/operator/value, effective period, source/evidence reference, and rule version. Unknown compatibility must return non-eligible, not eligible-by-default.

- [ ] **Step 4: Implement dependent-effect rules**

Represent known downstream effects such as loft/lie/face changes, shaft-length effects, iron bend/bounce effects, and wedge loft/bounce effects as structured rule records with evidence references.

- [ ] **Step 5: GREEN tests**

Insert one synthetic valid factory configuration and one invalid combination. Assert only the valid configuration enters the eligibility read set.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260904013000_equipment_wave_c_configuration_compatibility.sql supabase/tests/equipment_configuration_compatibility.sql
git commit -m "feat: add equipment configuration compatibility model"
```

---

### Task 5: Wave C — Add Physical Samples, Test Sessions, Observations, Exclusions, and Derivations

**Files:**
- Create: `supabase/tests/equipment_testing_derivations.sql`
- Create: `supabase/migrations/20260904014000_equipment_wave_c_testing_derivations.sql`

**Interfaces:**
- Consumes: canonical equipment/configuration identities and ontology attributes.
- Produces: traceable GAL-measured evidence and derived equipment characteristics.

- [ ] **Step 1: RED tests**

Require the chain:
`gal_equipment_samples` → `gal_equipment_tested_configurations` → `gal_equipment_test_sessions` → `gal_equipment_test_observations` plus `gal_equipment_test_exclusions` and `gal_equipment_derivations`.

- [ ] **Step 2: Implement physical sample records**

Preserve sample identity, linked variant/component, acquisition/source, condition, serial/lot when appropriate, measured physical properties, and disposition/history.

- [ ] **Step 3: Implement tested configuration snapshots**

Freeze exact assembly/settings used in testing. A fitting-relevant material change requires a new tested-configuration row.

- [ ] **Step 4: Implement session and observation records**

Sessions preserve date/facility/tester-or-robot/instrumentation/calibration/environment/protocol version. Observations are append-only after validation and reference the applicable ontology attribute.

- [ ] **Step 5: Implement exclusion and derivation lineage**

Excluded runs remain auditable. Derivations must reference contributing observation IDs, methodology/aggregation version, sample/configuration context, effective date, and scope-of-generalization.

- [ ] **Step 6: GREEN generalization test**

Create a single-sample synthetic observation and assert no family-wide approved characteristic is generated unless the derivation explicitly records an approved generalization methodology.

- [ ] **Step 7: Commit**

```bash
git add supabase/migrations/20260904014000_equipment_wave_c_testing_derivations.sql supabase/tests/equipment_testing_derivations.sql
git commit -m "feat: add governed equipment testing evidence chain"
```

---

### Task 6: Wave C — Add Use-Case Readiness Policies, States, and Evidence Gap Queue

**Files:**
- Create: `supabase/tests/equipment_readiness_governance.sql`
- Create: `supabase/migrations/20260904015000_equipment_wave_c_readiness_governance.sql`

**Interfaces:**
- Consumes: approved characteristics, configurations, category/use-case ontology requirements.
- Produces: readiness evaluation and explicit blockers for Guide/AI Fit eligibility.

- [ ] **Step 1: RED tests**

Require `gal_equipment_readiness_policies`, `gal_equipment_readiness_requirements`, `gal_equipment_readiness_state`, `gal_equipment_evidence_gaps`, and readiness-evaluation history.

- [ ] **Step 2: Implement readiness policy model**

Requirements classify attributes as `REQUIRED`, `CONDITIONALLY_REQUIRED`, or `OPTIONAL` by category + use case + policy version.

- [ ] **Step 3: Implement readiness states**

```sql
check (readiness_state in ('CATALOG_READY','GUIDE_READY','AI_FIT_LIMITED','AI_FIT_READY'))
```

Readiness state records must preserve evaluation timestamp, policy version, evidence snapshot/version, and blocking gap count.

- [ ] **Step 4: Implement Evidence Gap Queue**

Each gap records equipment/configuration, desired use-case/readiness target, missing attribute/evidence requirement, priority/materiality, recommended research/test action, state, and timestamps. The queue does not itself change readiness.

- [ ] **Step 5: GREEN behavior tests**

Synthetic driver missing required spin evidence must not become `AI_FIT_READY`. Adding qualifying governed spin evidence and re-evaluating may advance the readiness state.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260904015000_equipment_wave_c_readiness_governance.sql supabase/tests/equipment_readiness_governance.sql
git commit -m "feat: add equipment readiness governance"
```

---

### Task 7: Add Equipment Media Rights/Provenance Registry With Analytical Firewall

**Files:**
- Create: `supabase/tests/equipment_media_governance.sql`
- Create: `supabase/migrations/20260904016000_equipment_media_governance.sql`

**Interfaces:**
- Consumes: canonical equipment/sample/configuration identities.
- Produces: governed presentation assets only; no analytical dependency.

- [ ] **Step 1: RED tests**

Require `gal_equipment_media_assets` and rights states:
`GAL_OWNED`, `MANUFACTURER_AUTHORIZED`, `PARTNER_LICENSED`, `PUBLIC_REFERENCE_ONLY`, `UNVERIFIED_RIGHTS`.

- [ ] **Step 2: Implement asset provenance**

Store entity/sample linkage, media role, source/provider, rights state, approved surfaces/use scope, attribution/crop/transform permissions, territory/channel restrictions, effective/expiration dates, approval state and supersession lineage.

- [ ] **Step 3: Implement production eligibility view**

Only assets with valid golfer-facing rights may enter `gal_equipment_media_production_v`.

- [ ] **Step 4: Verify analytical firewall**

Readiness and candidate-match queries must not join media tables. Add SQL dependency inspection asserting the readiness views/functions do not reference `gal_equipment_media_assets`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260904016000_equipment_media_governance.sql supabase/tests/equipment_media_governance.sql
git commit -m "feat: add governed equipment media registry"
```

---

### Task 8: Create Shared Approved Consumer Views for Buyers Guides and AI Fitting

**Files:**
- Create: `supabase/tests/equipment_consumer_views.sql`
- Create: `supabase/migrations/20260904017000_equipment_consumer_views.sql`

**Interfaces:**
- Consumes: canonical equipment, approved characteristics, valid configurations, readiness, media eligibility.
- Produces: one approved equipment truth exposed at different detail levels.

- [ ] **Step 1: RED tests**

Require at least:
- `gal_equipment_guide_v`
- `gal_equipment_ai_fit_v`
- `gal_equipment_detail_v`

- [ ] **Step 2: Implement Guide view**

Only include `GUIDE_READY` or stronger entities for normal analytical guide inclusion. Return canonical IDs, approved display identity, approved characteristics safe for public guide use, eligible media refs, and no private golfer data.

- [ ] **Step 3: Implement AI Fit view**

Return candidate configurations, approved characteristics, evidence/claim states needed for fitting, readiness state, and explicit limited-evidence markers. Do not expose commerce commission fields.

- [ ] **Step 4: Prove one-truth consistency**

For a synthetic product in both views, assert shared canonical facts (product identity, category, approved launch/spin class, lifecycle) are identical. Differences are allowed only in detail/scope, not contradictory equipment facts.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260904017000_equipment_consumer_views.sql supabase/tests/equipment_consumer_views.sql
git commit -m "feat: add shared equipment consumer views"
```

---

### Task 9: Wave D — Normalize Legacy Driver Registry Data Into the New Knowledge Layer

**Files:**
- Create: `supabase/tests/equipment_driver_legacy_normalization.sql`
- Create: `supabase/migrations/20260904018000_equipment_driver_legacy_normalization.sql`

**Interfaces:**
- Consumes: `gal_driver_registry`, `gal_driver_master_registry`, `gal_driver_sources`, existing `gal_catalog_products` and new normalized core.
- Produces: conservative identity/evidence mappings while legacy tables remain intact.

- [ ] **Step 1: RED reconciliation tests**

Capture pre-migration legacy counts and canonical IDs. Assert each eligible driver row has either a normalized family mapping or an explicit unresolved-mapping record; silent drops are forbidden.

- [ ] **Step 2: Implement deterministic identity mapping**

Use canonical product/brand IDs first. Do not infer variant/component identity from marketing text when ambiguous. Record unresolved mappings in a dedicated migration reconciliation table.

- [ ] **Step 3: Parse only governed payload fields**

Move factual identity/specification values into source observations with source provenance. Do not convert marketing adjectives or unsupported payload claims into approved characteristics.

- [ ] **Step 4: Preserve source payload lineage**

Every normalized legacy observation must reference its original legacy table/key/release version or source record.

- [ ] **Step 5: GREEN reconciliation tests**

Assert:
- legacy row count = normalized mappings + explicitly unresolved rows;
- no duplicate canonical product identity introduced;
- legacy tables still exist and are readable;
- no legacy table is yet removed from rollback path.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260904018000_equipment_driver_legacy_normalization.sql supabase/tests/equipment_driver_legacy_normalization.sql
git commit -m "feat: normalize legacy driver equipment data"
```

---

### Task 10: Link My Bag and Profile Continuity Without Replacing Golfer-Owned Tables

**Files:**
- Create: `supabase/tests/equipment_bag_profile_links.sql`
- Create: `supabase/migrations/20260904019000_equipment_bag_profile_links.sql`

**Interfaces:**
- Consumes: `gal_bag_items`, `gal_profile_facts`, normalized equipment configurations.
- Produces: optional governed configuration links and preserved Tell GAL Once semantics.

- [ ] **Step 1: RED tests**

Require an optional governed configuration FK/reference on `gal_bag_items` while preserving existing JSON `configuration` for transitional snapshots.

- [ ] **Step 2: Add configuration linkage non-destructively**

Add nullable `equipment_configuration_id uuid` referencing `gal_equipment_configurations(id)`. Do not drop or reinterpret existing `configuration` JSON.

- [ ] **Step 3: Preserve existing profile-fact model**

Do not replace `gal_profile_facts`. Add only source/reference conventions needed for Buyers Guide → authenticated Tell GAL Once reuse and equipment fitting provenance.

- [ ] **Step 4: GREEN tests**

Assert legacy bag items without an exact known build remain valid with null governed configuration ID; exact synthetic builds can reference the new configuration table.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260904019000_equipment_bag_profile_links.sql supabase/tests/equipment_bag_profile_links.sql
git commit -m "feat: link My Bag to governed equipment configurations"
```

---

### Task 11: Apply RLS, Privilege Boundaries, Indexing, and Performance Hardening

**Files:**
- Create: `supabase/tests/equipment_security_performance.sql`
- Create: `supabase/migrations/20260904020000_equipment_security_performance_hardening.sql`

**Interfaces:**
- Consumes: all new Equipment Knowledge structures.
- Produces: explicit browser-safe reads, trusted writes, protected golfer-owned rows, and indexed fitting/readiness queries.

- [ ] **Step 1: RED privilege tests**

Test that anonymous/authenticated browser roles cannot directly mutate global Equipment Knowledge tables and cannot access internal raw observations/conflicts/testing governance unless explicitly exposed by approved views.

- [ ] **Step 2: Apply RLS and grants**

Global/internal tables: RLS enabled with explicit-deny browser policies or no browser grants; service/trusted paths only for mutation. Public Guide views receive only intended anonymous SELECT grants. Golfer-owned bag/profile records retain golfer-scoped RLS.

- [ ] **Step 3: Add FK and lookup indexes**

Index all high-value FK columns and common match keys: family/variant/component IDs, attribute IDs, configuration membership, readiness `(entity/use_case/state)`, evidence source, effective-date lookup and mapping/reconciliation keys.

- [ ] **Step 4: Run query-plan checks**

Use `EXPLAIN (ANALYZE, BUFFERS)` on representative Guide lookup, AI Fit candidate/readiness lookup, My Bag equipment detail and legacy reconciliation queries using staging fixtures. Record regressions before promotion.

- [ ] **Step 5: Run Supabase advisors/security checks**

No new exposed mutable table, missing RLS, avoidable FK-without-index, or security-definer/search-path regression is accepted.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260904020000_equipment_security_performance_hardening.sql supabase/tests/equipment_security_performance.sql
git commit -m "chore: harden equipment knowledge security and performance"
```

---

### Task 12: Full Staging Acceptance, Consumer Cutover Gate, Rollback Smoke Test, and Production Release Gate

**Files:**
- Create: `supabase/tests/equipment_release_acceptance.sql`
- Modify only after approval: public Buyers Guide / portal data-contract files identified during implementation; do not guess or change those files before Task 12 review.

**Interfaces:**
- Consumes: complete schema and normalized driver data from Tasks 1–11.
- Produces: evidence that the new Equipment Knowledge layer is safe for controlled consumer cutover; does not itself authorize production release.

- [ ] **Step 1: Write end-to-end acceptance SQL**

The acceptance test must assert:
- all new tables/views exist;
- staging contains required legacy compatibility schema;
- no production golfer fixture IDs exist in staging;
- legacy driver counts reconcile to normalized + unresolved mappings;
- shared canonical facts are equal across Guide/AI Fit views;
- `GUIDE_READY` gates Guide normal inclusion;
- missing required evidence blocks `AI_FIT_READY`;
- invalid/unverified configurations are excluded from fitting candidates;
- raw evidence/conflict/testing tables are not browser-writable;
- legacy registries still exist for rollback.

- [ ] **Step 2: Run all equipment SQL tests in staging**

Run every new `supabase/tests/equipment_*.sql` file plus existing longitudinal/security tests. Expected: all PASS.

- [ ] **Step 3: Run two-user RLS acceptance**

Verify two authenticated synthetic users cannot read or mutate each other's bag/profile/fitting-owned records, while both can consume the same approved global Equipment Knowledge read contracts.

- [ ] **Step 4: Run consumer equivalence rehearsal before cutover**

For existing Driver Buyers Guide fixture cases, compare legacy output inputs versus new governed view inputs. Differences must be classified as:
- expected normalization correction;
- evidence-governance narrowing;
- unresolved data gap;
- defect.

No unexplained difference is accepted.

- [ ] **Step 5: Run rollback smoke test in staging**

Repoint the consumer rehearsal to legacy registry/read path without deleting the new schema. Verify old behavior remains recoverable. Then switch back to new approved views. This proves rollback does not require destructive data reversal.

- [ ] **Step 6: Review gate before any production consumer switch**

Present:
- migration list and commit SHAs;
- staging schema fingerprint;
- all test results;
- reconciliation counts;
- RLS/security checks;
- performance results;
- Guide equivalence/difference report;
- rollback smoke-test results;
- unresolved Evidence Gap Queue items.

Do not apply production migrations or switch public/authenticated consumers until explicit user approval.

- [ ] **Step 7: Production migration sequence after explicit approval only**

Apply the exact staging-verified migration sequence in order. Re-run release acceptance in production using read-only/non-destructive checks. Do not seed staging fixtures into production. Do not retire legacy analytical authority until consumer verification succeeds.

- [ ] **Step 8: Production post-release gate**

Verify Buyers Guides, authenticated AI Fitting/My Bag read contracts, longitudinal links, RLS, advisors, performance, and rollback route. Only then mark legacy driver registries `READ_ONLY_LEGACY_SOURCE` or equivalent governance status; do not delete them.

- [ ] **Step 9: Commit acceptance test and release evidence references**

```bash
git add supabase/tests/equipment_release_acceptance.sql
git commit -m "test: add equipment knowledge release acceptance gate"
```

---

## Self-Review

### 1. Spec coverage
- Evolution-not-replacement: Tasks 1, 2, 9, 10.
- Staging/production schema parity: Tasks 1 and 12.
- Canonical Product Family → Variant → Component: Task 2.
- Attribute-level evidence/provenance/conflicts/effective dating: Task 3.
- Compatibility and dependent effects: Task 4.
- Physical samples/test sessions/observations/derivations: Task 5.
- Use-case-specific readiness and Evidence Gap Queue: Task 6.
- Media rights and analytical firewall: Task 7.
- One equipment truth for Guide + AI Fit: Task 8.
- Legacy driver normalization without deletion: Task 9.
- Preserve My Bag and Tell GAL Once foundations: Task 10.
- RLS/security/performance: Task 11.
- Staging acceptance/rollback/production gate: Task 12.
- Production golfer-data isolation: Tasks 1 and 12 plus Global Constraints.

No approved schema-gap requirement is intentionally omitted.

### 2. Placeholder scan
The plan contains no `TBD`, `TODO`, "implement later", or unspecified generic test steps. Task 12 intentionally delays identification of consumer application files until the schema is staged because those file paths are consumer-specific implementation details and changing them before the data contract exists would violate the migration gate; the task explicitly requires identification during execution before modification.

### 3. Type and naming consistency
- Canonical IDs remain text public IDs plus UUID internal PKs, matching existing GAL conventions.
- `gal_equipment_families`, `gal_equipment_variants`, `gal_equipment_components`, `gal_equipment_configurations` are used consistently across later tasks.
- Readiness states use the locked four-state vocabulary.
- Compatibility states use `UNVERIFIED_INVALID` as the SQL-safe spelling of the locked `UNVERIFIED / INVALID` concept.
- Evidence classes and claim states remain stable through evidence, testing, readiness and consumer views.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-09-03-gal-equipment-knowledge-schema-migration.md`.

Two execution options after review:

1. **Subagent-Driven (recommended)** — execute one independently reviewable task at a time, with review between tasks.
2. **Inline Execution** — execute the plan in this session in controlled batches with checkpoints.

No implementation begins until the plan is reviewed/approved.