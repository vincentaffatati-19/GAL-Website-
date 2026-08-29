-- GI-1.1 Recommendation Auditability Task 5
-- Purpose: immutable/versioned recommendation execution records with bounded lifecycle updates.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_recommendation_runs

create table public.gal_recommendation_runs (
  id uuid primary key default gen_random_uuid(),
  recommendation_run_id text unique not null default ('GAL-RUN-' || gen_random_uuid()::text),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  run_type text not null check (btrim(run_type) <> ''),
  category public.gal_category,
  status text not null default 'PLANNED' check (status in ('PLANNED','RUNNING','COMPLETED','FAILED','SUPERSEDED')),
  profile_snapshot_id uuid not null references public.gal_profile_snapshots(id) on delete restrict,
  bag_snapshot_id uuid references public.gal_bag_snapshots(id) on delete restrict,
  scenario_id uuid references public.gal_bag_scenarios(id) on delete set null,
  equipment_data_version text not null check (btrim(equipment_data_version) <> ''),
  fit_model_version text not null check (btrim(fit_model_version) <> ''),
  category_model_version text,
  guide_version text not null check (btrim(guide_version) <> ''),
  bag_optimization_version text,
  question_engine_version text not null check (btrim(question_engine_version) <> ''),
  ai_explanation_version text,
  normalized_inputs jsonb not null default '{}'::jsonb,
  result_summary jsonb not null default '{}'::jsonb,
  market_code text,
  currency char(3),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  superseded_at timestamptz,
  created_at timestamptz not null default now()
);

create index gal_recommendation_runs_user_started_idx
  on public.gal_recommendation_runs(user_id, started_at desc);
create index gal_recommendation_runs_user_category_idx
  on public.gal_recommendation_runs(user_id, category, started_at desc);
create index gal_recommendation_runs_status_idx
  on public.gal_recommendation_runs(status, started_at desc);
create index gal_recommendation_runs_profile_snapshot_idx
  on public.gal_recommendation_runs(profile_snapshot_id);
create index gal_recommendation_runs_bag_snapshot_idx
  on public.gal_recommendation_runs(bag_snapshot_id)
  where bag_snapshot_id is not null;

alter table public.gal_recommendation_runs enable row level security;

revoke all on table public.gal_recommendation_runs from public, anon, authenticated;
grant select on table public.gal_recommendation_runs to authenticated;

-- Service code may create a run and advance lifecycle/result metadata, but may not delete it.
revoke all on table public.gal_recommendation_runs from service_role;
grant select, insert, update on table public.gal_recommendation_runs to service_role;

create policy gal_recommendation_runs_self_select
  on public.gal_recommendation_runs
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

create or replace function gal_private.gal_validate_recommendation_run_ownership()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
begin
  if not exists (
    select 1 from public.gal_profile_snapshots ps
    where ps.id = new.profile_snapshot_id and ps.user_id = new.user_id
  ) then
    raise exception 'RECOMMENDATION_PROFILE_SNAPSHOT_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if new.bag_snapshot_id is not null and not exists (
    select 1 from public.gal_bag_snapshots bs
    where bs.id = new.bag_snapshot_id and bs.user_id = new.user_id
  ) then
    raise exception 'RECOMMENDATION_BAG_SNAPSHOT_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if new.scenario_id is not null and not exists (
    select 1 from public.gal_bag_scenarios s
    where s.id = new.scenario_id and s.user_id = new.user_id
  ) then
    raise exception 'RECOMMENDATION_SCENARIO_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  return new;
end;
$$;
revoke execute on function gal_private.gal_validate_recommendation_run_ownership() from public, anon, authenticated, service_role;

drop trigger if exists gal_recommendation_runs_validate_ownership on public.gal_recommendation_runs;
create trigger gal_recommendation_runs_validate_ownership
before insert on public.gal_recommendation_runs
for each row execute function gal_private.gal_validate_recommendation_run_ownership();

create or replace function gal_private.gal_guard_recommendation_run_update()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
begin
  -- Only lifecycle/result fields may change after creation. The deterministic input,
  -- snapshot, market, and version chain is immutable historical evidence.
  if (to_jsonb(new) - array['status','result_summary','completed_at','superseded_at']::text[])
     is distinct from
     (to_jsonb(old) - array['status','result_summary','completed_at','superseded_at']::text[]) then
    raise exception 'RECOMMENDATION_RUN_IMMUTABLE_FIELDS' using errcode = '42501';
  end if;

  if old.status in ('FAILED','SUPERSEDED') and new.status is distinct from old.status then
    raise exception 'RECOMMENDATION_RUN_TERMINAL' using errcode = '42501';
  end if;
  if old.status = 'COMPLETED' and new.status not in ('COMPLETED','SUPERSEDED') then
    raise exception 'RECOMMENDATION_RUN_INVALID_TRANSITION' using errcode = '42501';
  end if;
  if old.status = 'RUNNING' and new.status not in ('RUNNING','COMPLETED','FAILED','SUPERSEDED') then
    raise exception 'RECOMMENDATION_RUN_INVALID_TRANSITION' using errcode = '42501';
  end if;
  if old.status = 'PLANNED' and new.status not in ('PLANNED','RUNNING','FAILED','SUPERSEDED') then
    raise exception 'RECOMMENDATION_RUN_INVALID_TRANSITION' using errcode = '42501';
  end if;

  return new;
end;
$$;
revoke execute on function gal_private.gal_guard_recommendation_run_update() from public, anon, authenticated, service_role;

drop trigger if exists gal_recommendation_runs_guard_update on public.gal_recommendation_runs;
create trigger gal_recommendation_runs_guard_update
before update on public.gal_recommendation_runs
for each row execute function gal_private.gal_guard_recommendation_run_update();

comment on table public.gal_recommendation_runs is
  'Versioned recommendation execution audit record. Snapshot/input/version fields are immutable; only bounded trusted lifecycle and structured result metadata may change.';
