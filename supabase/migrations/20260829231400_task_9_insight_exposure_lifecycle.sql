create type public.gal_insight_delivery_status as enum ('ELIGIBLE','COOLDOWN','DISMISSED','ACTED','EXPIRED');
create type public.gal_insight_exposure_event_type as enum ('PRESENTED','BLOCKED_COOLDOWN','DISMISSED','ACTED','SNOOZED');

create table public.gal_insight_delivery_state (
  insight_id uuid primary key references public.gal_insights(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  status public.gal_insight_delivery_status not null default 'ELIGIBLE',
  presentation_count integer not null default 0 check (presentation_count >= 0),
  first_presented_at timestamptz,
  last_presented_at timestamptz,
  next_global_eligible_at timestamptz,
  last_surface text,
  dismissed_at timestamptz,
  acted_at timestamptz,
  snoozed_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, insight_id),
  check (first_presented_at is null or last_presented_at is null or last_presented_at >= first_presented_at)
);

create table public.gal_insight_exposures (
  id uuid primary key default gen_random_uuid(),
  exposure_id text not null unique default public.gal_public_id('GAL-IEX'),
  insight_id uuid not null references public.gal_insights(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  surface text not null check (btrim(surface) <> ''),
  status public.gal_insight_delivery_status not null default 'ELIGIBLE',
  presentation_count integer not null default 0 check (presentation_count >= 0),
  first_presented_at timestamptz,
  last_presented_at timestamptz,
  next_surface_eligible_at timestamptz,
  dismissed_at timestamptz,
  acted_at timestamptz,
  snoozed_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gal_insight_exposures_one_surface unique(insight_id, surface),
  check (first_presented_at is null or last_presented_at is null or last_presented_at >= first_presented_at)
);

create table public.gal_insight_exposure_events (
  id uuid primary key default gen_random_uuid(),
  exposure_event_id text not null unique default public.gal_public_id('GAL-IEV'),
  exposure_id uuid references public.gal_insight_exposures(id) on delete cascade,
  insight_id uuid not null references public.gal_insights(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  event_type public.gal_insight_exposure_event_type not null,
  surface text not null check (btrim(surface) <> ''),
  source_system text not null check (btrim(source_system) <> ''),
  source_event_key text not null check (btrim(source_event_key) <> ''),
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata)='object'),
  created_at timestamptz not null default now(),
  constraint gal_insight_exposure_events_idempotency unique(user_id, source_system, source_event_key)
);

create index gal_insight_delivery_state_user_idx on public.gal_insight_delivery_state(user_id,status,next_global_eligible_at);
create index gal_insight_exposures_user_idx on public.gal_insight_exposures(user_id,status,next_surface_eligible_at);
create index gal_insight_exposure_events_insight_idx on public.gal_insight_exposure_events(insight_id,occurred_at desc);

alter table public.gal_insight_delivery_state enable row level security;
alter table public.gal_insight_exposures enable row level security;
alter table public.gal_insight_exposure_events enable row level security;

revoke all on public.gal_insight_delivery_state from anon, authenticated;
revoke all on public.gal_insight_exposures from anon, authenticated;
revoke all on public.gal_insight_exposure_events from anon, authenticated;
grant select on public.gal_insight_delivery_state to authenticated;
grant select on public.gal_insight_exposures to authenticated;

create policy gal_insight_delivery_state_self_select on public.gal_insight_delivery_state
for select to authenticated
using (user_id = public.gal_current_user_id());

create policy gal_insight_exposures_self_select on public.gal_insight_exposures
for select to authenticated
using (user_id = public.gal_current_user_id());

create policy gal_insight_exposure_events_no_client_access on public.gal_insight_exposure_events
as restrictive for all to anon, authenticated using(false) with check(false);

create or replace function public.gal_record_insight_presentation(
  p_user_id uuid,
  p_insight_id text,
  p_surface text,
  p_source_system text,
  p_source_event_key text,
  p_presented_at timestamptz default now(),
  p_global_cooldown_hours integer default 168,
  p_surface_cooldown_hours integer default 168,
  p_metadata jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_insight public.gal_insights%rowtype;
  v_delivery public.gal_insight_delivery_state%rowtype;
  v_exposure public.gal_insight_exposures%rowtype;
  v_existing public.gal_insight_exposure_events%rowtype;
  v_block_until timestamptz;
  v_allowed boolean;
begin
  if p_user_id is null then raise exception 'p_user_id is required'; end if;
  if nullif(btrim(p_insight_id),'') is null then raise exception 'p_insight_id is required'; end if;
  if nullif(btrim(p_surface),'') is null then raise exception 'p_surface is required'; end if;
  if nullif(btrim(p_source_system),'') is null then raise exception 'p_source_system is required'; end if;
  if nullif(btrim(p_source_event_key),'') is null then raise exception 'p_source_event_key is required'; end if;
  if p_global_cooldown_hours < 0 or p_surface_cooldown_hours < 0 then raise exception 'cooldown hours must be >= 0'; end if;
  if jsonb_typeof(coalesce(p_metadata,'{}'::jsonb)) <> 'object' then raise exception 'p_metadata must be a JSON object'; end if;

  select * into v_existing
  from public.gal_insight_exposure_events
  where user_id=p_user_id and source_system=lower(btrim(p_source_system)) and source_event_key=btrim(p_source_event_key);

  if found then
    return jsonb_build_object(
      'idempotent_replay', true,
      'event_type', v_existing.event_type,
      'exposure_event_id', v_existing.exposure_event_id,
      'presented', v_existing.event_type='PRESENTED'
    );
  end if;

  select * into v_insight from public.gal_insights
  where insight_id=p_insight_id and user_id=p_user_id;
  if not found then raise exception 'Insight not found for user'; end if;
  if v_insight.status not in ('ACTIVE','ACKNOWLEDGED') then raise exception 'Insight is not eligible for presentation: %',v_insight.status; end if;
  if v_insight.expires_at is not null and v_insight.expires_at <= p_presented_at then raise exception 'Insight is expired'; end if;

  insert into public.gal_insight_delivery_state(insight_id,user_id)
  values(v_insight.id,p_user_id)
  on conflict(insight_id) do nothing;
  select * into v_delivery from public.gal_insight_delivery_state where insight_id=v_insight.id for update;

  insert into public.gal_insight_exposures(insight_id,user_id,surface)
  values(v_insight.id,p_user_id,lower(btrim(p_surface)))
  on conflict(insight_id,surface) do nothing;
  select * into v_exposure from public.gal_insight_exposures where insight_id=v_insight.id and surface=lower(btrim(p_surface)) for update;

  v_block_until := greatest(
    coalesce(v_delivery.next_global_eligible_at,'-infinity'::timestamptz),
    coalesce(v_delivery.snoozed_until,'-infinity'::timestamptz),
    coalesce(v_exposure.next_surface_eligible_at,'-infinity'::timestamptz),
    coalesce(v_exposure.snoozed_until,'-infinity'::timestamptz)
  );
  v_allowed := v_delivery.status not in ('DISMISSED','ACTED','EXPIRED')
    and v_exposure.status not in ('DISMISSED','ACTED','EXPIRED')
    and p_presented_at >= v_block_until;

  if not v_allowed then
    insert into public.gal_insight_exposure_events(exposure_id,insight_id,user_id,event_type,surface,source_system,source_event_key,occurred_at,metadata)
    values(v_exposure.id,v_insight.id,p_user_id,'BLOCKED_COOLDOWN',lower(btrim(p_surface)),lower(btrim(p_source_system)),btrim(p_source_event_key),p_presented_at,
      coalesce(p_metadata,'{}'::jsonb) || jsonb_build_object('blocked_until',case when v_block_until='-infinity'::timestamptz then null else v_block_until end));
    return jsonb_build_object('idempotent_replay',false,'presented',false,'reason','cooldown_or_terminal_state','blocked_until',case when v_block_until='-infinity'::timestamptz then null else v_block_until end);
  end if;

  update public.gal_insight_delivery_state
  set status='COOLDOWN', presentation_count=presentation_count+1,
      first_presented_at=coalesce(first_presented_at,p_presented_at), last_presented_at=p_presented_at,
      next_global_eligible_at=p_presented_at + make_interval(hours=>p_global_cooldown_hours),
      last_surface=lower(btrim(p_surface)), updated_at=now()
  where insight_id=v_insight.id returning * into v_delivery;

  update public.gal_insight_exposures
  set status='COOLDOWN', presentation_count=presentation_count+1,
      first_presented_at=coalesce(first_presented_at,p_presented_at), last_presented_at=p_presented_at,
      next_surface_eligible_at=p_presented_at + make_interval(hours=>p_surface_cooldown_hours), updated_at=now()
  where id=v_exposure.id returning * into v_exposure;

  insert into public.gal_insight_exposure_events(exposure_id,insight_id,user_id,event_type,surface,source_system,source_event_key,occurred_at,metadata)
  values(v_exposure.id,v_insight.id,p_user_id,'PRESENTED',lower(btrim(p_surface)),lower(btrim(p_source_system)),btrim(p_source_event_key),p_presented_at,coalesce(p_metadata,'{}'::jsonb));

  return jsonb_build_object('idempotent_replay',false,'presented',true,'presentation_count',v_delivery.presentation_count,'next_global_eligible_at',v_delivery.next_global_eligible_at,'next_surface_eligible_at',v_exposure.next_surface_eligible_at);
end;
$$;

revoke execute on function public.gal_record_insight_presentation(uuid,text,text,text,text,timestamptz,integer,integer,jsonb) from public,anon,authenticated;
grant execute on function public.gal_record_insight_presentation(uuid,text,text,text,text,timestamptz,integer,integer,jsonb) to service_role;
