-- GI-1.1 Foundation Task 4
-- Purpose: preserve immutable longitudinal golfer-fact history while keeping
-- the browser-facing mutation endpoint SECURITY INVOKER and RLS-governed.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_profile_fact_history

create schema if not exists gal_private;
revoke all on schema gal_private from public;
grant usage on schema gal_private to authenticated, service_role;

create table public.gal_profile_fact_history (
  id uuid primary key default gen_random_uuid(),
  history_id text unique not null default public.gal_public_id('GAL-FH'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  current_fact_id uuid not null,
  fact_key text not null references public.gal_fact_catalog(fact_key),
  scope text not null,
  fact_value jsonb,
  value_state text not null,
  unit text,
  source text not null,
  source_category text,
  source_type text,
  source_detail jsonb not null default '{}'::jsonb,
  confidence numeric(4,3) not null check (confidence >= 0 and confidence <= 1),
  user_confirmed boolean not null default false,
  fact_catalog_version text not null,
  model_version text,
  question_version text,
  privacy_class text,
  commercial_class text,
  data_source_id uuid references public.gal_external_source_catalog(id) on delete set null,
  effective_from timestamptz,
  effective_to timestamptz,
  observed_at timestamptz not null,
  superseded_reason text not null,
  created_at timestamptz not null default now(),
  constraint gal_profile_fact_history_value_state_check
    check (value_state in ('KNOWN','UNKNOWN','NOT_ANSWERED','NOT_APPLICABLE','INFERRED_ONLY')),
  constraint gal_profile_fact_history_source_type_check
    check (source_type is null or source_type in ('DECLARED','MEASURED','OBSERVED','INFERRED','IMPORTED','SYSTEM'))
);

create index gal_profile_fact_history_user_fact_effective_idx
  on public.gal_profile_fact_history(user_id, fact_key, effective_from desc);

create index gal_profile_fact_history_user_created_idx
  on public.gal_profile_fact_history(user_id, created_at desc);

create index gal_profile_fact_history_current_fact_idx
  on public.gal_profile_fact_history(current_fact_id);

create index gal_profile_fact_history_data_source_idx
  on public.gal_profile_fact_history(data_source_id)
  where data_source_id is not null;

alter table public.gal_profile_fact_history enable row level security;

revoke all on table public.gal_profile_fact_history from public, anon, authenticated;
grant select on table public.gal_profile_fact_history to authenticated;
grant select, insert, update, delete on table public.gal_profile_fact_history to service_role;

create policy gal_profile_fact_history_self_select
  on public.gal_profile_fact_history
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

-- Narrow privileged catalog reader used by the SECURITY INVOKER mutation RPC.
-- The schema is not exposed through the Data API; only this bounded function is executable.
create or replace function gal_private.gal_active_fact_contract(p_fact_key text)
returns table (
  schema_version text,
  unit text,
  privacy_class text,
  commercial_class text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    fc.schema_version,
    fc.unit,
    fc.privacy_class,
    fc.commercial_class
  from public.gal_fact_catalog fc
  where fc.fact_key = p_fact_key
    and fc.status = 'ACTIVE'
  limit 1;
$$;

revoke all on function gal_private.gal_active_fact_contract(text) from public, anon, authenticated;
grant execute on function gal_private.gal_active_fact_contract(text) to authenticated, service_role;

-- Trigger-only privileged writer. It is deliberately outside public and has no
-- authenticated EXECUTE grant. It preserves OLD before UPDATE/DELETE.
create or replace function gal_private.gal_capture_profile_fact_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text;
  v_effective_to timestamptz;
begin
  v_reason := coalesce(
    nullif(pg_catalog.current_setting('gal.superseded_reason', true), ''),
    case when tg_op = 'DELETE' then 'golfer_delete' else 'golfer_update' end
  );

  v_effective_to := case
    when tg_op = 'UPDATE' then coalesce(new.effective_at, pg_catalog.transaction_timestamp())
    else pg_catalog.transaction_timestamp()
  end;

  insert into public.gal_profile_fact_history (
    user_id,
    current_fact_id,
    fact_key,
    scope,
    fact_value,
    value_state,
    unit,
    source,
    source_category,
    source_type,
    source_detail,
    confidence,
    user_confirmed,
    fact_catalog_version,
    model_version,
    question_version,
    privacy_class,
    commercial_class,
    data_source_id,
    effective_from,
    effective_to,
    observed_at,
    superseded_reason
  ) values (
    old.user_id,
    old.id,
    old.fact_key,
    old.scope,
    old.fact_value,
    old.value_state,
    old.unit,
    old.source,
    old.source_category,
    old.source_type,
    old.source_detail,
    old.confidence,
    old.user_confirmed,
    old.fact_catalog_version,
    old.model_version,
    old.question_version,
    old.privacy_class,
    old.commercial_class,
    old.data_source_id,
    coalesce(old.effective_at, old.created_at),
    v_effective_to,
    old.observed_at,
    v_reason
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function gal_private.gal_capture_profile_fact_history() from public, anon, authenticated;
grant execute on function gal_private.gal_capture_profile_fact_history() to service_role;

drop trigger if exists gal_profile_facts_capture_history on public.gal_profile_facts;
create trigger gal_profile_facts_capture_history
before update or delete on public.gal_profile_facts
for each row
execute function gal_private.gal_capture_profile_fact_history();

-- Browser-facing current-fact mutation contract. SECURITY INVOKER is deliberate:
-- profile-fact INSERT/UPDATE remains subject to the authenticated golfer's RLS.
create or replace function public.gal_set_profile_fact(
  p_fact_key text,
  p_fact_value jsonb,
  p_scope text,
  p_provenance jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_fact_id uuid;
  v_fact_key text := pg_catalog.btrim(p_fact_key);
  v_scope text := coalesce(nullif(pg_catalog.btrim(p_scope), ''), 'global');
  v_provenance jsonb := coalesce(p_provenance, '{}'::jsonb);
  v_catalog_version text;
  v_catalog_unit text;
  v_privacy_class text;
  v_commercial_class text;
  v_source text;
  v_source_category text;
  v_source_type text;
  v_confidence numeric(4,3);
  v_user_confirmed boolean;
  v_value_state text;
  v_unit text;
  v_source_detail jsonb;
  v_effective_at timestamptz;
  v_observed_at timestamptz;
  v_last_confirmed_at timestamptz;
  v_model_version text;
  v_question_version text;
  v_data_source_id uuid;
  v_stale_after_days integer;
  v_superseded_reason text;
begin
  if v_fact_key is null or v_fact_key = '' then
    raise exception 'GI11_FACT_KEY_REQUIRED' using errcode = '22023';
  end if;

  if current_user in ('postgres', 'service_role') then
    v_user_id := nullif(v_provenance ->> 'user_id', '')::uuid;
    if v_user_id is null then
      v_user_id := public.gal_current_user_id();
    end if;
  else
    v_user_id := public.gal_current_user_id();
  end if;

  if v_user_id is null then
    raise exception 'GI11_ACTIVE_GAL_USER_REQUIRED' using errcode = '42501';
  end if;

  select c.schema_version, c.unit, c.privacy_class, c.commercial_class
    into v_catalog_version, v_catalog_unit, v_privacy_class, v_commercial_class
  from gal_private.gal_active_fact_contract(v_fact_key) c;

  if v_catalog_version is null then
    raise exception 'GI11_ACTIVE_FACT_KEY_REQUIRED: %', v_fact_key using errcode = '23503';
  end if;

  v_source := coalesce(nullif(v_provenance ->> 'source', ''), 'golfer');
  v_source_category := nullif(v_provenance ->> 'source_category', '');
  v_source_type := coalesce(
    nullif(v_provenance ->> 'source_type', ''),
    v_source_category,
    'DECLARED'
  );
  v_confidence := coalesce(nullif(v_provenance ->> 'confidence', '')::numeric, 1.000);
  v_user_confirmed := coalesce(nullif(v_provenance ->> 'user_confirmed', '')::boolean, false);
  v_value_state := coalesce(
    nullif(v_provenance ->> 'value_state', ''),
    case when p_fact_value is null then 'UNKNOWN' else 'KNOWN' end
  );
  v_unit := coalesce(nullif(v_provenance ->> 'unit', ''), v_catalog_unit);
  v_source_detail := coalesce(v_provenance -> 'source_detail', '{}'::jsonb);
  v_effective_at := coalesce(nullif(v_provenance ->> 'effective_at', '')::timestamptz, pg_catalog.transaction_timestamp());
  v_observed_at := coalesce(nullif(v_provenance ->> 'observed_at', '')::timestamptz, pg_catalog.transaction_timestamp());
  v_last_confirmed_at := case
    when nullif(v_provenance ->> 'last_confirmed_at', '') is not null
      then (v_provenance ->> 'last_confirmed_at')::timestamptz
    when v_user_confirmed
      then pg_catalog.transaction_timestamp()
    else null
  end;
  v_model_version := nullif(v_provenance ->> 'model_version', '');
  v_question_version := nullif(v_provenance ->> 'question_version', '');
  v_data_source_id := nullif(v_provenance ->> 'data_source_id', '')::uuid;
  v_stale_after_days := nullif(v_provenance ->> 'stale_after_days', '')::integer;
  v_superseded_reason := coalesce(nullif(v_provenance ->> 'superseded_reason', ''), 'golfer_update');

  if v_confidence < 0 or v_confidence > 1 then
    raise exception 'GI11_CONFIDENCE_OUT_OF_RANGE' using errcode = '22023';
  end if;

  perform pg_catalog.set_config('gal.superseded_reason', v_superseded_reason, true);

  select pf.id
    into v_fact_id
  from public.gal_profile_facts pf
  where pf.user_id = v_user_id
    and pf.fact_key = v_fact_key
    and pf.scope = v_scope
  for update;

  if v_fact_id is null then
    insert into public.gal_profile_facts (
      user_id,
      fact_key,
      fact_value,
      source,
      source_category,
      confidence,
      user_confirmed,
      scope,
      stale_after_days,
      observed_at,
      updated_at,
      value_state,
      unit,
      source_type,
      source_detail,
      fact_catalog_version,
      effective_at,
      last_confirmed_at,
      model_version,
      question_version,
      privacy_class,
      commercial_class,
      data_source_id
    ) values (
      v_user_id,
      v_fact_key,
      p_fact_value,
      v_source,
      v_source_category,
      v_confidence,
      v_user_confirmed,
      v_scope,
      v_stale_after_days,
      v_observed_at,
      pg_catalog.transaction_timestamp(),
      v_value_state,
      v_unit,
      v_source_type,
      v_source_detail,
      v_catalog_version,
      v_effective_at,
      v_last_confirmed_at,
      v_model_version,
      v_question_version,
      v_privacy_class,
      v_commercial_class,
      v_data_source_id
    )
    returning id into v_fact_id;
  else
    update public.gal_profile_facts
    set fact_value = p_fact_value,
        source = v_source,
        source_category = v_source_category,
        confidence = v_confidence,
        user_confirmed = v_user_confirmed,
        stale_after_days = v_stale_after_days,
        observed_at = v_observed_at,
        updated_at = pg_catalog.transaction_timestamp(),
        value_state = v_value_state,
        unit = v_unit,
        source_type = v_source_type,
        source_detail = v_source_detail,
        fact_catalog_version = v_catalog_version,
        effective_at = v_effective_at,
        last_confirmed_at = v_last_confirmed_at,
        model_version = v_model_version,
        question_version = v_question_version,
        privacy_class = v_privacy_class,
        commercial_class = v_commercial_class,
        data_source_id = v_data_source_id
    where id = v_fact_id;
  end if;

  perform pg_catalog.set_config('gal.superseded_reason', '', true);
  return v_fact_id;
exception
  when others then
    perform pg_catalog.set_config('gal.superseded_reason', '', true);
    raise;
end;
$$;

revoke all on function public.gal_set_profile_fact(text, jsonb, text, jsonb) from public, anon, authenticated;
grant execute on function public.gal_set_profile_fact(text, jsonb, text, jsonb) to authenticated, service_role;
