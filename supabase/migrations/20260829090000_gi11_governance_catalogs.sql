-- GI-1.1
-- Purpose: establish system-governed catalogs for facts, questions, events, models, and external sources.
-- Spec: docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md

create extension if not exists pgcrypto;

create table public.gal_fact_catalog (
  id uuid primary key default gen_random_uuid(),
  fact_key text not null unique,
  schema_version text not null,
  domain text not null,
  display_name text not null,
  description text,
  value_type text not null,
  unit text,
  allowed_values jsonb,
  min_value numeric,
  max_value numeric,
  initial_profile boolean not null default false,
  fit_importance text,
  can_be_inferred boolean not null default false,
  refresh_class text not null,
  privacy_class text not null,
  commercial_class text not null,
  status text not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (min_value is null or max_value is null or min_value <= max_value)
);

create table public.gal_question_catalog (
  id uuid primary key default gen_random_uuid(),
  question_key text not null,
  question_version text not null,
  status text not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (question_key, question_version)
);

create table public.gal_event_catalog (
  id uuid primary key default gen_random_uuid(),
  event_key text not null,
  event_version text not null,
  domain text,
  object_type text,
  action text,
  description text,
  status text not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_key, event_version)
);

create table public.gal_model_registry (
  id uuid primary key default gen_random_uuid(),
  model_key text not null,
  model_version text not null,
  model_type text not null,
  category text,
  status text not null default 'DRAFT',
  config jsonb not null default '{}'::jsonb,
  change_summary text,
  source_commit text,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (model_key, model_version),
  check (effective_to is null or effective_from is null or effective_to >= effective_from)
);

create table public.gal_external_source_catalog (
  id uuid primary key default gen_random_uuid(),
  source_key text not null,
  source_version text not null,
  source_type text not null,
  provider_name text,
  status text not null default 'ACTIVE',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_key, source_version)
);

alter table public.gal_fact_catalog enable row level security;
alter table public.gal_question_catalog enable row level security;
alter table public.gal_event_catalog enable row level security;
alter table public.gal_model_registry enable row level security;
alter table public.gal_external_source_catalog enable row level security;

-- Reference catalogs are system-governed in GI-1.1 Foundation.
-- Browser roles receive no direct access until a product requirement explicitly needs governed reads.
revoke all on table public.gal_fact_catalog from anon, authenticated;
revoke all on table public.gal_question_catalog from anon, authenticated;
revoke all on table public.gal_event_catalog from anon, authenticated;
revoke all on table public.gal_model_registry from anon, authenticated;
revoke all on table public.gal_external_source_catalog from anon, authenticated;

grant select, insert, update, delete on table public.gal_fact_catalog to service_role;
grant select, insert, update, delete on table public.gal_question_catalog to service_role;
grant select, insert, update, delete on table public.gal_event_catalog to service_role;
grant select, insert, update, delete on table public.gal_model_registry to service_role;
grant select, insert, update, delete on table public.gal_external_source_catalog to service_role;
