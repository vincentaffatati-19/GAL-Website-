-- GI-1.1 Jerry's Bag: immutable whole-bag snapshots for recommendation replay.

create table public.gal_bag_snapshots (
  id uuid primary key default gen_random_uuid(),
  bag_snapshot_id text unique not null default public.gal_public_id('GAL-BS'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_id uuid not null,
  snapshot_type text not null
    check (snapshot_type in ('RECOMMENDATION','MANUAL','SCENARIO_ADOPTION','SYSTEM')),
  bag_version text not null,
  items_snapshot jsonb not null default '[]'::jsonb,
  club_count integer not null default 0 check (club_count >= 0),
  market_code text,
  currency char(3),
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index gal_bag_snapshots_user_time_idx
  on public.gal_bag_snapshots(user_id, captured_at desc);
create index gal_bag_snapshots_bag_time_idx
  on public.gal_bag_snapshots(bag_id, captured_at desc);

alter table public.gal_bag_snapshots enable row level security;

revoke all on table public.gal_bag_snapshots from public, anon, authenticated;
grant select on table public.gal_bag_snapshots to authenticated;
revoke all on table public.gal_bag_snapshots from service_role;
grant select, insert on table public.gal_bag_snapshots to service_role;

create policy gal_bag_snapshots_self_select
on public.gal_bag_snapshots
for select
to authenticated
using (user_id = public.gal_current_user_id());

comment on table public.gal_bag_snapshots is
  'Immutable whole-bag evidence used to reproduce recommendation-time bag state. Current bag truth remains in gal_bags/gal_bag_items.';
