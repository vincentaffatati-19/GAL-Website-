create table public.gal_learning_snapshot_contributors (
  learning_snapshot_id uuid not null references public.gal_learning_snapshots(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  contributed_at timestamptz not null default now(),
  primary key(learning_snapshot_id,user_id)
);

create table public.gal_learning_consent_reconciliations (
  id uuid primary key default gen_random_uuid(),
  reconciliation_id text not null unique default public.gal_public_id('GAL-LCR'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  source_system text not null check (btrim(source_system)<>''),
  source_event_key text not null check (btrim(source_event_key)<>''),
  impacted_snapshot_count integer not null default 0 check (impacted_snapshot_count>=0),
  invalidated_candidate_count integer not null default 0 check (invalidated_candidate_count>=0),
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id,source_system,source_event_key)
);

create index gal_learning_snapshot_contributors_user_idx on public.gal_learning_snapshot_contributors(user_id,learning_snapshot_id);

alter table public.gal_learning_snapshot_contributors enable row level security;
alter table public.gal_learning_consent_reconciliations enable row level security;
revoke all on public.gal_learning_snapshot_contributors from anon,authenticated;
revoke all on public.gal_learning_consent_reconciliations from anon,authenticated;
grant select,insert,update,delete on public.gal_learning_snapshot_contributors to service_role;
grant select,insert on public.gal_learning_consent_reconciliations to service_role;

create or replace function public.gal_build_learning_snapshot(
  p_outcome_type text,
  p_window_start timestamptz,
  p_window_end timestamptz,
  p_insight_domain text default null,
  p_insight_code text default null,
  p_subject_type text default null,
  p_subject_key text default null,
  p_scope_key text default null,
  p_minimum_cohort_size integer default 10,
  p_aggregation_version text default '1',
  p_governance_version text default '1'
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_dimensions jsonb;
  v_key text;
  v_users integer;
  v_outcomes integer;
  v_observed integer;
  v_assisted integer;
  v_direct integer;
  v_avg numeric(5,4);
  v_status public.gal_learning_snapshot_status;
  v_row public.gal_learning_snapshots%rowtype;
begin
  if nullif(btrim(p_outcome_type),'') is null then raise exception 'p_outcome_type is required'; end if;
  if p_window_end <= p_window_start then raise exception 'window_end must be after window_start'; end if;
  if p_minimum_cohort_size < 10 then raise exception 'minimum cohort size cannot be below 10'; end if;
  if nullif(btrim(p_aggregation_version),'') is null then raise exception 'aggregation version required'; end if;
  if nullif(btrim(p_governance_version),'') is null then raise exception 'governance version required'; end if;

  v_dimensions := jsonb_strip_nulls(jsonb_build_object(
    'insight_domain',case when p_insight_domain is null then null else lower(btrim(p_insight_domain)) end,
    'insight_code',case when p_insight_code is null then null else lower(btrim(p_insight_code)) end,
    'subject_type',case when p_subject_type is null then null else lower(btrim(p_subject_type)) end,
    'subject_key',case when p_subject_key is null then null else lower(btrim(p_subject_key)) end,
    'scope_key',case when p_scope_key is null then null else lower(btrim(p_scope_key)) end
  ));

  v_key := public.gal_learning_cohort_key(p_outcome_type,v_dimensions,p_window_start,p_window_end,p_aggregation_version);

  with latest_consent as (
    select distinct on (user_id) user_id,status
    from public.gal_consent_records
    where consent_type='ANALYTICS_OPTIONAL'
    order by user_id,recorded_at desc,id desc
  ), eligible as (
    select o.*
    from public.gal_insight_outcomes o
    join public.gal_insights i on i.id=o.insight_id
    join latest_consent c on c.user_id=o.user_id and c.status='ACCEPTED'
    where lower(o.outcome_type)=lower(btrim(p_outcome_type))
      and o.occurred_at >= p_window_start and o.occurred_at < p_window_end
      and (p_insight_domain is null or i.insight_domain=lower(btrim(p_insight_domain)))
      and (p_insight_code is null or i.insight_code=lower(btrim(p_insight_code)))
      and (p_subject_type is null or i.subject_type=lower(btrim(p_subject_type)))
      and (p_subject_key is null or i.subject_key=lower(btrim(p_subject_key)))
      and (p_scope_key is null or i.scope_key=lower(btrim(p_scope_key)))
  )
  select count(distinct user_id),count(*),
    count(*) filter(where attribution='OBSERVED'),
    count(*) filter(where attribution='ASSISTED'),
    count(*) filter(where attribution='DIRECT_DECLARED'),
    round(avg(attribution_confidence),4)
  into v_users,v_outcomes,v_observed,v_assisted,v_direct,v_avg from eligible;

  v_status := case when v_users >= p_minimum_cohort_size then 'DRAFT' else 'WITHHELD' end;

  insert into public.gal_learning_snapshots(
    cohort_key,status,outcome_type,dimensions,window_start,window_end,minimum_cohort_size,
    eligible_user_count,outcome_count,observed_count,assisted_count,direct_declared_count,
    average_attribution_confidence,aggregation_version,governance_version
  ) values(
    v_key,v_status,lower(btrim(p_outcome_type)),v_dimensions,p_window_start,p_window_end,p_minimum_cohort_size,
    v_users,v_outcomes,v_observed,v_assisted,v_direct,v_avg,btrim(p_aggregation_version),btrim(p_governance_version)
  )
  on conflict(cohort_key) do update set
    status=excluded.status,published_at=null,
    eligible_user_count=excluded.eligible_user_count,outcome_count=excluded.outcome_count,
    observed_count=excluded.observed_count,assisted_count=excluded.assisted_count,direct_declared_count=excluded.direct_declared_count,
    average_attribution_confidence=excluded.average_attribution_confidence,governance_version=excluded.governance_version,generated_at=now()
  returning * into v_row;

  delete from public.gal_learning_snapshot_contributors where learning_snapshot_id=v_row.id;
  with latest_consent as (
    select distinct on (user_id) user_id,status
    from public.gal_consent_records where consent_type='ANALYTICS_OPTIONAL'
    order by user_id,recorded_at desc,id desc
  )
  insert into public.gal_learning_snapshot_contributors(learning_snapshot_id,user_id)
  select distinct v_row.id,o.user_id
  from public.gal_insight_outcomes o
  join public.gal_insights i on i.id=o.insight_id
  join latest_consent c on c.user_id=o.user_id and c.status='ACCEPTED'
  where lower(o.outcome_type)=lower(btrim(p_outcome_type))
    and o.occurred_at >= p_window_start and o.occurred_at < p_window_end
    and (p_insight_domain is null or i.insight_domain=lower(btrim(p_insight_domain)))
    and (p_insight_code is null or i.insight_code=lower(btrim(p_insight_code)))
    and (p_subject_type is null or i.subject_type=lower(btrim(p_subject_type)))
    and (p_subject_key is null or i.subject_key=lower(btrim(p_subject_key)))
    and (p_scope_key is null or i.scope_key=lower(btrim(p_scope_key)));

  return jsonb_build_object('learning_snapshot_id',v_row.learning_snapshot_id,'status',v_row.status,'eligible_user_count',v_row.eligible_user_count,'outcome_count',v_row.outcome_count,'cohort_key',v_row.cohort_key);
end;
$$;

create or replace function public.gal_reconcile_learning_after_consent_withdrawal(
  p_user_id uuid,
  p_source_system text,
  p_source_event_key text,
  p_occurred_at timestamptz default now()
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_existing public.gal_learning_consent_reconciliations%rowtype;
  v_latest public.gal_consent_status;
  v_snapshot public.gal_learning_snapshots%rowtype;
  v_impacted integer:=0;
  v_invalidated integer:=0;
  v_count integer:=0;
begin
  if p_user_id is null then raise exception 'p_user_id is required'; end if;
  if nullif(btrim(p_source_system),'') is null or nullif(btrim(p_source_event_key),'') is null then raise exception 'source system/event key required'; end if;

  select * into v_existing from public.gal_learning_consent_reconciliations
  where user_id=p_user_id and source_system=lower(btrim(p_source_system)) and source_event_key=btrim(p_source_event_key);
  if found then return jsonb_build_object('idempotent_replay',true,'impacted_snapshot_count',v_existing.impacted_snapshot_count,'invalidated_candidate_count',v_existing.invalidated_candidate_count); end if;

  select status into v_latest from public.gal_consent_records
  where user_id=p_user_id and consent_type='ANALYTICS_OPTIONAL'
  order by recorded_at desc,id desc limit 1;
  if v_latest is null or v_latest='ACCEPTED' then raise exception 'Latest optional analytics consent is still ACCEPTED or absent'; end if;

  for v_snapshot in
    select s.* from public.gal_learning_snapshots s
    join public.gal_learning_snapshot_contributors c on c.learning_snapshot_id=s.id
    where c.user_id=p_user_id and s.status in ('PUBLISHED','DRAFT')
    for update of s
  loop
    v_impacted:=v_impacted+1;

    update public.gal_learning_candidates set
      status=case when status='PRODUCTION' then 'ROLLED_BACK'::public.gal_learning_candidate_status else 'REJECTED'::public.gal_learning_candidate_status end,
      rolled_back_at=case when status='PRODUCTION' then p_occurred_at else rolled_back_at end,
      rollback_reason=case when status='PRODUCTION' then 'Source learning snapshot invalidated by analytics consent withdrawal' else rollback_reason end,
      approval_note=case when status in ('CANDIDATE','EVALUATED','APPROVED') then concat_ws(' | ',approval_note,'Source snapshot invalidated by analytics consent withdrawal') else approval_note end,
      updated_at=now()
    where learning_snapshot_id=v_snapshot.id and status in ('CANDIDATE','EVALUATED','APPROVED','PRODUCTION');
    get diagnostics v_count=row_count; v_invalidated:=v_invalidated+v_count;

    perform public.gal_build_learning_snapshot(
      v_snapshot.outcome_type,v_snapshot.window_start,v_snapshot.window_end,
      v_snapshot.dimensions->>'insight_domain',v_snapshot.dimensions->>'insight_code',v_snapshot.dimensions->>'subject_type',
      v_snapshot.dimensions->>'subject_key',v_snapshot.dimensions->>'scope_key',v_snapshot.minimum_cohort_size,
      v_snapshot.aggregation_version,v_snapshot.governance_version
    );
  end loop;

  insert into public.gal_learning_consent_reconciliations(user_id,source_system,source_event_key,impacted_snapshot_count,invalidated_candidate_count,occurred_at)
  values(p_user_id,lower(btrim(p_source_system)),btrim(p_source_event_key),v_impacted,v_invalidated,p_occurred_at)
  returning * into v_existing;

  return jsonb_build_object('idempotent_replay',false,'reconciliation_id',v_existing.reconciliation_id,'impacted_snapshot_count',v_impacted,'invalidated_candidate_count',v_invalidated);
end;
$$;

revoke execute on function public.gal_reconcile_learning_after_consent_withdrawal(uuid,text,text,timestamptz) from public,anon,authenticated;
grant execute on function public.gal_reconcile_learning_after_consent_withdrawal(uuid,text,text,timestamptz) to service_role;
