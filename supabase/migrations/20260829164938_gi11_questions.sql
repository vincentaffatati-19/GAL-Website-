-- GI-1.1 Foundation Task 6
-- Purpose: extend the governed Question Catalog and add append-only golfer response evidence.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_questions

alter table public.gal_question_catalog
  add column question_text text not null,
  add column short_label text,
  add column help_text text,
  add column why_gal_asks text,
  add column response_type text not null,
  add column primary_fact_key text references public.gal_fact_catalog(fact_key),
  add column secondary_fact_keys jsonb not null default '[]'::jsonb,
  add column category public.gal_category,
  add column domain text,
  add column required_level text,
  add column can_skip boolean not null default true,
  add column allow_unknown boolean not null default true,
  add column proxy_group text,
  add column refresh_class text,
  add column confidence_rule jsonb not null default '{}'::jsonb,
  add column branching_rule jsonb not null default '{}'::jsonb,
  add column output_type text,
  add column visual_asset_key text,
  add column commercial_class text,
  add column retired_at timestamptz;

-- The existing (question_key, question_version) uniqueness remains authoritative.
-- This companion key allows response evidence to bind to the exact catalog row and version.
alter table public.gal_question_catalog
  add constraint gal_question_catalog_exact_version_key
  unique (id, question_key, question_version);

create table public.gal_question_responses (
  id uuid primary key default gen_random_uuid(),
  response_id text unique not null default public.gal_public_id('GAL-QR'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  question_catalog_id uuid not null,
  question_key text not null,
  question_version text not null,
  response_value jsonb,
  response_state text not null,
  source_context text not null,
  session_id text,
  recommendation_run_id uuid,
  resulting_fact_id uuid references public.gal_profile_facts(id) on delete set null,
  confidence_generated numeric(4,3),
  answered_at timestamptz not null default now(),
  superseded_at timestamptz,
  created_at timestamptz not null default now(),

  constraint gal_question_responses_exact_question_fk
    foreign key (question_catalog_id, question_key, question_version)
    references public.gal_question_catalog(id, question_key, question_version),

  constraint gal_question_responses_confidence_check
    check (confidence_generated is null or (confidence_generated >= 0 and confidence_generated <= 1)),

  constraint gal_question_responses_state_check
    check (response_state in ('ANSWERED','UNKNOWN_DECLARED','SKIPPED','NOT_APPLICABLE'))
);

create index gal_question_responses_user_question_answered_idx
  on public.gal_question_responses(user_id, question_key, answered_at desc);

create index gal_question_responses_user_context_answered_idx
  on public.gal_question_responses(user_id, source_context, answered_at desc);

create index gal_question_responses_session_idx
  on public.gal_question_responses(session_id)
  where session_id is not null;

create index gal_question_responses_recommendation_run_idx
  on public.gal_question_responses(recommendation_run_id)
  where recommendation_run_id is not null;

create index gal_question_responses_resulting_fact_idx
  on public.gal_question_responses(resulting_fact_id)
  where resulting_fact_id is not null;

alter table public.gal_question_responses enable row level security;

-- Response history is evidence: golfer-readable but not directly golfer-writable.
revoke all on table public.gal_question_responses from public, anon, authenticated;
grant select on table public.gal_question_responses to authenticated;
grant select, insert, update, delete on table public.gal_question_responses to service_role;

create policy gal_question_responses_self_select
  on public.gal_question_responses
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());
