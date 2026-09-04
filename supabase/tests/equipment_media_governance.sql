do $$ begin
  if to_regclass('public.gal_equipment_media_assets') is null then raise exception 'equipment media assets missing'; end if;
  if to_regclass('public.gal_equipment_media_production_v') is null then raise exception 'equipment media production view missing'; end if;
end $$;

do $$ begin
  if exists (select 1 from public.gal_equipment_media_production_v where rights_state in ('PUBLIC_REFERENCE_ONLY','UNVERIFIED_RIGHTS')) then
    raise exception 'non-production media rights leaked into production view';
  end if;
end $$;

do $$ begin
  if exists (
    select 1 from information_schema.view_table_usage
    where view_schema='public' and view_name like 'gal_equipment_readiness%'
      and table_name='gal_equipment_media_assets'
  ) then raise exception 'readiness depends on media assets'; end if;
end $$;