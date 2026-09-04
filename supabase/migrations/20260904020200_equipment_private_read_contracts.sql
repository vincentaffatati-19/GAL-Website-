-- Move privileged read implementation out of the exposed public schema.

create schema if not exists gal_private;
revoke all on schema gal_private from public;
grant usage on schema gal_private to anon,authenticated;

drop function if exists public.gal_public_equipment_guide();
drop function if exists public.gal_authenticated_equipment_ai_fit();

create or replace function gal_private.equipment_guide_reader()
returns setof public.gal_equipment_guide_v
language sql
stable
security definer
set search_path=public,gal_private
as $$ select * from public.gal_equipment_guide_v; $$;

create or replace function gal_private.equipment_ai_fit_reader()
returns setof public.gal_equipment_ai_fit_v
language sql
stable
security definer
set search_path=public,gal_private
as $$ select * from public.gal_equipment_ai_fit_v; $$;

revoke all on function gal_private.equipment_guide_reader() from public;
revoke all on function gal_private.equipment_ai_fit_reader() from public;
grant execute on function gal_private.equipment_guide_reader() to anon,authenticated;
grant execute on function gal_private.equipment_ai_fit_reader() to authenticated;

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
