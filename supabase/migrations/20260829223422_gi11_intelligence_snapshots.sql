-- GI-1.1 Longitudinal Intelligence Task 7
-- Immutable milestone intelligence snapshots. Current intelligence state remains
-- a rebuildable cache; this table is written only for explicit milestones.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_intelligence_snapshots

create table public.gal_intelligence_snapshots (
  id uuid primary key default gen_random_uuid(),
  intelligence_snapshot_id text not null unique default public.gal_public_id('GAL-IS'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  state_generation_id uuid not null,
  engine_version text not null,
  state_schema_version text not null,
  state jsonb not null,
  domain_status jsonb not null default '{}'::jsonb,
  trigger_type text not null,
  trigger_id text not null,
  profile_snapshot_id uuid references public.gal_profile_snapshots(id) on delete set null,
  bag_snapshot_id uuid references public.gal_bag_snapshots(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint gal_intelligence_snapshots_engine_version_nonempty
    check (btrim(engine_version) <> ''),
  constraint gal_intelligence_snapshots_state_schema_version_nonempty
    check (btrim(state_schema_version) <> ''),
  constraint gal_intelligence_snapshots_trigger_type_nonempty
    check (btrim(trigger_type) <> ''),
  constraint gal_intelligence_snapshots_trigger_id_nonempty
    check (btrim(trigger_id) <> ''),
  constraint gal_intelligence_snapshots_state_object
    check (jsonb_typeof(state) = 'object'),
  constraint gal_intelligence_snapshots_domain_status_object
    check (jsonb_typeof(domain_status) = 'object')
);

create index gal_intelligence_snapshots_user_created_idx
  on public.gal_intelligence_snapshots(user_id, created_at desc);

create index gal_intelligence_snapshots_generation_idx
  on public.gal_intelligence_snapshots(state_generation_id);

create index gal_intelligence_snapshots_profile_snapshot_idx
  on public.gal_intelligence_snapshots(profile_snapshot_id)
  where profile_snapshot_id is not null;

create index gal_intelligence_snapshots_bag_snapshot_idx
  on public.gal_intelligence_snapshots(bag_snapshot_id)
  where bag_snapshot_id is not null;

alter table public.gal_intelligence_snapshots enable row level security;

-- Golfer-facing surface is immutable/read-only and remains scoped by RLS.
revoke all on table public.gal_intelligence_snapshots from public, anon, authenticated;
grant select on table public.gal_intelligence_snapshots to authenticated;

-- Trusted services may record explicit milestone evidence, but cannot rewrite or
-- delete prior snapshots. Corrections require a new milestone snapshot.
revoke all on table public.gal_intelligence_snapshots from service_role;
grant select, insert on table public.gal_intelligence_snapshots to service_role;

create policy gal_intelligence_snapshots_self_select
on public.gal_intelligence_snapshots
for select
to authenticated
using (user_id = public.gal_current_user_id());

comment on table public.gal_intelligence_snapshots is
  'Immutable milestone copies of generated golfer intelligence. Not written for every state recomputation; current cache remains gal_intelligence_state.';
comment on column public.gal_intelligence_snapshots.state_generation_id is
  'Generation identifier of the rebuildable intelligence-state result captured at this milestone.';
comment on column public.gal_intelligence_snapshots.trigger_type is
  'Governed application milestone class that caused the snapshot to be recorded.';
comment on column public.gal_intelligence_snapshots.trigger_id is
  'Stable identifier of the milestone source, such as a recommendation run, adoption, or explicit system checkpoint.';
