do $$ begin
  if to_regclass('public.gal_equipment_configuration_rule_evaluations') is null then
    raise exception 'configuration rule evaluations missing';
  end if;
end $$;

do $$
declare
  f uuid;
  c uuid;
  r uuid;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-BRAND-COMPAT','GAL-TEST-COMPAT-001','DRIVER','Synthetic Compatibility Driver','CURRENT','SYNTHETIC','1')
  returning id into f;

  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state)
  values(f,'CFG','Synthetic Config','FACTORY_STANDARD') returning id into c;

  if not exists (select 1 from public.gal_equipment_configuration_eligible_v where id=c) then
    raise exception 'configuration with no applicable hard rules should be eligible';
  end if;

  insert into public.gal_equipment_compatibility_rules(category,predicate_key,operator,predicate_value,hard_rule,rule_version)
  values('DRIVER','synthetic_rule','EQ','true'::jsonb,true,'1') returning id into r;

  if exists (select 1 from public.gal_equipment_configuration_eligible_v where id=c) then
    raise exception 'unknown hard-rule compatibility must block eligibility';
  end if;

  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version)
  values(c,r,'PASS','1');

  if not exists (select 1 from public.gal_equipment_configuration_eligible_v where id=c) then
    raise exception 'passed hard rule should permit eligibility';
  end if;

  update public.gal_equipment_configuration_rule_evaluations set result_state='FAIL', evaluated_at=now() where configuration_id=c and compatibility_rule_id=r;

  if exists (select 1 from public.gal_equipment_configuration_eligible_v where id=c) then
    raise exception 'failed hard rule must block eligibility';
  end if;

  delete from public.gal_equipment_configuration_rule_evaluations where configuration_id=c;
  delete from public.gal_equipment_compatibility_rules where id=r;
  delete from public.gal_equipment_configurations where id=c;
  delete from public.gal_equipment_families where id=f;
end $$;