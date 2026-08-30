create type public.gal_insight_resolution_status as enum ('OPEN','EVIDENCE_PENDING','RESOLVED','INEFFECTIVE','REGRESSED');
create type public.gal_insight_resolution_event_type as enum ('EVIDENCE_RECORDED','RESOLVED','INEFFECTIVE','REGRESSED');

create table public.gal_insight_resolution_rules (
  id uuid primary key default gen_random_uuid(),
  resolution_rule_id text not null unique default public.gal_public_id('GAL-IRR'),
  insight_domain text not null check (btrim(insight_domain)<>''),
  insight_code text not null check (btrim(insight_code)<>''),
  rule_code text not null check (btrim(rule_code)<>''),
  rule_version text not null check (btrim(rule_version)<>''),
  qualifying_outcome_type text not null check (btrim(qualifying_outcome_type)<>''),
  minimum_outcome_confidence numeric(5,4) not null default 0.8000 check (minimum_outcome_confidence between 0 and 1),
  allowed_attributions public.gal_insight_outcome_attribution[] not null default array['OBSERVED'::public.gal_insight_outcome_attribution,'DIRECT_DECLARED'::public.gal_insight_outcome_attribution],
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(insight_domain,insight_code,rule_code,rule_version)
);

create table public.gal_insight_resolution_state (
  insight_id uuid primary key references public.gal_insights(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  status public.gal_insight_resolution_status not null default 'OPEN',
  resolution_rule_id uuid references public.gal_insight_resolution_rules(id) on delete restrict,
  qualifying_outcome_id uuid references public.gal_insight_outcomes(id) on delete set null,
  resolution_confidence numeric(5,4) check (resolution_confidence is null or resolution_confidence between 0 and 1),
  resolved_at timestamptz,
  regressed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,insight_id)
);

create table public.gal_insight_resolution_events (
  id uuid primary key default gen_random_uuid(),
  resolution_event_id text not null unique default public.gal_public_id('GAL-IRE'),
  insight_id uuid not null references public.gal_insights(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  event_type public.gal_insight_resolution_event_type not null,
  resolution_rule_id uuid references public.gal_insight_resolution_rules(id) on delete restrict,
  qualifying_outcome_id uuid references public.gal_insight_outcomes(id) on delete set null,
  source_system text not null check (btrim(source_system)<>''),
  source_event_key text not null check (btrim(source_event_key)<>''),
  confidence numeric(5,4) not null default 1.0000 check (confidence between 0 and 1),
  evidence jsonb not null default '{}'::jsonb check (jsonb_typeof(evidence)='object'),
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id,source_system,source_event_key)
);

create index gal_insight_resolution_state_user_idx on public.gal_insight_resolution_state(user_id,status,updated_at desc);
create index gal_insight_resolution_events_insight_idx on public.gal_insight_resolution_events(insight_id,occurred_at desc);
create index gal_insight_resolution_events_outcome_idx on public.gal_insight_resolution_events(qualifying_outcome_id) where qualifying_outcome_id is not null;

alter table public.gal_insight_resolution_rules enable row level security;
alter table public.gal_insight_resolution_state enable row level security;
alter table public.gal_insight_resolution_events enable row level security;
revoke all on public.gal_insight_resolution_rules from anon,authenticated;
revoke all on public.gal_insight_resolution_state from anon,authenticated;
revoke all on public.gal_insight_resolution_events from anon,authenticated;
grant select on public.gal_insight_resolution_state to authenticated;
create policy gal_insight_resolution_state_self_select on public.gal_insight_resolution_state
for select to authenticated using(user_id=public.gal_current_user_id());

insert into public.gal_insight_resolution_rules(
  insight_domain,insight_code,rule_code,rule_version,qualifying_outcome_type,minimum_outcome_confidence,allowed_attributions
) values(
  'bag','top_of_bag_gap','bag_gap_closed_verified','1','bag_gap_closed_verified',0.8000,
  array['OBSERVED'::public.gal_insight_outcome_attribution,'DIRECT_DECLARED'::public.gal_insight_outcome_attribution]
) on conflict do nothing;

create or replace function public.gal_apply_insight_resolution(
  p_user_id uuid,
  p_insight_id text,
  p_event_type public.gal_insight_resolution_event_type,
  p_source_system text,
  p_source_event_key text,
  p_outcome_id text default null,
  p_rule_code text default null,
  p_rule_version text default null,
  p_confidence numeric default 1.0,
  p_evidence jsonb default '{}'::jsonb,
  p_occurred_at timestamptz default now()
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_insight public.gal_insights%rowtype;
  v_state public.gal_insight_resolution_state%rowtype;
  v_existing public.gal_insight_resolution_events%rowtype;
  v_outcome public.gal_insight_outcomes%rowtype;
  v_rule public.gal_insight_resolution_rules%rowtype;
begin
  if p_user_id is null then raise exception 'p_user_id is required'; end if;
  if nullif(btrim(p_insight_id),'') is null then raise exception 'p_insight_id is required'; end if;
  if nullif(btrim(p_source_system),'') is null then raise exception 'p_source_system is required'; end if;
  if nullif(btrim(p_source_event_key),'') is null then raise exception 'p_source_event_key is required'; end if;
  if p_confidence < 0 or p_confidence > 1 then raise exception 'p_confidence must be 0..1'; end if;
  if jsonb_typeof(coalesce(p_evidence,'{}'::jsonb)) <> 'object' then raise exception 'p_evidence must be object'; end if;

  select * into v_existing from public.gal_insight_resolution_events
  where user_id=p_user_id and source_system=lower(btrim(p_source_system)) and source_event_key=btrim(p_source_event_key);
  if found then
    select * into v_state from public.gal_insight_resolution_state where insight_id=v_existing.insight_id;
    return jsonb_build_object('idempotent_replay',true,'resolution_event_id',v_existing.resolution_event_id,'status',v_state.status);
  end if;

  select * into v_insight from public.gal_insights where insight_id=p_insight_id and user_id=p_user_id for update;
  if not found then raise exception 'Insight not found for user'; end if;

  insert into public.gal_insight_resolution_state(insight_id,user_id) values(v_insight.id,p_user_id)
  on conflict(insight_id) do nothing;
  select * into v_state from public.gal_insight_resolution_state where insight_id=v_insight.id for update;

  if p_outcome_id is not null then
    select * into v_outcome from public.gal_insight_outcomes
    where outcome_id=p_outcome_id and user_id=p_user_id and insight_id=v_insight.id;
    if not found then raise exception 'Outcome does not belong to insight/user'; end if;
    if p_occurred_at < v_outcome.occurred_at then raise exception 'Resolution event cannot predate outcome'; end if;
  end if;

  if p_event_type='RESOLVED' then
    if p_outcome_id is null then raise exception 'RESOLVED requires qualifying outcome'; end if;
    select * into v_rule from public.gal_insight_resolution_rules
    where insight_domain=v_insight.insight_domain and insight_code=v_insight.insight_code
      and rule_code=lower(btrim(coalesce(p_rule_code,'')))
      and rule_version=btrim(coalesce(p_rule_version,'')) and active;
    if not found then raise exception 'Active resolution rule not found'; end if;
    if v_outcome.outcome_type<>v_rule.qualifying_outcome_type then raise exception 'Outcome type does not satisfy resolution rule'; end if;
    if v_outcome.attribution_confidence<v_rule.minimum_outcome_confidence then raise exception 'Outcome confidence below resolution threshold'; end if;
    if not (v_outcome.attribution=any(v_rule.allowed_attributions)) then raise exception 'Outcome attribution not allowed by resolution rule'; end if;

    update public.gal_insight_resolution_state set
      status='RESOLVED',resolution_rule_id=v_rule.id,qualifying_outcome_id=v_outcome.id,
      resolution_confidence=least(p_confidence,v_outcome.attribution_confidence),resolved_at=p_occurred_at,regressed_at=null,updated_at=now()
    where insight_id=v_insight.id returning * into v_state;
    update public.gal_insights set status='RESOLVED',resolved_at=coalesce(resolved_at,p_occurred_at),updated_at=now() where id=v_insight.id;

  elsif p_event_type='REGRESSED' then
    if v_state.status<>'RESOLVED' then raise exception 'Only a RESOLVED insight can regress'; end if;
    update public.gal_insight_resolution_state set status='REGRESSED',regressed_at=p_occurred_at,updated_at=now()
    where insight_id=v_insight.id returning * into v_state;
    update public.gal_insights set status='ACTIVE',resolved_at=null,updated_at=now() where id=v_insight.id;

  elsif p_event_type='INEFFECTIVE' then
    update public.gal_insight_resolution_state set status='INEFFECTIVE',qualifying_outcome_id=v_outcome.id,resolution_confidence=p_confidence,updated_at=now()
    where insight_id=v_insight.id returning * into v_state;

  else
    update public.gal_insight_resolution_state set status='EVIDENCE_PENDING',qualifying_outcome_id=v_outcome.id,resolution_confidence=p_confidence,updated_at=now()
    where insight_id=v_insight.id returning * into v_state;
  end if;

  insert into public.gal_insight_resolution_events(
    insight_id,user_id,event_type,resolution_rule_id,qualifying_outcome_id,source_system,source_event_key,confidence,evidence,occurred_at
  ) values(
    v_insight.id,p_user_id,p_event_type,v_rule.id,v_outcome.id,lower(btrim(p_source_system)),btrim(p_source_event_key),p_confidence,coalesce(p_evidence,'{}'::jsonb),p_occurred_at
  ) returning * into v_existing;

  return jsonb_build_object('idempotent_replay',false,'resolution_event_id',v_existing.resolution_event_id,'status',v_state.status,'insight_status',(select status from public.gal_insights where id=v_insight.id));
end;
$$;

revoke execute on function public.gal_apply_insight_resolution(uuid,text,public.gal_insight_resolution_event_type,text,text,text,text,text,numeric,jsonb,timestamptz) from public,anon,authenticated;
grant execute on function public.gal_apply_insight_resolution(uuid,text,public.gal_insight_resolution_event_type,text,text,text,text,text,numeric,jsonb,timestamptz) to service_role;
