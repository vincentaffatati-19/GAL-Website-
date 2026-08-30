create type public.gal_insight_response_type as enum ('ACKNOWLEDGED','DISMISSED','SNOOZED','ACTED','NOT_RELEVANT');

create table public.gal_insight_responses (
  id uuid primary key default gen_random_uuid(),
  response_id text not null unique default public.gal_public_id('GAL-IRP'),
  insight_id uuid not null references public.gal_insights(id) on delete cascade,
  exposure_id uuid not null references public.gal_insight_exposures(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  response_type public.gal_insight_response_type not null,
  surface text not null check (btrim(surface) <> ''),
  source_system text not null check (btrim(source_system) <> ''),
  source_event_key text not null check (btrim(source_event_key) <> ''),
  buyer_event_id uuid references public.gal_buyer_events(id) on delete set null,
  occurred_at timestamptz not null default now(),
  snoozed_until timestamptz,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata)='object'),
  created_at timestamptz not null default now(),
  constraint gal_insight_responses_idempotency unique(user_id, source_system, source_event_key),
  constraint gal_insight_responses_snooze_check check ((response_type='SNOOZED' and snoozed_until is not null) or (response_type<>'SNOOZED'))
);

create index gal_insight_responses_insight_idx on public.gal_insight_responses(insight_id,occurred_at desc);
create index gal_insight_responses_user_idx on public.gal_insight_responses(user_id,occurred_at desc);

alter table public.gal_insight_responses enable row level security;
revoke all on public.gal_insight_responses from anon, authenticated;
grant select on public.gal_insight_responses to authenticated;

create policy gal_insight_responses_self_select on public.gal_insight_responses
for select to authenticated
using (user_id = public.gal_current_user_id());

create or replace function public.gal_record_insight_response(
  p_user_id uuid,
  p_insight_id text,
  p_surface text,
  p_response_type public.gal_insight_response_type,
  p_source_system text,
  p_source_event_key text,
  p_occurred_at timestamptz default now(),
  p_snoozed_until timestamptz default null,
  p_buyer_event_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_insight public.gal_insights%rowtype;
  v_exposure public.gal_insight_exposures%rowtype;
  v_existing public.gal_insight_responses%rowtype;
  v_response public.gal_insight_responses%rowtype;
begin
  if p_user_id is null then raise exception 'p_user_id is required'; end if;
  if nullif(btrim(p_insight_id),'') is null then raise exception 'p_insight_id is required'; end if;
  if nullif(btrim(p_surface),'') is null then raise exception 'p_surface is required'; end if;
  if nullif(btrim(p_source_system),'') is null then raise exception 'p_source_system is required'; end if;
  if nullif(btrim(p_source_event_key),'') is null then raise exception 'p_source_event_key is required'; end if;
  if p_response_type='SNOOZED' and (p_snoozed_until is null or p_snoozed_until <= p_occurred_at) then raise exception 'SNOOZED requires future p_snoozed_until'; end if;
  if jsonb_typeof(coalesce(p_metadata,'{}'::jsonb)) <> 'object' then raise exception 'p_metadata must be a JSON object'; end if;

  select * into v_existing
  from public.gal_insight_responses
  where user_id=p_user_id and source_system=lower(btrim(p_source_system)) and source_event_key=btrim(p_source_event_key);
  if found then
    return jsonb_build_object('idempotent_replay',true,'response_id',v_existing.response_id,'response_type',v_existing.response_type);
  end if;

  select * into v_insight from public.gal_insights
  where insight_id=p_insight_id and user_id=p_user_id;
  if not found then raise exception 'Insight not found for user'; end if;

  select * into v_exposure from public.gal_insight_exposures
  where insight_id=v_insight.id and user_id=p_user_id and surface=lower(btrim(p_surface))
  for update;
  if not found then raise exception 'No prior exposure exists for this insight and surface'; end if;

  insert into public.gal_insight_responses(
    insight_id,exposure_id,user_id,response_type,surface,source_system,source_event_key,buyer_event_id,occurred_at,snoozed_until,metadata
  ) values(
    v_insight.id,v_exposure.id,p_user_id,p_response_type,lower(btrim(p_surface)),lower(btrim(p_source_system)),btrim(p_source_event_key),p_buyer_event_id,p_occurred_at,p_snoozed_until,coalesce(p_metadata,'{}'::jsonb)
  ) returning * into v_response;

  if p_response_type='ACKNOWLEDGED' then
    update public.gal_insights
      set status='ACKNOWLEDGED', acknowledged_at=coalesce(acknowledged_at,p_occurred_at), updated_at=now()
      where id=v_insight.id and status='ACTIVE';
  elsif p_response_type in ('DISMISSED','NOT_RELEVANT') then
    update public.gal_insight_delivery_state
      set status='DISMISSED', dismissed_at=coalesce(dismissed_at,p_occurred_at), updated_at=now()
      where insight_id=v_insight.id;
    update public.gal_insight_exposures
      set status='DISMISSED', dismissed_at=coalesce(dismissed_at,p_occurred_at), updated_at=now()
      where insight_id=v_insight.id;
  elsif p_response_type='SNOOZED' then
    update public.gal_insight_delivery_state
      set status='COOLDOWN', snoozed_until=greatest(coalesce(snoozed_until,'-infinity'::timestamptz),p_snoozed_until), updated_at=now()
      where insight_id=v_insight.id;
    update public.gal_insight_exposures
      set status='COOLDOWN', snoozed_until=greatest(coalesce(snoozed_until,'-infinity'::timestamptz),p_snoozed_until), updated_at=now()
      where id=v_exposure.id;
  elsif p_response_type='ACTED' then
    update public.gal_insight_delivery_state
      set status='ACTED', acted_at=coalesce(acted_at,p_occurred_at), updated_at=now()
      where insight_id=v_insight.id;
    update public.gal_insight_exposures
      set status='ACTED', acted_at=coalesce(acted_at,p_occurred_at), updated_at=now()
      where insight_id=v_insight.id;
    update public.gal_insights
      set status='ACKNOWLEDGED', acknowledged_at=coalesce(acknowledged_at,p_occurred_at), updated_at=now()
      where id=v_insight.id and status='ACTIVE';
  end if;

  return jsonb_build_object('idempotent_replay',false,'response_id',v_response.response_id,'response_type',v_response.response_type,'insight_id',v_insight.insight_id);
end;
$$;

revoke execute on function public.gal_record_insight_response(uuid,text,text,public.gal_insight_response_type,text,text,timestamptz,timestamptz,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.gal_record_insight_response(uuid,text,text,public.gal_insight_response_type,text,text,timestamptz,timestamptz,uuid,jsonb) to service_role;
