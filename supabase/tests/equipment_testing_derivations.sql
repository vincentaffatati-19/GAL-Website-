do $$ begin
  if to_regclass('public.gal_equipment_samples') is null then raise exception 'samples missing'; end if;
  if to_regclass('public.gal_equipment_tested_configurations') is null then raise exception 'tested configurations missing'; end if;
  if to_regclass('public.gal_equipment_test_sessions') is null then raise exception 'test sessions missing'; end if;
  if to_regclass('public.gal_equipment_test_observations') is null then raise exception 'test observations missing'; end if;
  if to_regclass('public.gal_equipment_test_exclusions') is null then raise exception 'test exclusions missing'; end if;
  if to_regclass('public.gal_equipment_derivations') is null then raise exception 'derivations missing'; end if;
end $$;

do $$ begin
  if exists (
    select 1 from public.gal_equipment_derivations
    where generalization_scope='FAMILY' and approved_generalization_methodology=false
  ) then raise exception 'family derivation lacks approved generalization methodology'; end if;
end $$;