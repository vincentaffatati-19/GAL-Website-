-- GAL Equipment Knowledge Wave C: configurations and compatibility

create table if not exists public.gal_equipment_configurations (
  id uuid primary key default gen_random_uuid(),
  equipment_configuration_id text not null unique default gal_public_id('GAL-ECG'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  configuration_key text not null,
  display_name text,
  support_state text not null check (support_state in ('FACTORY_STANDARD','FACTORY_CUSTOM','AFTERMARKET_VALID','UNVERIFIED_INVALID')),
  source_reference text,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (family_id is not null or variant_id is not null),
  unique nulls not distinct (family_id,variant_id,configuration_key,effective_from)
);

create table if not exists public.gal_equipment_configuration_components (
  id uuid primary key default gen_random_uuid(),
  configuration_id uuid not null references public.gal_equipment_configurations(id) on delete cascade,
  component_id uuid not null references public.gal_equipment_components(id),
  component_role text not null,
  ordinal smallint not null default 1 check (ordinal >= 1),
  created_at timestamptz not null default now(),
  unique(configuration_id,component_role,ordinal)
);

create table if not exists public.gal_equipment_configuration_settings (
  id uuid primary key default gen_random_uuid(),
  configuration_id uuid not null references public.gal_equipment_configurations(id) on delete cascade,
  setting_key text not null,
  setting_value jsonb not null,
  unit text,
  source_reference text,
  created_at timestamptz not null default now(),
  unique(configuration_id,setting_key)
);

create table if not exists public.gal_equipment_compatibility_rules (
  id uuid primary key default gen_random_uuid(),
  equipment_compatibility_rule_id text not null unique default gal_public_id('GAL-ECR'),
  category text,
  subject_component_type text,
  target_component_type text,
  predicate_key text not null,
  operator text not null check (operator in ('EQ','NEQ','IN','NOT_IN','BETWEEN','REQUIRES','EXCLUDES')),
  predicate_value jsonb not null,
  hard_rule boolean not null default true,
  source_reference text,
  evidence_reference text,
  rule_version text not null,
  effective_from timestamptz,
  effective_to timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.gal_equipment_dependency_rules (
  id uuid primary key default gen_random_uuid(),
  equipment_dependency_rule_id text not null unique default gal_public_id('GAL-EDR'),
  category text,
  trigger_key text not null,
  trigger_operator text not null,
  trigger_value jsonb not null,
  effect_attribute_key text not null,
  effect_value jsonb,
  effect_expression text,
  unit text,
  source_reference text,
  evidence_reference text,
  rule_version text not null,
  effective_from timestamptz,
  effective_to timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists gal_equipment_config_family_idx on public.gal_equipment_configurations(family_id,support_state);
create index if not exists gal_equipment_config_variant_idx on public.gal_equipment_configurations(variant_id,support_state);
create index if not exists gal_equipment_config_component_idx on public.gal_equipment_configuration_components(component_id,configuration_id);
create index if not exists gal_equipment_compatibility_lookup_idx on public.gal_equipment_compatibility_rules(category,subject_component_type,target_component_type,active);
create index if not exists gal_equipment_dependency_lookup_idx on public.gal_equipment_dependency_rules(category,trigger_key,active);

create or replace view public.gal_equipment_configuration_eligible_v as
select c.*
from public.gal_equipment_configurations c
where c.support_state in ('FACTORY_STANDARD','FACTORY_CUSTOM','AFTERMARKET_VALID')
  and not exists (
    select 1 from public.gal_equipment_compatibility_rules r
    where r.active and r.hard_rule
      and r.category is not null
      and r.category <> coalesce((select f.category from public.gal_equipment_families f where f.id=c.family_id),
                                 (select f.category from public.gal_equipment_variants v join public.gal_equipment_families f on f.id=v.family_id where v.id=c.variant_id))
      and false
  );

alter table public.gal_equipment_configurations enable row level security;
alter table public.gal_equipment_configuration_components enable row level security;
alter table public.gal_equipment_configuration_settings enable row level security;
alter table public.gal_equipment_compatibility_rules enable row level security;
alter table public.gal_equipment_dependency_rules enable row level security;

do $$ declare t text; begin
  foreach t in array array['gal_equipment_configurations','gal_equipment_configuration_components','gal_equipment_configuration_settings','gal_equipment_compatibility_rules','gal_equipment_dependency_rules'] loop
    if not exists (select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)',t);
    end if;
  end loop;
end $$;
