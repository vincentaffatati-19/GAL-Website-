do $$
begin
  if to_regprocedure('public.gal_parse_set_club_count(text)') is not null then
    execute 'alter function public.gal_parse_set_club_count(text) set search_path = public, pg_temp';
  end if;
  if to_regprocedure('public.gal_add_to_my_bag(jsonb)') is not null then
    execute 'revoke execute on function public.gal_add_to_my_bag(jsonb) from authenticated';
    execute 'grant execute on function public.gal_add_to_my_bag(jsonb) to service_role';
  end if;
end $$;

drop policy if exists gal_consent_self_all on public.gal_consent_records;
drop policy if exists gal_consent_self_select on public.gal_consent_records;
drop policy if exists gal_consent_self_insert on public.gal_consent_records;
revoke update, delete on public.gal_consent_records from authenticated;
grant select, insert on public.gal_consent_records to authenticated;
create policy gal_consent_self_select on public.gal_consent_records for select to authenticated using (user_id = public.gal_current_user_id());
create policy gal_consent_self_insert on public.gal_consent_records for insert to authenticated with check (user_id = public.gal_current_user_id());

drop function if exists public.gal_v64320_import(text, text, jsonb);
