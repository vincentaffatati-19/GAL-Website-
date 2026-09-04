-- GAL Equipment Knowledge Wave C: use-case-specific readiness governance

create table if not exists public.gal_equipment_readiness_policies (
  id uuid primary key default gen_random_uuid(),
  equipment_readiness_policy_id text not null unique default gal_public_id('GAL-ERP'),
  category text not null,
  use_case text not null,
  policy_version text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(category,use_case,policy_version)
);

create table if not exists public.gal_equipment_readiness_requirements (
  id uuid primary key default gen_random_uuid(),
  readiness_policy_id uuid not null references public.gal_equipment_readiness_policies(id) on delete cascade,
  attribute_definition_id uuid not null references public.gal_equipment_attribute_definitions(id),
  requirement_type text not null check (requirement_type in ('REQUIRED','CONDITIONALLY_REQUIRED','OPTIONAL')),
  condition_json jsonb,
  created_at timestamptz not null default now(),
  unique(readiness_policy_id,attribute_definition_id)
);

create table if not exists public.gal_equipment_readiness_state (
  id uuid primary key default gen_random_uuid(),
  equipment_readiness_state_id text not null unique default gal_public_id('GAL-ERS'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  configuration_id uuid references public.gal_equipment_configurations(id),
  use_case text not null,
  readiness_state text not null check (readiness_state in ('CATALOG_READY','GUIDE_READY','AI_FIT_LIMITED','AI_FIT_READY')),
  policy_version text not null,
  evidence_snapshot_version text,
  blocking_gap_count integer not null default 0 check (blocking_gap_count>=0),
  evaluated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check ((((family_id is not null)::int)+((variant_id is not null)::int)+((configuration_id is not null)::int))=1),
  check (readiness_state <> 'AI_FIT_READY' or blocking_gap_count=0)
);

create table if not exists public.gal_equipment_evidence_gaps (
  id uuid primary key default gen_random_uuid(),
  equipment_evidence_gap_id text not null unique default gal_public_id('GAL-EGP'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  configuration_id uuid references public.gal_equipment_configurations(id),
  use_case text not null,
  desired_readiness_state text not null check (desired_readiness_state in ('CATALOG_READY','GUIDE_READY','AI_FIT_LIMITED','AI_FIT_READY')),
  attribute_definition_id uuid references public.gal_equipment_attribute_definitions(id),
  evidence_requirement text not null,
  priority text not null default 'MEDIUM' check (priority in ('LOW','MEDIUM','HIGH','CRITICAL')),
  materiality numeric check (materiality is null or materiality between 0 and 1),
  recommended_action text,
  status text not null default 'OPEN' check (status in ('OPEN','IN_PROGRESS','RESOLVED','WITHHELD')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((((family_id is not null)::int)+((variant_id is not null)::int)+((configuration_id is not null)::int))=1)
);

create table if not exists public.gal_equipment_readiness_evaluations (
  id uuid primary key default gen_random_uuid(),
  readiness_state_id uuid not null references public.gal_equipment_readiness_state(id),
  readiness_policy_id uuid references public.gal_equipment_readiness_policies(id),
  evidence_snapshot jsonb not null default '{}'::jsonb,
  blocker_snapshot jsonb not null default '[]'::jsonb,
  evaluator_version text not null,
  evaluated_at timestamptz not null default now()
);

create index if not exists gal_equipment_readiness_subject_idx on public.gal_equipment_readiness_state(family_id,variant_id,configuration_id,use_case,readiness_state);
create index if not exists gal_equipment_gap_subject_idx on public.gal_equipment_evidence_gaps(family_id,variant_id,configuration_id,use_case,status);
create index if not exists gal_equipment_readiness_req_idx on public.gal_equipment_readiness_requirements(readiness_policy_id,requirement_type);

alter table public.gal_equipment_readiness_policies enable row level security;
alter table public.gal_equipment_readiness_requirements enable row level security;
alter table public.gal_equipment_readiness_state enable row level security;
alter table public.gal_equipment_evidence_gaps enable row level security;
alter table public.gal_equipment_readiness_evaluations enable row level security;

do $$ declare t text; begin
  foreach t in array array['gal_equipment_readiness_policies','gal_equipment_readiness_requirements','gal_equipment_readiness_state','gal_equipment_evidence_gaps','gal_equipment_readiness_evaluations'] loop
    if not exists (select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)',t);
    end if;
  end loop;
end $$;
