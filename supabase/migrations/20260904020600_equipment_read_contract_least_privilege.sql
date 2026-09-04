-- Restore advisor-clean SECURITY INVOKER public RPCs while keeping private helpers least-privilege.

revoke all on schema gal_private from public;
revoke create on schema gal_private from anon,authenticated;
grant usage on schema gal_private to anon,authenticated;

revoke all on function gal_private.equipment_guide_reader() from public;
revoke all on function gal_private.equipment_ai_fit_reader() from public;
grant execute on function gal_private.equipment_guide_reader() to anon,authenticated;
grant execute on function gal_private.equipment_ai_fit_reader() to authenticated;
revoke execute on function gal_private.equipment_ai_fit_reader() from anon;

create or replace function public.gal_public_equipment_guide()
returns setof public.gal_equipment_guide_v
language sql
stable
security invoker
set search_path=public,gal_private
as $$ select * from gal_private.equipment_guide_reader(); $$;

create or replace function public.gal_authenticated_equipment_ai_fit()
returns setof public.gal_equipment_ai_fit_v
language sql
stable
security invoker
set search_path=public,gal_private
as $$ select * from gal_private.equipment_ai_fit_reader(); $$;

revoke all on function public.gal_public_equipment_guide() from public;
revoke all on function public.gal_authenticated_equipment_ai_fit() from public;
grant execute on function public.gal_public_equipment_guide() to anon,authenticated;
grant execute on function public.gal_authenticated_equipment_ai_fit() to authenticated;
revoke execute on function public.gal_authenticated_equipment_ai_fit() from anon;

-- Underlying views remain non-browser-readable; only the RPC contracts are exposed.
revoke all on public.gal_equipment_configuration_eligible_v from anon,authenticated;
revoke all on public.gal_equipment_detail_v from anon,authenticated;
revoke all on public.gal_equipment_guide_v from anon,authenticated;
revoke all on public.gal_equipment_ai_fit_v from anon,authenticated;
