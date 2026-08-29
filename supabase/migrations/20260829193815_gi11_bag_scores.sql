-- GI-1.1 Jerry's Bag Task 4
-- Purpose: immutable, versioned Bag Optimization Score evidence distinct from product Fit Score.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_bag_scores

create table public.gal_bag_score_snapshots (
  id uuid primary key default gen_random_uuid(),
  bag_score_snapshot_id text unique not null default ('GAL-BSS-' || gen_random_uuid()::text),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_id uuid not null references public.gal_bags(id) on delete cascade,
  bag_snapshot_id uuid not null references public.gal_bag_snapshots(id) on delete restrict,
  scenario_id uuid references public.gal_bag_scenarios(id) on delete set null,
  profile_snapshot_id uuid not null references public.gal_profile_snapshots(id) on delete restrict,
  optimization_score numeric(5,2) not null check (optimization_score >= 0 and optimization_score <= 100),
  confidence numeric(4,3) not null check (confidence >= 0 and confidence <= 1),
  components jsonb not null default '[]'::jsonb,
  bag_optimization_version text not null check (btrim(bag_optimization_version) <> ''),
  equipment_data_version text not null check (btrim(equipment_data_version) <> ''),
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index gal_bag_score_snapshots_user_captured_idx
  on public.gal_bag_score_snapshots(user_id, captured_at desc);
create index gal_bag_score_snapshots_bag_captured_idx
  on public.gal_bag_score_snapshots(bag_id, captured_at desc);
create index gal_bag_score_snapshots_bag_snapshot_idx
  on public.gal_bag_score_snapshots(bag_snapshot_id);
create index gal_bag_score_snapshots_scenario_idx
  on public.gal_bag_score_snapshots(scenario_id)
  where scenario_id is not null;

alter table public.gal_bag_score_snapshots enable row level security;

-- Golfer may read only owned immutable score evidence.
revoke all on table public.gal_bag_score_snapshots from public, anon, authenticated;
grant select on table public.gal_bag_score_snapshots to authenticated;

-- Trusted system can create evidence but cannot rewrite or delete history.
revoke all on table public.gal_bag_score_snapshots from service_role;
grant select, insert on table public.gal_bag_score_snapshots to service_role;

create policy gal_bag_score_snapshots_self_select
  on public.gal_bag_score_snapshots
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

create or replace function gal_private.gal_validate_bag_score_snapshot_ownership()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
begin
  if not exists (
    select 1 from public.gal_bags b
    where b.id = new.bag_id and b.user_id = new.user_id
  ) then
    raise exception 'BAG_SCORE_BAG_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if not exists (
    select 1 from public.gal_bag_snapshots bs
    where bs.id = new.bag_snapshot_id
      and bs.bag_id = new.bag_id
      and bs.user_id = new.user_id
  ) then
    raise exception 'BAG_SCORE_BAG_SNAPSHOT_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if not exists (
    select 1 from public.gal_profile_snapshots ps
    where ps.id = new.profile_snapshot_id and ps.user_id = new.user_id
  ) then
    raise exception 'BAG_SCORE_PROFILE_SNAPSHOT_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if new.scenario_id is not null and not exists (
    select 1 from public.gal_bag_scenarios s
    where s.id = new.scenario_id
      and s.bag_id = new.bag_id
      and s.user_id = new.user_id
  ) then
    raise exception 'BAG_SCORE_SCENARIO_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  return new;
end;
$$;
revoke execute on function gal_private.gal_validate_bag_score_snapshot_ownership() from public, anon, authenticated, service_role;

drop trigger if exists gal_bag_score_snapshots_validate_ownership on public.gal_bag_score_snapshots;
create trigger gal_bag_score_snapshots_validate_ownership
before insert on public.gal_bag_score_snapshots
for each row execute function gal_private.gal_validate_bag_score_snapshot_ownership();

comment on table public.gal_bag_score_snapshots is
  'Immutable Bag Optimization Score evidence. Score is 0-100 and separate from product Fit Score; confidence and component evidence remain explicit.';
