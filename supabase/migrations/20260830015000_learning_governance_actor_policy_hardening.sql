create type public.gal_governance_actor_role as enum ('REVIEWER','APPROVER','RELEASE_MANAGER');

create table public.gal_governance_actors (
  id uuid primary key default gen_random_uuid(),
  governance_actor_id text not null unique default public.gal_public_id('GAL-GOV'),
  auth_user_id uuid not null unique references auth.users(id) on delete restrict,
  actor_role public.gal_governance_actor_role not null,
  display_name text not null check (btrim(display_name)<>''),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.gal_learning_evaluation_policies (
  id uuid primary key default gen_random_uuid(),
  evaluation_policy_id text not null unique default public.gal_public_id('GAL-LEP'),
  target_system text not null check (btrim(target_system)<>''),
  target_key text not null check (btrim(target_key)<>''),
  policy_version text not null check (btrim(policy_version)<>''),
  primary_metric_name text not null check (btrim(primary_metric_name)<>''),
  minimum_holdout_sample_size integer not null check (minimum_holdout_sample_size>=100),
  minimum_primary_metric_delta numeric(10,6) not null default 0,
  required_segments jsonb not null default '[]'::jsonb check (jsonb_typeof(required_segments)='array'),
  required_bias_checks jsonb not null default '[]'::jsonb check (jsonb_typeof(required_bias_checks)='array'),
  active boolean not null default true,
  governance_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(target_system,target_key,policy_version)
);

alter table public.gal_governance_actors enable row level security;
alter table public.gal_learning_evaluation_policies enable row level security;
revoke all on public.gal_governance_actors from anon,authenticated;
revoke all on public.gal_learning_evaluation_policies from anon,authenticated;
grant select on public.gal_governance_actors to service_role;
grant select on public.gal_learning_evaluation_policies to service_role;

alter table public.gal_learning_candidates
  add column evaluation_policy_id uuid references public.gal_learning_evaluation_policies(id) on delete restrict,
  add column evaluation_actor_id uuid references public.gal_governance_actors(id) on delete restrict,
  add column approved_by_actor_id uuid references public.gal_governance_actors(id) on delete restrict,
  add column primary_metric_name text,
  add column regression_check jsonb not null default '{}'::jsonb check (jsonb_typeof(regression_check)='object'),
  add column bias_check jsonb not null default '{}'::jsonb check (jsonb_typeof(bias_check)='object');

alter table public.gal_learning_candidates add constraint gal_learning_candidates_governed_approval_check
check (status not in ('APPROVED','PRODUCTION') or approved_by_actor_id is not null) not valid;
alter table public.gal_learning_candidates validate constraint gal_learning_candidates_governed_approval_check;

create index gal_learning_candidates_policy_idx on public.gal_learning_candidates(evaluation_policy_id) where evaluation_policy_id is not null;
create index gal_learning_candidates_evaluator_idx on public.gal_learning_candidates(evaluation_actor_id) where evaluation_actor_id is not null;
create index gal_learning_candidates_approver_idx on public.gal_learning_candidates(approved_by_actor_id) where approved_by_actor_id is not null;

insert into public.gal_learning_evaluation_policies(
  target_system,target_key,policy_version,primary_metric_name,minimum_holdout_sample_size,minimum_primary_metric_delta,
  required_segments,required_bias_checks,governance_note
) values(
  'recommendation_engine','top_of_bag_ranker','1','resolution_rate',100,0.010000,
  '["handicap_band","swing_speed_band"]'::jsonb,'["segment_parity","calibration"]'::jsonb,
  'Initial governed policy: learning must improve verified insight resolution, not click-through alone.'
) on conflict do nothing;

revoke execute on function public.gal_create_learning_candidate(text,text,text,text,jsonb,integer,numeric) from service_role;
revoke execute on function public.gal_record_learning_candidate_evaluation(text,text,integer,numeric,boolean,boolean,jsonb) from service_role;
revoke execute on function public.gal_govern_learning_candidate(text,text,text,text) from service_role;

create or replace function public.gal_create_learning_candidate_v2(
  p_learning_snapshot_id text,
  p_target_system text,
  p_target_key text,
  p_candidate_version text,
  p_proposed_change jsonb,
  p_evaluation_policy_id text
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_snapshot public.gal_learning_snapshots%rowtype;
  v_policy public.gal_learning_evaluation_policies%rowtype;
  v_row public.gal_learning_candidates%rowtype;
begin
  if jsonb_typeof(coalesce(p_proposed_change,'{}'::jsonb))<>'object' then raise exception 'proposed_change must be object'; end if;
  select * into v_snapshot from public.gal_learning_snapshots where learning_snapshot_id=p_learning_snapshot_id;
  if not found or v_snapshot.status<>'PUBLISHED' then raise exception 'Learning snapshot must exist and be PUBLISHED'; end if;
  select * into v_policy from public.gal_learning_evaluation_policies where evaluation_policy_id=p_evaluation_policy_id and active;
  if not found then raise exception 'Active evaluation policy not found'; end if;
  if v_policy.target_system<>lower(btrim(p_target_system)) or v_policy.target_key<>lower(btrim(p_target_key)) then raise exception 'Evaluation policy does not match target'; end if;

  insert into public.gal_learning_candidates(
    learning_snapshot_id,target_system,target_key,candidate_version,proposed_change,evaluation_policy_id,
    minimum_holdout_sample_size,minimum_primary_metric_delta,primary_metric_name
  ) values(
    v_snapshot.id,v_policy.target_system,v_policy.target_key,btrim(p_candidate_version),p_proposed_change,v_policy.id,
    v_policy.minimum_holdout_sample_size,v_policy.minimum_primary_metric_delta,v_policy.primary_metric_name
  ) returning * into v_row;
  return jsonb_build_object('learning_candidate_id',v_row.learning_candidate_id,'status',v_row.status,'evaluation_policy_id',v_policy.evaluation_policy_id);
end;
$$;

create or replace function public.gal_record_learning_candidate_evaluation_v2(
  p_learning_candidate_id text,
  p_evaluator_actor_id text,
  p_evaluation_dataset_version text,
  p_holdout_sample_size integer,
  p_primary_metric_name text,
  p_primary_metric_delta numeric,
  p_regression_check jsonb,
  p_bias_check jsonb,
  p_evaluation_metrics jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_row public.gal_learning_candidates%rowtype;
  v_actor public.gal_governance_actors%rowtype;
  v_policy public.gal_learning_evaluation_policies%rowtype;
  v_reg_pass boolean;
  v_bias_pass boolean;
  v_pass boolean;
begin
  select * into v_row from public.gal_learning_candidates where learning_candidate_id=p_learning_candidate_id for update;
  if not found then raise exception 'Learning candidate not found'; end if;
  if v_row.status not in ('CANDIDATE','EVALUATED') then raise exception 'Candidate is not evaluable in status %',v_row.status; end if;
  select * into v_actor from public.gal_governance_actors where governance_actor_id=p_evaluator_actor_id and active;
  if not found or v_actor.actor_role not in ('REVIEWER','APPROVER','RELEASE_MANAGER') then raise exception 'Active reviewer governance actor required'; end if;
  select * into v_policy from public.gal_learning_evaluation_policies where id=v_row.evaluation_policy_id and active;
  if not found then raise exception 'Candidate has no active evaluation policy'; end if;
  if nullif(btrim(p_evaluation_dataset_version),'') is null then raise exception 'evaluation dataset version required'; end if;
  if lower(btrim(p_primary_metric_name))<>lower(v_policy.primary_metric_name) then raise exception 'Primary metric does not match governed policy'; end if;
  if jsonb_typeof(coalesce(p_regression_check,'{}'::jsonb))<>'object' or jsonb_typeof(coalesce(p_bias_check,'{}'::jsonb))<>'object' then raise exception 'Structured regression and bias checks are required'; end if;
  if jsonb_typeof(coalesce(p_evaluation_metrics,'{}'::jsonb))<>'object' then raise exception 'evaluation_metrics must be object'; end if;
  if not (p_regression_check ? 'passed') or not (p_bias_check ? 'passed') then raise exception 'Regression and bias checks require passed booleans'; end if;
  v_reg_pass:=(p_regression_check->>'passed')::boolean;
  v_bias_pass:=(p_bias_check->>'passed')::boolean;
  if not (coalesce(p_regression_check->'segments','[]'::jsonb) @> v_policy.required_segments) then raise exception 'Required regression segments were not evaluated'; end if;
  if not (coalesce(p_bias_check->'checks','[]'::jsonb) @> v_policy.required_bias_checks) then raise exception 'Required bias checks were not evaluated'; end if;

  v_pass:=p_holdout_sample_size>=v_policy.minimum_holdout_sample_size
    and p_primary_metric_delta>=v_policy.minimum_primary_metric_delta
    and v_reg_pass and v_bias_pass;

  update public.gal_learning_candidates set
    status='EVALUATED',evaluation_actor_id=v_actor.id,evaluation_dataset_version=btrim(p_evaluation_dataset_version),
    holdout_sample_size=p_holdout_sample_size,primary_metric_name=v_policy.primary_metric_name,primary_metric_delta=p_primary_metric_delta,
    regression_detected=not v_reg_pass,bias_check_passed=v_bias_pass,regression_check=p_regression_check,bias_check=p_bias_check,
    evaluation_metrics=coalesce(p_evaluation_metrics,'{}'::jsonb),evaluation_passed=v_pass,evaluated_at=now(),updated_at=now()
  where id=v_row.id returning * into v_row;

  return jsonb_build_object('learning_candidate_id',v_row.learning_candidate_id,'status',v_row.status,'evaluation_passed',v_row.evaluation_passed,'evaluation_policy_id',v_policy.evaluation_policy_id);
end;
$$;

create or replace function public.gal_govern_learning_candidate_v2(
  p_learning_candidate_id text,
  p_action text,
  p_actor_id text,
  p_note text default null
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_row public.gal_learning_candidates%rowtype;
  v_actor public.gal_governance_actors%rowtype;
  v_action text:=upper(btrim(p_action));
begin
  select * into v_actor from public.gal_governance_actors where governance_actor_id=p_actor_id and active;
  if not found then raise exception 'Active governance actor required'; end if;
  select * into v_row from public.gal_learning_candidates where learning_candidate_id=p_learning_candidate_id for update;
  if not found then raise exception 'Learning candidate not found'; end if;

  if v_action='APPROVE' then
    if v_actor.actor_role not in ('APPROVER','RELEASE_MANAGER') then raise exception 'APPROVE requires APPROVER or RELEASE_MANAGER'; end if;
    if v_row.status<>'EVALUATED' or not v_row.evaluation_passed or v_row.evaluation_actor_id is null or v_row.evaluation_policy_id is null then raise exception 'Only a governed passing EVALUATED candidate can be approved'; end if;
    update public.gal_learning_candidates set status='APPROVED',approved_at=now(),approved_by=v_actor.governance_actor_id,approved_by_actor_id=v_actor.id,approval_note=p_note,updated_at=now() where id=v_row.id returning * into v_row;
  elsif v_action='REJECT' then
    if v_actor.actor_role not in ('APPROVER','RELEASE_MANAGER') then raise exception 'REJECT requires APPROVER or RELEASE_MANAGER'; end if;
    if v_row.status not in ('CANDIDATE','EVALUATED') then raise exception 'Candidate cannot be rejected from status %',v_row.status; end if;
    update public.gal_learning_candidates set status='REJECTED',approved_by=v_actor.governance_actor_id,approved_by_actor_id=v_actor.id,approval_note=p_note,updated_at=now() where id=v_row.id returning * into v_row;
  elsif v_action='PROMOTE' then
    if v_actor.actor_role<>'RELEASE_MANAGER' then raise exception 'PROMOTE requires RELEASE_MANAGER'; end if;
    if v_row.status<>'APPROVED' then raise exception 'Only APPROVED candidate can be promoted'; end if;
    update public.gal_learning_candidates set status='PRODUCTION',promoted_at=now(),updated_at=now() where id=v_row.id returning * into v_row;
  elsif v_action='ROLLBACK' then
    if v_actor.actor_role<>'RELEASE_MANAGER' then raise exception 'ROLLBACK requires RELEASE_MANAGER'; end if;
    if v_row.status<>'PRODUCTION' then raise exception 'Only PRODUCTION candidate can be rolled back'; end if;
    if nullif(btrim(p_note),'') is null then raise exception 'rollback reason required'; end if;
    update public.gal_learning_candidates set status='ROLLED_BACK',rolled_back_at=now(),rollback_reason=btrim(p_note),updated_at=now() where id=v_row.id returning * into v_row;
  else raise exception 'Unsupported action %',v_action;
  end if;
  return jsonb_build_object('learning_candidate_id',v_row.learning_candidate_id,'status',v_row.status,'actor_id',v_actor.governance_actor_id);
end;
$$;

revoke execute on function public.gal_create_learning_candidate_v2(text,text,text,text,jsonb,text) from public,anon,authenticated;
revoke execute on function public.gal_record_learning_candidate_evaluation_v2(text,text,text,integer,text,numeric,jsonb,jsonb,jsonb) from public,anon,authenticated;
revoke execute on function public.gal_govern_learning_candidate_v2(text,text,text,text) from public,anon,authenticated;
grant execute on function public.gal_create_learning_candidate_v2(text,text,text,text,jsonb,text) to service_role;
grant execute on function public.gal_record_learning_candidate_evaluation_v2(text,text,text,integer,text,numeric,jsonb,jsonb,jsonb) to service_role;
grant execute on function public.gal_govern_learning_candidate_v2(text,text,text,text) to service_role;
