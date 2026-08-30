create type public.gal_learning_candidate_status as enum ('CANDIDATE','EVALUATED','APPROVED','REJECTED','PRODUCTION','ROLLED_BACK');

create table public.gal_learning_candidates (
  id uuid primary key default gen_random_uuid(),
  learning_candidate_id text not null unique default public.gal_public_id('GAL-LRC'),
  learning_snapshot_id uuid not null references public.gal_learning_snapshots(id) on delete restrict,
  target_system text not null check (btrim(target_system)<>''),
  target_key text not null check (btrim(target_key)<>''),
  candidate_version text not null check (btrim(candidate_version)<>''),
  status public.gal_learning_candidate_status not null default 'CANDIDATE',
  proposed_change jsonb not null check (jsonb_typeof(proposed_change)='object'),
  evaluation_dataset_version text,
  holdout_sample_size integer not null default 0 check (holdout_sample_size>=0),
  minimum_holdout_sample_size integer not null default 100 check (minimum_holdout_sample_size>=100),
  primary_metric_delta numeric(10,6),
  minimum_primary_metric_delta numeric(10,6) not null default 0,
  regression_detected boolean,
  bias_check_passed boolean,
  evaluation_metrics jsonb not null default '{}'::jsonb check (jsonb_typeof(evaluation_metrics)='object'),
  evaluation_passed boolean not null default false,
  evaluated_at timestamptz,
  approved_at timestamptz,
  approved_by text,
  approval_note text,
  promoted_at timestamptz,
  rolled_back_at timestamptz,
  rollback_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(target_system,target_key,candidate_version),
  check (status not in ('APPROVED','PRODUCTION') or (evaluation_passed and approved_at is not null and approved_by is not null)),
  check (status <> 'PRODUCTION' or promoted_at is not null),
  check (status <> 'ROLLED_BACK' or (rolled_back_at is not null and rollback_reason is not null))
);

create unique index gal_learning_candidates_one_production_idx
on public.gal_learning_candidates(target_system,target_key)
where status='PRODUCTION';

alter table public.gal_learning_candidates enable row level security;
revoke all on public.gal_learning_candidates from anon,authenticated;

create or replace function public.gal_create_learning_candidate(
  p_learning_snapshot_id text,
  p_target_system text,
  p_target_key text,
  p_candidate_version text,
  p_proposed_change jsonb,
  p_minimum_holdout_sample_size integer default 100,
  p_minimum_primary_metric_delta numeric default 0
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_snapshot public.gal_learning_snapshots%rowtype;
  v_row public.gal_learning_candidates%rowtype;
begin
  if p_minimum_holdout_sample_size < 100 then raise exception 'minimum holdout sample size cannot be below 100'; end if;
  if jsonb_typeof(coalesce(p_proposed_change,'{}'::jsonb)) <> 'object' then raise exception 'proposed_change must be object'; end if;

  select * into v_snapshot
  from public.gal_learning_snapshots
  where learning_snapshot_id=p_learning_snapshot_id;
  if not found then raise exception 'Learning snapshot not found'; end if;
  if v_snapshot.status <> 'PUBLISHED' then raise exception 'Learning snapshot must be PUBLISHED'; end if;

  insert into public.gal_learning_candidates(
    learning_snapshot_id,target_system,target_key,candidate_version,proposed_change,
    minimum_holdout_sample_size,minimum_primary_metric_delta
  ) values(
    v_snapshot.id,lower(btrim(p_target_system)),lower(btrim(p_target_key)),btrim(p_candidate_version),
    p_proposed_change,p_minimum_holdout_sample_size,p_minimum_primary_metric_delta
  ) returning * into v_row;

  return jsonb_build_object('learning_candidate_id',v_row.learning_candidate_id,'status',v_row.status);
end;
$$;

create or replace function public.gal_record_learning_candidate_evaluation(
  p_learning_candidate_id text,
  p_evaluation_dataset_version text,
  p_holdout_sample_size integer,
  p_primary_metric_delta numeric,
  p_regression_detected boolean,
  p_bias_check_passed boolean,
  p_evaluation_metrics jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_row public.gal_learning_candidates%rowtype;
  v_pass boolean;
begin
  select * into v_row
  from public.gal_learning_candidates
  where learning_candidate_id=p_learning_candidate_id
  for update;
  if not found then raise exception 'Learning candidate not found'; end if;
  if v_row.status not in ('CANDIDATE','EVALUATED') then raise exception 'Candidate is not evaluable in status %',v_row.status; end if;
  if nullif(btrim(p_evaluation_dataset_version),'') is null then raise exception 'evaluation dataset version required'; end if;
  if p_holdout_sample_size < 0 then raise exception 'holdout sample size must be nonnegative'; end if;
  if p_regression_detected is null or p_bias_check_passed is null then raise exception 'regression and bias checks are required'; end if;
  if jsonb_typeof(coalesce(p_evaluation_metrics,'{}'::jsonb)) <> 'object' then raise exception 'evaluation_metrics must be object'; end if;

  v_pass := p_holdout_sample_size >= v_row.minimum_holdout_sample_size
    and not p_regression_detected
    and p_bias_check_passed
    and p_primary_metric_delta >= v_row.minimum_primary_metric_delta;

  update public.gal_learning_candidates set
    status='EVALUATED',
    evaluation_dataset_version=btrim(p_evaluation_dataset_version),
    holdout_sample_size=p_holdout_sample_size,
    primary_metric_delta=p_primary_metric_delta,
    regression_detected=p_regression_detected,
    bias_check_passed=p_bias_check_passed,
    evaluation_metrics=coalesce(p_evaluation_metrics,'{}'::jsonb),
    evaluation_passed=v_pass,
    evaluated_at=now(),
    updated_at=now()
  where id=v_row.id
  returning * into v_row;

  return jsonb_build_object(
    'learning_candidate_id',v_row.learning_candidate_id,
    'status',v_row.status,
    'evaluation_passed',v_row.evaluation_passed
  );
end;
$$;

create or replace function public.gal_govern_learning_candidate(
  p_learning_candidate_id text,
  p_action text,
  p_actor text,
  p_note text default null
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_row public.gal_learning_candidates%rowtype;
  v_action text := upper(btrim(p_action));
begin
  if nullif(btrim(p_actor),'') is null then raise exception 'actor required'; end if;

  select * into v_row
  from public.gal_learning_candidates
  where learning_candidate_id=p_learning_candidate_id
  for update;
  if not found then raise exception 'Learning candidate not found'; end if;

  if v_action='APPROVE' then
    if v_row.status<>'EVALUATED' or not v_row.evaluation_passed then
      raise exception 'Only a passing EVALUATED candidate can be approved';
    end if;
    update public.gal_learning_candidates
    set status='APPROVED',approved_at=now(),approved_by=btrim(p_actor),approval_note=p_note,updated_at=now()
    where id=v_row.id returning * into v_row;

  elsif v_action='REJECT' then
    if v_row.status not in ('CANDIDATE','EVALUATED') then
      raise exception 'Candidate cannot be rejected from status %',v_row.status;
    end if;
    update public.gal_learning_candidates
    set status='REJECTED',approval_note=p_note,updated_at=now()
    where id=v_row.id returning * into v_row;

  elsif v_action='PROMOTE' then
    if v_row.status<>'APPROVED' then raise exception 'Only APPROVED candidate can be promoted'; end if;
    update public.gal_learning_candidates
    set status='PRODUCTION',promoted_at=now(),updated_at=now()
    where id=v_row.id returning * into v_row;

  elsif v_action='ROLLBACK' then
    if v_row.status<>'PRODUCTION' then raise exception 'Only PRODUCTION candidate can be rolled back'; end if;
    if nullif(btrim(p_note),'') is null then raise exception 'rollback reason required'; end if;
    update public.gal_learning_candidates
    set status='ROLLED_BACK',rolled_back_at=now(),rollback_reason=btrim(p_note),updated_at=now()
    where id=v_row.id returning * into v_row;

  else
    raise exception 'Unsupported action %',v_action;
  end if;

  return jsonb_build_object(
    'learning_candidate_id',v_row.learning_candidate_id,
    'status',v_row.status,
    'evaluation_passed',v_row.evaluation_passed
  );
end;
$$;

revoke execute on function public.gal_create_learning_candidate(text,text,text,text,jsonb,integer,numeric) from public,anon,authenticated;
revoke execute on function public.gal_record_learning_candidate_evaluation(text,text,integer,numeric,boolean,boolean,jsonb) from public,anon,authenticated;
revoke execute on function public.gal_govern_learning_candidate(text,text,text,text) from public,anon,authenticated;

grant execute on function public.gal_create_learning_candidate(text,text,text,text,jsonb,integer,numeric) to service_role;
grant execute on function public.gal_record_learning_candidate_evaluation(text,text,integer,numeric,boolean,boolean,jsonb) to service_role;
grant execute on function public.gal_govern_learning_candidate(text,text,text,text) to service_role;
