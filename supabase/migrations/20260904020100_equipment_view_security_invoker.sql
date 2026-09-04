-- Remediate Supabase security_definer_view advisor findings.
-- All views execute with invoker security. Browser contracts are read-only SECURITY DEFINER RPCs with fixed search_path.

alter view public.gal_equipment_configuration_eligible_v set (security_invoker=true);
alter view public.gal_equipment_media_production_v set (security_invoker=true);
alter view public.gal_equipment_detail_v set (security_invoker=true);
alter view public.gal_equipment_guide_v set (security_invoker=true);
alter view public.gal_equipment_ai_fit_v set (security_invoker=true);

revoke all on public.gal_equipment_configuration_eligible_v from anon,authenticated;
revoke all on public.gal_equipment_media_production_v from anon,authenticated;
revoke all on public.gal_equipment_detail_v from anon,authenticated;
revoke all on public.gal_equipment_guide_v from anon,authenticated;
revoke all on public.gal_equipment_ai_fit_v from anon,authenticated;

create or replace function public.gal_public_equipment_guide()
returns setof public.gal_equipment_guide_v
language sql
stable
security definer
set search_path=public
as $$
  select * from public.gal_equipment_guide_v;
$$;

create or replace function public.gal_authenticated_equipment_ai_fit()
returns setof public.gal_equipment_ai_fit_v
language sql
stable
security definer
set search_path=public
as $$
  select * from public.gal_equipment_ai_fit_v;
$$;

revoke all on function public.gal_public_equipment_guide() from public;
revoke all on function public.gal_authenticated_equipment_ai_fit() from public;
grant execute on function public.gal_public_equipment_guide() to anon,authenticated;
grant execute on function public.gal_authenticated_equipment_ai_fit() to authenticated;
