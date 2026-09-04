-- GAL Equipment Knowledge Wave C: physical samples, testing, observations, exclusions, derivations

create table if not exists public.gal_equipment_samples (
  id uuid primary key default gen_random_uuid(),
  equipment_sample_id text not null unique default gal_public_id('GAL-ESM'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  component_id uuid references public.gal_equipment_components(id),
  serial_or_lot text,
  acquisition_source text,
  acquired_at timestamptz,
  condition_state text,
  measured_properties jsonb not null default '{}'::jsonb,
  disposition_state text,
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((((family_id is not null)::int)+((variant_id is not null)::int)+((component_id is not null)::int))=1)
);

create table if not exists public.gal_equipment_tested_configurations (
  id uuid primary key default gen_random_uuid(),
  equipment_tested_configuration_id text not null unique default gal_public_id('GAL-ETC'),
  sample_id uuid not null references public.gal_equipment_samples(id),
  configuration_id uuid references public.gal_equipment_configurations(id),
  assembly_snapshot jsonb not null,
  settings_snapshot jsonb not null default '{}'::jsonb,
  configuration_hash text not null,
  created_at timestamptz not null default now(),
  unique(sample_id,configuration_hash)
);

create table if not exists public.gal_equipment_test_sessions (
  id uuid primary key default gen_random_uuid(),
  equipment_test_session_id text not null unique default gal_public_id('GAL-ETS'),
  tested_configuration_id uuid not null references public.gal_equipment_tested_configurations(id),
  started_at timestamptz not null,
  ended_at timestamptz,
  facility text,
  tester_or_robot text,
  instrumentation jsonb not null default '{}'::jsonb,
  calibration jsonb not null default '{}'::jsonb,
  environment jsonb not null default '{}'::jsonb,
  protocol_version text not null,
  anomalies jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.gal_equipment_test_observations (
  id uuid primary key default gen_random_uuid(),
  equipment_test_observation_id text not null unique default gal_public_id('GAL-ETO'),
  test_session_id uuid not null references public.gal_equipment_test_sessions(id),
  attribute_definition_id uuid not null references public.gal_equipment_attribute_definitions(id),
  value_json jsonb,
  unit text,
  run_index integer check (run_index is null or run_index >= 1),
  validation_status text not null default 'RAW' check (validation_status in ('RAW','VALIDATED','EXCLUDED','SUPERSEDED')),
  observed_at timestamptz not null default now(),
  supersedes_observation_id uuid references public.gal_equipment_test_observations(id),
  created_at timestamptz not null default now()
);

create table if not exists public.gal_equipment_test_exclusions (
  id uuid primary key default gen_random_uuid(),
  test_observation_id uuid not null references public.gal_equipment_test_observations(id),
  exclusion_reason text not null,
  governing_protocol_rule text,
  actor_reference text,
  excluded_at timestamptz not null default now(),
  unique(test_observation_id)
);

create table if not exists public.gal_equipment_derivations (
  id uuid primary key default gen_random_uuid(),
  equipment_derivation_id text not null unique default gal_public_id('GAL-EDV'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  configuration_id uuid references public.gal_equipment_configurations(id),
  attribute_definition_id uuid not null references public.gal_equipment_attribute_definitions(id),
  contributing_observation_ids uuid[] not null,
  methodology_version text not null,
  aggregation_version text,
  derived_value jsonb,
  unit text,
  generalization_scope text not null check (generalization_scope in ('SAMPLE','CONFIGURATION','VARIANT','FAMILY')),
  approved_generalization_methodology boolean not null default false,
  effective_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (generalization_scope <> 'FAMILY' or approved_generalization_methodology=true)
);

create index if not exists gal_equipment_samples_variant_idx on public.gal_equipment_samples(variant_id);
create index if not exists gal_equipment_tested_config_config_idx on public.gal_equipment_tested_configurations(configuration_id);
create index if not exists gal_equipment_test_sessions_config_idx on public.gal_equipment_test_sessions(tested_configuration_id,started_at desc);
create index if not exists gal_equipment_test_obs_session_idx on public.gal_equipment_test_observations(test_session_id,attribute_definition_id);
create index if not exists gal_equipment_derivations_subject_idx on public.gal_equipment_derivations(family_id,variant_id,configuration_id,attribute_definition_id);

create or replace function public.gal_guard_test_observation_immutability()
returns trigger language plpgsql set search_path=public as $$
begin
  if old.validation_status='VALIDATED' then
    raise exception 'validated test observations are immutable; supersede instead';
  end if;
  return new;
end $$;

drop trigger if exists gal_equipment_test_observation_immutability on public.gal_equipment_test_observations;
create trigger gal_equipment_test_observation_immutability before update or delete on public.gal_equipment_test_observations for each row execute function public.gal_guard_test_observation_immutability();

alter table public.gal_equipment_samples enable row level security;
alter table public.gal_equipment_tested_configurations enable row level security;
alter table public.gal_equipment_test_sessions enable row level security;
alter table public.gal_equipment_test_observations enable row level security;
alter table public.gal_equipment_test_exclusions enable row level security;
alter table public.gal_equipment_derivations enable row level security;

do $$ declare t text; begin
  foreach t in array array['gal_equipment_samples','gal_equipment_tested_configurations','gal_equipment_test_sessions','gal_equipment_test_observations','gal_equipment_test_exclusions','gal_equipment_derivations'] loop
    if not exists (select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)',t);
    end if;
  end loop;
end $$;
