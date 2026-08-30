create type public.gal_learning_snapshot_status as enum ('DRAFT','PUBLISHED','WITHHELD');

create table public.gal_learning_snapshots (
  id uuid primary key default gen_random_uuid(),
  learning_snapshot_id text not null unique default public.gal_public_id('GAL-LRN'),
  cohort_key text not null unique,
  status public.gal_learning_snapshot_status not null default 'DRAFT',
  outcome_type text not null,
  dimensions jsonb not null default '{}'::jsonb check (jsonb_typeof(dimensions)='object'),
  window_start timestamptz not null,
  window_end timestamptz not null,
  minimum_cohort_size integer not null default 10 check (minimum_cohort_size >= 10),
  eligible_user_count integer not null check (eligible_user_count >= 0),
  outcome_count integer not null check (outcome_count >= 0),
  observed_count integer not null check (observed_count >= 0),
  assisted_count integer not null check (assisted_count >= 0),
  direct_declared_count integer not null check (direct_declared_count >= 0),
  average_attribution_confidence numeric(5,4),
  aggregation_version text not null check (btrim(aggregation_version) <> ''),
  governance_version text not null check (btrim(governance_version) <> ''),
  generated_at timestamptz not null default now(),
  published_at timestamptz,
  check (window_end > window_start),
  check (status <> 'PUBLISHED' or eligible_user_count >= minimum_cohort_size)
);

alter table public.gal_learning_snapshots enable row level security;
revoke all on public.gal_learning_snapshots from anon, authenticated;

create or replace function public.gal_learning_cohort_key(
  p_outcome_type text,
  p_dimensions jsonb,
  p_window_start timestamptz,
  p_window_end timestamptz,
  p_aggregation_version text
) returns text
language sql
immutable
security invoker
set search_path=''
as $$
  select encode(
    extensions.digest(
      convert_to(
        jsonb_build_array(
          lower(btrim(p_outcome_type)),
          coalesce(p_dimensions,'{}'::jsonb),
          p_window_start,
          p_window_end,
          btrim(p_aggregation_version)
        )::text,
        'UTF8'
      ),
      'sha256'
    ),
    'hex'
  )
$$;

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

  v_key := public.gal_learning_cohort_key(
    p_outcome_type,v_dimensions,p_window_start,p_window_end,p_aggregation_version
  );

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
      and o.occurred_at >= p_window_start
      and o.occurred_at < p_window_end
      and (p_insight_domain is null or i.insight_domain=lower(btrim(p_insight_domain)))
      and (p_insight_code is null or i.insight_code=lower(btrim(p_insight_code)))
      and (p_subject_type is null or i.subject_type=lower(btrim(p_subject_type)))
      and (p_subject_key is null or i.subject_key=lower(btrim(p_subject_key)))
      and (p_scope_key is null or i.scope_key=lower(btrim(p_scope_key)))
  )
  select
    count(distinct user_id),
    count(*),
    count(*) filter(where attribution='OBSERVED'),
    count(*) filter(where attribution='ASSISTED'),
    count(*) filter(where attribution='DIRECT_DECLARED'),
    round(avg(attribution_confidence),4)
  into v_users,v_outcomes,v_observed,v_assisted,v_direct,v_avg
  from eligible;

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
    status=excluded.status,
    eligible_user_count=excluded.eligible_user_count,
    outcome_count=excluded.outcome_count,
    observed_count=excluded.observed_count,
    assisted_count=excluded.assisted_count,
    direct_declared_count=excluded.direct_declared_count,
    average_attribution_confidence=excluded.average_attribution_confidence,
    governance_version=excluded.governance_version,
    generated_at=now()
  returning * into v_row;

  return jsonb_build_object(
    'learning_snapshot_id',v_row.learning_snapshot_id,
    'status',v_row.status,
    'eligible_user_count',v_row.eligible_user_count,
    'outcome_count',v_row.outcome_count,
    'cohort_key',v_row.cohort_key
  );
end;
$$;

create or replace function public.gal_publish_learning_snapshot(p_learning_snapshot_id text)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_row public.gal_learning_snapshots%rowtype;
begin
  select * into v_row
  from public.gal_learning_snapshots
  where learning_snapshot_id=p_learning_snapshot_id
  for update;

  if not found then raise exception 'Learning snapshot not found'; end if;
  if v_row.eligible_user_count < v_row.minimum_cohort_size then raise exception 'Privacy threshold not met'; end if;

  update public.gal_learning_snapshots
  set status='PUBLISHED', published_at=coalesce(published_at,now())
  where id=v_row.id
  returning * into v_row;

  return jsonb_build_object(
    'learning_snapshot_id',v_row.learning_snapshot_id,
    'status',v_row.status,
    'eligible_user_count',v_row.eligible_user_count
  );
end;
$$;

revoke execute on function public.gal_build_learning_snapshot(text,timestamptz,timestamptz,text,text,text,text,text,integer,text,text) from public,anon,authenticated;
revoke execute on function public.gal_publish_learning_snapshot(text) from public,anon,authenticated;
grant execute on function public.gal_build_learning_snapshot(text,timestamptz,timestamptz,text,text,text,text,text,integer,text,text) to service_role;
grant execute on function public.gal_publish_learning_snapshot(text) to service_role;
