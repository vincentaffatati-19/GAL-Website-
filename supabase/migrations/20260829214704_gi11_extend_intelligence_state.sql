-- GI-1.1 Longitudinal Intelligence Task 4
-- Version the rebuildable intelligence-state cache without relabeling legacy rows.

alter table public.gal_intelligence_state
  add column state_schema_version text,
  add column state_generation_id uuid,
  add column status text,
  add column latest_source_event_at timestamptz,
  add column domain_status jsonb;

alter table public.gal_intelligence_state
  add constraint gal_intelligence_state_status_check
  check (
    status is null or status in ('HEALTHY','STALE','PARTIAL','REBUILDING','ERROR')
  );

-- Derived intelligence state is client read-only. RLS still limits SELECT to self.
revoke insert, update, delete on table public.gal_intelligence_state from authenticated;
grant select on table public.gal_intelligence_state to authenticated;

-- Trusted backend processes may rebuild/upsert/delete cache rows as operational state.
grant select, insert, update, delete on table public.gal_intelligence_state to service_role;

comment on column public.gal_intelligence_state.state_schema_version is
  'Schema contract used by the engine that generated this cache row. NULL means legacy/unrebuilt state.';
comment on column public.gal_intelligence_state.state_generation_id is
  'Unique identifier for a successful or in-progress state generation. NULL means legacy/unrebuilt state.';
comment on column public.gal_intelligence_state.status is
  'Derived cache health: HEALTHY, STALE, PARTIAL, REBUILDING, or ERROR.';
comment on column public.gal_intelligence_state.latest_source_event_at is
  'Latest non-invalidated behavioral source event incorporated by the current state generation.';
comment on column public.gal_intelligence_state.domain_status is
  'Per-domain freshness/completeness metadata for the derived intelligence cache.';
