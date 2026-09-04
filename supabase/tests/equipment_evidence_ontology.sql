do $$ begin
  if to_regclass('public.gal_equipment_attribute_definitions') is null then raise exception 'attribute definitions missing'; end if;
  if to_regclass('public.gal_equipment_sources') is null then raise exception 'equipment sources missing'; end if;
  if to_regclass('public.gal_equipment_observations') is null then raise exception 'equipment observations missing'; end if;
  if to_regclass('public.gal_equipment_conflicts') is null then raise exception 'equipment conflicts missing'; end if;
  if to_regclass('public.gal_equipment_characteristics') is null then raise exception 'equipment characteristics missing'; end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_constraint where conrelid='public.gal_equipment_observations'::regclass and pg_get_constraintdef(oid) like '%PUBLISHED_SPECIFICATION%GAL_MEASURED%INDEPENDENT_OBSERVED%GAL_DERIVED%') then
    raise exception 'evidence class constraint missing';
  end if;
end $$;