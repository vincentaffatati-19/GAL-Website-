-- GAL GI-1.1 Foundation Task 8: immutable profile snapshots.
-- Snapshot rows are system-written evidence used for deterministic recommendation replay.

create table public.gal_profile_snapshots (
  id uuid primary key default gen_random_uuid(),
  profile_snapshot_id text not null unique default public.gal_public_id('GAL-PS'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  snapshot_type text not null,
  profile_version text not null,
  facts_snapshot jsonb not null default '{}'::jsonb,
  inference_snapshot jsonb not null default '{}'::jsonb,
  state_generation_id text,
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint gal_profile_snapshots_snapshot_type_nonempty check (btrim(snapshot_type) <> ''),
  constraint gal_profile_snapshots_profile_version_nonempty check (btrim(profile_version) <> '')
);

create index gal_profile_snapshots_user_captured_idx
  on public.gal_profile_snapshots(user_id, captured_at desc);

alter table public.gal_profile_snapshots enable row level security;

-- Exposed-table least privilege: golfers may only read their own immutable snapshots.
revoke all on table public.gal_profile_snapshots from anon, authenticated;
grant select on table public.gal_profile_snapshots to authenticated;

-- Trusted server/service execution may create snapshot evidence, but not rewrite it.
revoke all on table public.gal_profile_snapshots from service_role;
grant select, insert on table public.gal_profile_snapshots to service_role;

create policy gal_profile_snapshots_self_select
on public.gal_profile_snapshots
for select
to authenticated
using (user_id = public.gal_current_user_id());
