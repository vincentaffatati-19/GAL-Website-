-- GI-1.1
-- Purpose: harden existing GAL backend security prerequisites before GI-1.1 schema work.
-- Spec: docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md

-- GI-SEC-001: immutable parsing helper must use a fixed search path.
alter function public.gal_parse_set_club_count(text)
  set search_path = public, pg_temp;

-- GI-SEC-002: the SECURITY DEFINER bag mutation RPC is a trusted/server path.
-- Browser-authenticated callers must not invoke it directly.
revoke execute on function public.gal_add_to_my_bag(jsonb) from authenticated;
grant execute on function public.gal_add_to_my_bag(jsonb) to service_role;

-- GI-RLS-006: consent history is append-only for authenticated golfers.
-- Replace broad self-ALL access with explicit read + append policies.
drop policy if exists gal_consent_self_all on public.gal_consent_records;

revoke update, delete on public.gal_consent_records from authenticated;
grant select, insert on public.gal_consent_records to authenticated;

create policy gal_consent_self_select
on public.gal_consent_records
for select
to authenticated
using (user_id = public.gal_current_user_id());

create policy gal_consent_self_insert
on public.gal_consent_records
for insert
to authenticated
with check (user_id = public.gal_current_user_id());
