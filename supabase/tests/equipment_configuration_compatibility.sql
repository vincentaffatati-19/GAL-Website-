do $$ begin
  if to_regclass('public.gal_equipment_configurations') is null then raise exception 'configurations missing'; end if;
  if to_regclass('public.gal_equipment_configuration_components') is null then raise exception 'configuration components missing'; end if;
  if to_regclass('public.gal_equipment_configuration_settings') is null then raise exception 'configuration settings missing'; end if;
  if to_regclass('public.gal_equipment_compatibility_rules') is null then raise exception 'compatibility rules missing'; end if;
  if to_regclass('public.gal_equipment_dependency_rules') is null then raise exception 'dependency rules missing'; end if;
  if to_regclass('public.gal_equipment_configuration_eligible_v') is null then raise exception 'configuration eligibility view missing'; end if;
end $$;

do $$ begin
  if exists (select 1 from public.gal_equipment_configuration_eligible_v where support_state='UNVERIFIED_INVALID') then
    raise exception 'invalid configuration entered eligibility view';
  end if;
end $$;