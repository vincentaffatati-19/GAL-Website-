create type public.gal_insight_status as enum ('CANDIDATE','ACTIVE','ACKNOWLEDGED','RESOLVED','SUPPRESSED','EXPIRED');
create type public.gal_insight_severity as enum ('INFO','MATERIAL','HIGH');

create or replace function public.gal_insight_dedupe_key(
  p_domain text,
  p_insight_code text,
  p_subject_type text,
  p_subject_key text,
  p_scope_key text default 'global'
) returns text
language sql
immutable
security invoker
set search_path = ''
as $$
  select encode(
    extensions.digest(
      convert_to(
        jsonb_build_array(
          lower(btrim(coalesce(p_domain,''))),
          lower(btrim(coalesce(p_insight_code,''))),
          lower(btrim(coalesce(p_subject_type,''))),
          lower(btrim(coalesce(p_subject_key,''))),
          lower(btrim(coalesce(p_scope_key,'global')))
        )::text,
        'UTF8'
      ),
      'sha256'
    ),
    'hex'
  );
$$;

create table public.gal_insights (
  id uuid primary key default gen_random_uuid(),
  insight_id text not null unique default public.gal_public_id('GAL-INS'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  insight_domain text not null check (btrim(insight_domain) <> ''),
  insight_code text not null check (btrim(insight_code) <> ''),
  subject_type text not null check (btrim(subject_type) <> ''),
  subject_key text not null check (btrim(subject_key) <> ''),
  scope_key text not null default 'global' check (btrim(scope_key) <> ''),
  dedupe_key text generated always as (
    public.gal_insight_dedupe_key(insight_domain, insight_code, subject_type, subject_key, scope_key)
  ) stored,
  status public.gal_insight_status not null default 'CANDIDATE',
  severity public.gal_insight_severity not null default 'MATERIAL',
  confidence numeric(5,4) not null default 1.0000 check (confidence >= 0 and confidence <= 1),
  materiality_score numeric(5,4) not null default 0.5000 check (materiality_score >= 0 and materiality_score <= 1),
  headline text,
  golfer_message text,
  evidence_summary jsonb not null default '{}'::jsonb check (jsonb_typeof(evidence_summary) = 'object'),
  governance_version text not null,
  signal_count integer not null default 0 check (signal_count >= 0),
  source_system_count integer not null default 0 check (source_system_count >= 0),
  first_detected_at timestamptz not null default now(),
  last_detected_at timestamptz not null default now(),
  activated_at timestamptz,
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  suppressed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gal_insights_user_dedupe_key unique (user_id, dedupe_key),
  constraint gal_insights_detection_order check (last_detected_at >= first_detected_at),
  constraint gal_insights_active_content check (
    status not in ('ACTIVE','ACKNOWLEDGED') or (headline is not null and btrim(headline) <> '' and golfer_message is not null and btrim(golfer_message) <> '')
  )
);

create index gal_insights_user_status_idx on public.gal_insights(user_id, status, severity, last_detected_at desc);
create index gal_insights_user_domain_idx on public.gal_insights(user_id, insight_domain, insight_code, status);

create table public.gal_insight_signals (
  id uuid primary key default gen_random_uuid(),
  signal_id text not null unique default public.gal_public_id('GAL-ISG'),
  insight_id uuid not null references public.gal_insights(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  source_system text not null check (btrim(source_system) <> ''),
  source_system_version text,
  source_event_key text not null check (btrim(source_event_key) <> ''),
  detected_at timestamptz not null default now(),
  confidence numeric(5,4) not null default 1.0000 check (confidence >= 0 and confidence <= 1),
  materiality_score numeric(5,4) not null default 0.5000 check (materiality_score >= 0 and materiality_score <= 1),
  evidence jsonb not null default '{}'::jsonb check (jsonb_typeof(evidence) = 'object'),
  created_at timestamptz not null default now(),
  constraint gal_insight_signals_source_event_key unique (user_id, source_system, source_event_key, insight_id)
);

create index gal_insight_signals_insight_detected_idx on public.gal_insight_signals(insight_id, detected_at desc);
create index gal_insight_signals_user_source_idx on public.gal_insight_signals(user_id, source_system, detected_at desc);

alter table public.gal_insights enable row level security;
alter table public.gal_insight_signals enable row level security;

revoke all on table public.gal_insights from anon, authenticated;
revoke all on table public.gal_insight_signals from anon, authenticated;
grant select on table public.gal_insights to authenticated;

create policy gal_insights_self_select
on public.gal_insights for select
to authenticated
using (
  user_id = public.gal_current_user_id()
  and status in ('ACTIVE','ACKNOWLEDGED','RESOLVED','EXPIRED')
);

create or replace function public.gal_record_insight_signal(
  p_user_id uuid,
  p_domain text,
  p_insight_code text,
  p_subject_type text,
  p_subject_key text,
  p_scope_key text,
  p_source_system text,
  p_source_event_key text,
  p_source_system_version text default null,
  p_detected_at timestamptz default now(),
  p_confidence numeric default 1.0,
  p_materiality_score numeric default 0.5,
  p_severity public.gal_insight_severity default 'MATERIAL',
  p_governance_version text default '1',
  p_evidence jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_insight public.gal_insights%rowtype;
  v_inserted integer := 0;
  v_source_count integer := 0;
begin
  if p_user_id is null then raise exception 'p_user_id is required'; end if;
  if nullif(btrim(p_domain),'') is null then raise exception 'p_domain is required'; end if;
  if nullif(btrim(p_insight_code),'') is null then raise exception 'p_insight_code is required'; end if;
  if nullif(btrim(p_subject_type),'') is null then raise exception 'p_subject_type is required'; end if;
  if nullif(btrim(p_subject_key),'') is null then raise exception 'p_subject_key is required'; end if;
  if nullif(btrim(coalesce(p_scope_key,'global')),'') is null then raise exception 'p_scope_key is required'; end if;
  if nullif(btrim(p_source_system),'') is null then raise exception 'p_source_system is required'; end if;
  if nullif(btrim(p_source_event_key),'') is null then raise exception 'p_source_event_key is required'; end if;
  if nullif(btrim(p_governance_version),'') is null then raise exception 'p_governance_version is required'; end if;
  if p_confidence < 0 or p_confidence > 1 then raise exception 'p_confidence must be between 0 and 1'; end if;
  if p_materiality_score < 0 or p_materiality_score > 1 then raise exception 'p_materiality_score must be between 0 and 1'; end if;
  if jsonb_typeof(coalesce(p_evidence,'{}'::jsonb)) <> 'object' then raise exception 'p_evidence must be a JSON object'; end if;

  insert into public.gal_insights(
    user_id, insight_domain, insight_code, subject_type, subject_key, scope_key,
    severity, confidence, materiality_score, governance_version,
    first_detected_at, last_detected_at
  ) values (
    p_user_id, lower(btrim(p_domain)), lower(btrim(p_insight_code)), lower(btrim(p_subject_type)), lower(btrim(p_subject_key)), lower(btrim(coalesce(p_scope_key,'global'))),
    p_severity, p_confidence, p_materiality_score, btrim(p_governance_version),
    p_detected_at, p_detected_at
  )
  on conflict (user_id, dedupe_key) do update set
    last_detected_at = greatest(public.gal_insights.last_detected_at, excluded.last_detected_at),
    confidence = greatest(public.gal_insights.confidence, excluded.confidence),
    materiality_score = greatest(public.gal_insights.materiality_score, excluded.materiality_score),
    severity = case
      when public.gal_insights.severity = 'HIGH' then public.gal_insights.severity
      when excluded.severity = 'HIGH' then excluded.severity
      when public.gal_insights.severity = 'MATERIAL' then public.gal_insights.severity
      else excluded.severity
    end,
    updated_at = now()
  returning * into v_insight;

  insert into public.gal_insight_signals(
    insight_id, user_id, source_system, source_system_version, source_event_key,
    detected_at, confidence, materiality_score, evidence
  ) values (
    v_insight.id, p_user_id, lower(btrim(p_source_system)), nullif(btrim(p_source_system_version),''), btrim(p_source_event_key),
    p_detected_at, p_confidence, p_materiality_score, coalesce(p_evidence,'{}'::jsonb)
  )
  on conflict (user_id, source_system, source_event_key, insight_id) do nothing;

  get diagnostics v_inserted = row_count;

  if v_inserted = 1 then
    select count(distinct source_system)::integer
      into v_source_count
      from public.gal_insight_signals
      where insight_id = v_insight.id;

    update public.gal_insights
       set signal_count = signal_count + 1,
           source_system_count = v_source_count,
           evidence_summary = jsonb_set(
             jsonb_set(evidence_summary, '{latest_source_system}', to_jsonb(lower(btrim(p_source_system))), true),
             '{latest_detected_at}', to_jsonb(p_detected_at), true
           ),
           updated_at = now()
     where id = v_insight.id
     returning * into v_insight;
  end if;

  return jsonb_build_object(
    'insight_id', v_insight.insight_id,
    'dedupe_key', v_insight.dedupe_key,
    'status', v_insight.status,
    'signal_was_new', (v_inserted = 1),
    'signal_count', v_insight.signal_count,
    'source_system_count', v_insight.source_system_count
  );
end;
$$;

create or replace function public.gal_govern_insight(
  p_insight_id text,
  p_status public.gal_insight_status,
  p_headline text default null,
  p_golfer_message text default null,
  p_evidence_summary jsonb default null,
  p_expires_at timestamptz default null
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v public.gal_insights%rowtype;
begin
  if p_status in ('ACTIVE','ACKNOWLEDGED') and (nullif(btrim(p_headline),'') is null or nullif(btrim(p_golfer_message),'') is null) then
    raise exception 'ACTIVE/ACKNOWLEDGED insights require headline and golfer_message';
  end if;
  if p_evidence_summary is not null and jsonb_typeof(p_evidence_summary) <> 'object' then
    raise exception 'p_evidence_summary must be a JSON object';
  end if;

  update public.gal_insights
     set status = p_status,
         headline = case when p_headline is not null then p_headline else headline end,
         golfer_message = case when p_golfer_message is not null then p_golfer_message else golfer_message end,
         evidence_summary = case when p_evidence_summary is not null then p_evidence_summary else evidence_summary end,
         expires_at = case when p_expires_at is not null then p_expires_at else expires_at end,
         activated_at = case when p_status = 'ACTIVE' and activated_at is null then now() else activated_at end,
         acknowledged_at = case when p_status = 'ACKNOWLEDGED' and acknowledged_at is null then now() else acknowledged_at end,
         resolved_at = case when p_status = 'RESOLVED' and resolved_at is null then now() else resolved_at end,
         suppressed_at = case when p_status = 'SUPPRESSED' and suppressed_at is null then now() else suppressed_at end,
         updated_at = now()
   where insight_id = p_insight_id
   returning * into v;

  if not found then raise exception 'Insight % not found', p_insight_id; end if;

  return jsonb_build_object(
    'insight_id', v.insight_id,
    'status', v.status,
    'updated_at', v.updated_at
  );
end;
$$;

revoke execute on function public.gal_record_insight_signal(uuid,text,text,text,text,text,text,text,text,timestamptz,numeric,numeric,public.gal_insight_severity,text,jsonb) from public, anon, authenticated;
grant execute on function public.gal_record_insight_signal(uuid,text,text,text,text,text,text,text,text,timestamptz,numeric,numeric,public.gal_insight_severity,text,jsonb) to service_role;
revoke execute on function public.gal_govern_insight(text,public.gal_insight_status,text,text,jsonb,timestamptz) from public, anon, authenticated;
grant execute on function public.gal_govern_insight(text,public.gal_insight_status,text,text,jsonb,timestamptz) to service_role;
