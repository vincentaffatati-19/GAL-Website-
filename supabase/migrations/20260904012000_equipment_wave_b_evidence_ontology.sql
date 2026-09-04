-- GAL Equipment Knowledge Wave B: governed ontology, sources, evidence, conflicts, approved characteristics

create table if not exists public.gal_equipment_attribute_definitions (
  id uuid primary key default gen_random_uuid(),
  equipment_attribute_id text not null unique default gal_public_id('GAL-EAT'),
  attribute_key text not null,
  category text,
  use_scope text not null default 'GLOBAL',
  value_type text not null,
  default_unit text,
  fitting_relevance text not null default 'OPTIONAL' check (fitting_relevance in ('REQUIRED','CONDITIONALLY_REQUIRED','OPTIONAL')),
  definition_version text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct(attribute_key,category,use_scope,definition_version)
);

create table if not exists public.gal_equipment_sources (
  id uuid primary key default gen_random_uuid(),
  equipment_source_id text not null unique default gal_public_id('GAL-ESR'),
  source_type text not null check (source_type in ('MANUFACTURER','GAL_TEST','INDEPENDENT','PARTNER','LEGACY_DATASET','MANUAL_RESEARCH')),
  provider_name text,
  source_reference text,
  raw_source_reference text,
  published_at timestamptz,
  observed_at timestamptz,
  license_scope text,
  rights_state text,
  source_version text,
  created_at timestamptz not null default now()
);

create table if not exists public.gal_equipment_observations (
  id uuid primary key default gen_random_uuid(),
  equipment_observation_id text not null unique default gal_public_id('GAL-EOB'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  component_id uuid references public.gal_equipment_components(id),
  attribute_definition_id uuid not null references public.gal_equipment_attribute_definitions(id),
  source_id uuid not null references public.gal_equipment_sources(id),
  value_json jsonb,
  unit text,
  evidence_class text not null check (evidence_class in ('PUBLISHED_SPECIFICATION','GAL_MEASURED','INDEPENDENT_OBSERVED','GAL_DERIVED')),
  claim_state text not null check (claim_state in ('KNOWN','DERIVED','UNKNOWN_INSUFFICIENT_EVIDENCE')),
  review_status text not null default 'INGESTED' check (review_status in ('INGESTED','NORMALIZED','VALIDATED','REVIEW_PENDING','APPROVED','PRODUCTION','CONFLICT','REJECTED','STALE','RETIRED')),
  methodology_version text,
  observed_at timestamptz not null default now(),
  effective_from timestamptz,
  effective_to timestamptz,
  supersedes_observation_id uuid references public.gal_equipment_observations(id),
  created_at timestamptz not null default now(),
  check ((((family_id is not null)::int)+((variant_id is not null)::int)+((component_id is not null)::int))=1)
);

create table if not exists public.gal_equipment_conflicts (
  id uuid primary key default gen_random_uuid(),
  equipment_conflict_id text not null unique default gal_public_id('GAL-ECF'),
  attribute_definition_id uuid not null references public.gal_equipment_attribute_definitions(id),
  observation_a_id uuid not null references public.gal_equipment_observations(id),
  observation_b_id uuid not null references public.gal_equipment_observations(id),
  status text not null default 'OPEN' check (status in ('OPEN','RESOLVED','WITHHELD')),
  resolution_method text,
  resolution_note text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check (observation_a_id <> observation_b_id),
  unique(observation_a_id,observation_b_id)
);

create table if not exists public.gal_equipment_characteristics (
  id uuid primary key default gen_random_uuid(),
  equipment_characteristic_id text not null unique default gal_public_id('GAL-ECH'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  component_id uuid references public.gal_equipment_components(id),
  attribute_definition_id uuid not null references public.gal_equipment_attribute_definitions(id),
  value_json jsonb,
  unit text,
  claim_state text not null check (claim_state in ('KNOWN','DERIVED','UNKNOWN_INSUFFICIENT_EVIDENCE')),
  methodology_version text,
  evidence_observation_ids uuid[] not null default '{}'::uuid[],
  governance_status text not null default 'DRAFT' check (governance_status in ('DRAFT','REVIEW_PENDING','APPROVED','PRODUCTION','RETIRED')),
  effective_from timestamptz,
  effective_to timestamptz,
  supersedes_characteristic_id uuid references public.gal_equipment_characteristics(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((((family_id is not null)::int)+((variant_id is not null)::int)+((component_id is not null)::int))=1)
);

create index if not exists gal_equipment_attr_key_idx on public.gal_equipment_attribute_definitions(attribute_key,category,use_scope);
create index if not exists gal_equipment_obs_subject_idx on public.gal_equipment_observations(family_id,variant_id,component_id,attribute_definition_id);
create index if not exists gal_equipment_obs_source_idx on public.gal_equipment_observations(source_id,observed_at desc);
create index if not exists gal_equipment_char_subject_idx on public.gal_equipment_characteristics(family_id,variant_id,component_id,attribute_definition_id,governance_status);
create index if not exists gal_equipment_conflicts_status_idx on public.gal_equipment_conflicts(status,attribute_definition_id);

create or replace function public.gal_guard_equipment_observation_immutability()
returns trigger language plpgsql set search_path=public as $$
begin
  if old.review_status in ('VALIDATED','REVIEW_PENDING','APPROVED','PRODUCTION') then
    raise exception 'validated equipment observations are immutable; create a superseding observation';
  end if;
  return new;
end $$;

drop trigger if exists gal_equipment_observation_immutability on public.gal_equipment_observations;
create trigger gal_equipment_observation_immutability before update or delete on public.gal_equipment_observations for each row execute function public.gal_guard_equipment_observation_immutability();

alter table public.gal_equipment_attribute_definitions enable row level security;
alter table public.gal_equipment_sources enable row level security;
alter table public.gal_equipment_observations enable row level security;
alter table public.gal_equipment_conflicts enable row level security;
alter table public.gal_equipment_characteristics enable row level security;

do $$ declare t text; begin
  foreach t in array array['gal_equipment_attribute_definitions','gal_equipment_sources','gal_equipment_observations','gal_equipment_conflicts','gal_equipment_characteristics'] loop
    if not exists (select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)',t);
    end if;
  end loop;
end $$;
