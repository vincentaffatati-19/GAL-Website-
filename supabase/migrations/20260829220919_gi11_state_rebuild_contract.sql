-- GI-1.1 Longitudinal Intelligence Task 6
-- Trusted persistence boundary for the rebuildable golfer intelligence cache.
-- Source-of-truth facts, events, bags, and recommendation evidence are never mutated here.

create or replace function public.gal_persist_intelligence_state(
  p_user_id uuid,
  p_payload jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_generation_id uuid;
  v_status text;
  v_state jsonb;
  v_domain_status jsonb;
  v_event_count bigint;
  v_latest_source_event_at timestamptz;
begin
  if p_user_id is null then
    raise exception using errcode = '22004', message = 'GI11_STATE_USER_REQUIRED';
  end if;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception using errcode = '22023', message = 'GI11_STATE_PAYLOAD_INVALID';
  end if;

  begin
    v_generation_id := nullif(btrim(p_payload ->> 'stateGenerationId'), '')::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '22023', message = 'GI11_STATE_GENERATION_ID_INVALID';
  end;

  if v_generation_id is null then
    raise exception using errcode = '22023', message = 'GI11_STATE_GENERATION_ID_REQUIRED';
  end if;

  v_status := upper(nullif(btrim(p_payload ->> 'status'), ''));
  if v_status is null or v_status not in ('HEALTHY','STALE','PARTIAL','REBUILDING','ERROR') then
    raise exception using errcode = '22023', message = 'GI11_STATE_STATUS_INVALID';
  end if;

  v_state := p_payload -> 'state';
  if v_state is null or jsonb_typeof(v_state) <> 'object' then
    raise exception using errcode = '22023', message = 'GI11_STATE_DOCUMENT_INVALID';
  end if;

  if v_state ->> 'stateSchemaVersion' is distinct from 'GI-STATE-1.1' then
    raise exception using errcode = '22023', message = 'GI11_STATE_SCHEMA_VERSION_INVALID';
  end if;

  v_domain_status := coalesce(p_payload -> 'domainStatus', '{}'::jsonb);
  if jsonb_typeof(v_domain_status) <> 'object' then
    raise exception using errcode = '22023', message = 'GI11_STATE_DOMAIN_STATUS_INVALID';
  end if;

  begin
    v_event_count := coalesce(nullif(btrim(p_payload ->> 'eventCount'), '')::bigint, 0);
  exception when invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = '22023', message = 'GI11_STATE_EVENT_COUNT_INVALID';
  end;

  if v_event_count < 0 then
    raise exception using errcode = '22023', message = 'GI11_STATE_EVENT_COUNT_INVALID';
  end if;

  begin
    v_latest_source_event_at := nullif(btrim(p_payload ->> 'latestSourceEventAt'), '')::timestamptz;
  exception when invalid_datetime_format or datetime_field_overflow then
    raise exception using errcode = '22023', message = 'GI11_STATE_EVENT_WATERMARK_INVALID';
  end;

  insert into public.gal_intelligence_state (
    user_id,
    engine_version,
    state,
    event_count,
    latest_event_at,
    computed_at,
    created_at,
    updated_at,
    state_schema_version,
    state_generation_id,
    status,
    latest_source_event_at,
    domain_status
  ) values (
    p_user_id,
    'GI-STATE-BUILDER-1.0',
    v_state,
    v_event_count,
    v_latest_source_event_at,
    transaction_timestamp(),
    transaction_timestamp(),
    transaction_timestamp(),
    'GI-STATE-1.1',
    v_generation_id,
    v_status,
    v_latest_source_event_at,
    v_domain_status
  )
  on conflict (user_id) do update
  set engine_version = excluded.engine_version,
      state = excluded.state,
      event_count = excluded.event_count,
      latest_event_at = excluded.latest_event_at,
      computed_at = excluded.computed_at,
      updated_at = excluded.updated_at,
      state_schema_version = excluded.state_schema_version,
      state_generation_id = excluded.state_generation_id,
      status = excluded.status,
      latest_source_event_at = excluded.latest_source_event_at,
      domain_status = excluded.domain_status;

  return v_generation_id;
end;
$$;

-- The function is an intentionally narrow service endpoint. It runs with caller privileges
-- and therefore does not bypass RLS/table grants on its own.
revoke all on function public.gal_persist_intelligence_state(uuid, jsonb) from public;
revoke all on function public.gal_persist_intelligence_state(uuid, jsonb) from anon;
revoke all on function public.gal_persist_intelligence_state(uuid, jsonb) from authenticated;
grant execute on function public.gal_persist_intelligence_state(uuid, jsonb) to service_role;

comment on function public.gal_persist_intelligence_state(uuid, jsonb) is
  'Service-role-only SECURITY INVOKER boundary that atomically replaces a golfer GI-STATE-1.1 derived cache row. Durable source data is not modified.';
