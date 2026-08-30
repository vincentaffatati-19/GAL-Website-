create type public.gal_insight_outcome_attribution as enum ('OBSERVED','ASSISTED','DIRECT_DECLARED');

create table public.gal_insight_outcomes (
  id uuid primary key default gen_random_uuid(),
  outcome_id text not null unique default public.gal_public_id('GAL-OUT'),
  insight_id uuid not null references public.gal_insights(id) on delete cascade,
  response_id uuid references public.gal_insight_responses(id) on delete set null,
  buyer_event_id uuid references public.gal_buyer_events(id) on delete set null,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  outcome_type text not null check (btrim(outcome_type) <> ''),
  attribution public.gal_insight_outcome_attribution not null default 'OBSERVED',
  attribution_confidence numeric(5,4) not null default 0.5000 check (attribution_confidence between 0 and 1),
  attribution_model_version text not null check (btrim(attribution_model_version) <> ''),
  source_system text not null check (btrim(source_system) <> ''),
  source_event_key text not null check (btrim(source_event_key) <> ''),
  occurred_at timestamptz not null,
  evidence jsonb not null default '{}'::jsonb check (jsonb_typeof(evidence)='object'),
  created_at timestamptz not null default now(),
  constraint gal_insight_outcomes_idempotency unique(user_id,source_system,source_event_key)
);

create index gal_insight_outcomes_insight_idx on public.gal_insight_outcomes(insight_id,occurred_at desc);
create index gal_insight_outcomes_user_idx on public.gal_insight_outcomes(user_id,outcome_type,occurred_at desc);

alter table public.gal_insight_outcomes enable row level security;
revoke all on public.gal_insight_outcomes from anon,authenticated;
grant select on public.gal_insight_outcomes to authenticated;

create policy gal_insight_outcomes_self_select on public.gal_insight_outcomes
for select to authenticated
using(user_id=public.gal_current_user_id());

create or replace function public.gal_record_insight_outcome(
  p_user_id uuid,
  p_insight_id text,
  p_outcome_type text,
  p_attribution public.gal_insight_outcome_attribution,
  p_attribution_confidence numeric,
  p_attribution_model_version text,
  p_source_system text,
  p_source_event_key text,
  p_occurred_at timestamptz,
  p_response_id text default null,
  p_buyer_event_id uuid default null,
  p_evidence jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_insight public.gal_insights%rowtype;
  v_response public.gal_insight_responses%rowtype;
  v_buyer public.gal_buyer_events%rowtype;
  v_existing public.gal_insight_outcomes%rowtype;
  v_outcome public.gal_insight_outcomes%rowtype;
begin
  if p_user_id is null then raise exception 'p_user_id is required'; end if;
  if nullif(btrim(p_insight_id),'') is null then raise exception 'p_insight_id is required'; end if;
  if nullif(btrim(p_outcome_type),'') is null then raise exception 'p_outcome_type is required'; end if;
  if p_attribution_confidence < 0 or p_attribution_confidence > 1 then raise exception 'attribution confidence must be 0..1'; end if;
  if nullif(btrim(p_attribution_model_version),'') is null then raise exception 'attribution model version required'; end if;
  if nullif(btrim(p_source_system),'') is null then raise exception 'p_source_system is required'; end if;
  if nullif(btrim(p_source_event_key),'') is null then raise exception 'p_source_event_key is required'; end if;
  if jsonb_typeof(coalesce(p_evidence,'{}'::jsonb)) <> 'object' then raise exception 'evidence must be object'; end if;

  select * into v_existing
  from public.gal_insight_outcomes
  where user_id=p_user_id
    and source_system=lower(btrim(p_source_system))
    and source_event_key=btrim(p_source_event_key);
  if found then
    return jsonb_build_object('idempotent_replay',true,'outcome_id',v_existing.outcome_id,'attribution',v_existing.attribution,'confidence',v_existing.attribution_confidence);
  end if;

  select * into v_insight
  from public.gal_insights
  where insight_id=p_insight_id and user_id=p_user_id;
  if not found then raise exception 'Insight not found for user'; end if;

  if p_response_id is not null then
    select * into v_response
    from public.gal_insight_responses
    where response_id=p_response_id and user_id=p_user_id and insight_id=v_insight.id;
    if not found then raise exception 'Response does not belong to insight/user'; end if;
    if p_occurred_at < v_response.occurred_at then raise exception 'Outcome cannot predate response'; end if;
  end if;

  if p_buyer_event_id is not null then
    select * into v_buyer
    from public.gal_buyer_events
    where id=p_buyer_event_id and user_id=p_user_id;
    if not found then raise exception 'Buyer event does not belong to user'; end if;
    if p_occurred_at < v_buyer.occurred_at then raise exception 'Outcome cannot predate buyer event'; end if;
  end if;

  insert into public.gal_insight_outcomes(
    insight_id,response_id,buyer_event_id,user_id,outcome_type,attribution,attribution_confidence,
    attribution_model_version,source_system,source_event_key,occurred_at,evidence
  ) values(
    v_insight.id,v_response.id,p_buyer_event_id,p_user_id,lower(btrim(p_outcome_type)),p_attribution,p_attribution_confidence,
    btrim(p_attribution_model_version),lower(btrim(p_source_system)),btrim(p_source_event_key),p_occurred_at,coalesce(p_evidence,'{}'::jsonb)
  ) returning * into v_outcome;

  return jsonb_build_object('idempotent_replay',false,'outcome_id',v_outcome.outcome_id,'attribution',v_outcome.attribution,'confidence',v_outcome.attribution_confidence);
end;
$$;

revoke execute on function public.gal_record_insight_outcome(uuid,text,text,public.gal_insight_outcome_attribution,numeric,text,text,text,timestamptz,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.gal_record_insight_outcome(uuid,text,text,public.gal_insight_outcome_attribution,numeric,text,text,text,timestamptz,text,uuid,jsonb) to service_role;
