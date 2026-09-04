-- Regression tests for PR #26 architectural review findings.
-- These tests intentionally describe the required post-remediation behavior.

-- 1. Consumer truth must expose only the current unsuperseded production characteristic.
do $$
declare f uuid; a uuid; oldc uuid; cnt int; current_value text;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-REVIEW','GAL-TEST-REVIEW-CHAR','DRIVER','Review Characteristic Driver','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_attribute_definitions(attribute_key,category,use_scope,value_type,definition_version)
  values('review_launch_tendency','DRIVER','GLOBAL','TEXT','1') returning id into a;
  insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,governance_status,effective_from)
  values(f,a,'"OLD"'::jsonb,'KNOWN','1','PRODUCTION',now()-interval '2 years') returning id into oldc;
  insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,governance_status,effective_from,supersedes_characteristic_id)
  values(f,a,'"CURRENT"'::jsonb,'KNOWN','2','PRODUCTION',now()-interval '1 year',oldc);
  select jsonb_array_length(approved_characteristics), approved_characteristics->0->>'value'
    into cnt,current_value
  from public.gal_equipment_detail_v where family_id=f;
  if cnt <> 1 or current_value <> 'CURRENT' then
    raise exception 'consumer detail must expose exactly one current unsuperseded characteristic; count %, value %',cnt,current_value;
  end if;
end $$;

-- 2. AI Fit may expose only configurations that have their own applicable AI_FIT readiness state.
do $$
declare f uuid; c_ready uuid; c_unproven uuid; cnt int; exposed uuid;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-REVIEW','GAL-TEST-REVIEW-READY','DRIVER','Review Readiness Driver','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state)
  values(f,'READY','Ready Config','FACTORY_STANDARD') returning id into c_ready;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state)
  values(f,'UNPROVEN','Unproven Config','FACTORY_STANDARD') returning id into c_unproven;
  insert into public.gal_equipment_readiness_state(family_id,use_case,readiness_state,policy_version,blocking_gap_count)
  values(f,'AI_FIT','AI_FIT_READY','1',0);
  insert into public.gal_equipment_readiness_state(configuration_id,use_case,readiness_state,policy_version,blocking_gap_count)
  values(c_ready,'AI_FIT','AI_FIT_READY','1',0);
  select count(*),min(configuration_id) into cnt,exposed from public.gal_equipment_ai_fit_v where family_id=f;
  if cnt <> 1 or exposed <> c_ready then
    raise exception 'AI Fit must expose only configuration-level ready candidates; count %, exposed %',cnt,exposed;
  end if;
end $$;

-- 3. Compatibility rules apply only to configurations matching the rule scope/components/settings.
do $$
declare f uuid; head uuid; shaft uuid; adapter uuid; c_head uuid; c_pair uuid; r uuid; eligible_head boolean; eligible_pair boolean;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-REVIEW','GAL-TEST-REVIEW-COMPAT','DRIVER','Review Compatibility Driver','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_components(component_type,manufacturer_key,display_name) values('HEAD','HEAD-1','Head') returning id into head;
  insert into public.gal_equipment_components(component_type,manufacturer_key,display_name) values('SHAFT','SHAFT-1','Shaft') returning id into shaft;
  insert into public.gal_equipment_components(component_type,manufacturer_key,display_name) values('ADAPTER','ADAPTER-1','Adapter') returning id into adapter;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'HEAD-ONLY','Head Only','FACTORY_STANDARD') returning id into c_head;
  insert into public.gal_equipment_configuration_components(configuration_id,component_id,component_role) values(c_head,head,'HEAD');
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'PAIR','Shaft Adapter Pair','FACTORY_CUSTOM') returning id into c_pair;
  insert into public.gal_equipment_configuration_components(configuration_id,component_id,component_role) values(c_pair,head,'HEAD');
  insert into public.gal_equipment_configuration_components(configuration_id,component_id,component_role) values(c_pair,shaft,'SHAFT');
  insert into public.gal_equipment_configuration_components(configuration_id,component_id,component_role) values(c_pair,adapter,'ADAPTER');
  insert into public.gal_equipment_compatibility_rules(category,subject_component_type,target_component_type,predicate_key,operator,predicate_value,hard_rule,rule_version,evidence_reference)
  values('DRIVER','SHAFT','ADAPTER','shaft_adapter_match','EQ','true'::jsonb,true,'1','SYNTHETIC:RULE') returning id into r;
  select exists(select 1 from public.gal_equipment_configuration_eligible_v where id=c_head),
         exists(select 1 from public.gal_equipment_configuration_eligible_v where id=c_pair)
    into eligible_head,eligible_pair;
  if not eligible_head or eligible_pair then
    raise exception 'component-scoped compatibility applicability wrong; head %, pair %',eligible_head,eligible_pair;
  end if;
  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version,evidence_reference)
  values(c_pair,r,'PASS','1','SYNTHETIC:EVAL');
  if not exists(select 1 from public.gal_equipment_configuration_eligible_v where id=c_pair) then
    raise exception 'matching component-scoped configuration should become eligible after PASS';
  end if;
end $$;

-- 4a. Characteristics must reject nonexistent evidence IDs and production records must be append-only.
do $$
declare f uuid; a uuid; ch uuid; fake uuid := gen_random_uuid(); rejected boolean := false; immutable boolean := false;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-REVIEW','GAL-TEST-REVIEW-PROV','DRIVER','Review Provenance Driver','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_attribute_definitions(attribute_key,category,use_scope,value_type,definition_version)
  values('review_provenance','DRIVER','GLOBAL','TEXT','1') returning id into a;
  begin
    insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,evidence_observation_ids,governance_status)
    values(f,a,'"BAD"'::jsonb,'DERIVED','1',array[fake],'PRODUCTION');
  exception when foreign_key_violation or check_violation or raise_exception then rejected := true;
  end;
  if not rejected then raise exception 'production characteristic accepted nonexistent evidence observation'; end if;
  insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,governance_status)
  values(f,a,'"GOOD"'::jsonb,'KNOWN','1','PRODUCTION') returning id into ch;
  begin
    update public.gal_equipment_characteristics set value_json='"MUTATED"'::jsonb where id=ch;
  exception when raise_exception then immutable := true;
  end;
  if not immutable then raise exception 'production characteristic was mutable in place'; end if;
end $$;

-- 4b. Compatibility evaluations are append-only/versioned; a new evaluation supersedes rather than mutates the old result.
do $$
declare f uuid; c uuid; r uuid; e1 uuid; e2 uuid; immutable boolean := false; current_result text;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-REVIEW','GAL-TEST-REVIEW-EVAL','DRIVER','Review Evaluation Driver','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'CFG','Config','FACTORY_STANDARD') returning id into c;
  insert into public.gal_equipment_compatibility_rules(category,predicate_key,operator,predicate_value,hard_rule,rule_version,evidence_reference)
  values('DRIVER','category_rule','EQ','true'::jsonb,true,'1','SYNTHETIC:RULE') returning id into r;
  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version,evidence_reference)
  values(c,r,'PASS','1','SYNTHETIC:E1') returning id into e1;
  begin
    update public.gal_equipment_configuration_rule_evaluations set result_state='FAIL' where id=e1;
  exception when raise_exception then immutable := true;
  end;
  if not immutable then raise exception 'compatibility evaluation was mutable in place'; end if;
  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version,evidence_reference,supersedes_evaluation_id)
  values(c,r,'FAIL','2','SYNTHETIC:E2',e1) returning id into e2;
  select result_state into current_result
  from public.gal_equipment_configuration_rule_evaluations e
  where e.configuration_id=c and e.compatibility_rule_id=r
    and not exists(select 1 from public.gal_equipment_configuration_rule_evaluations n where n.supersedes_evaluation_id=e.id)
  order by evaluated_at desc limit 1;
  if current_result <> 'FAIL' then raise exception 'latest unsuperseded compatibility evaluation not selected'; end if;
  if exists(select 1 from public.gal_equipment_configuration_eligible_v where id=c) then
    raise exception 'configuration remained eligible after superseding FAIL evaluation';
  end if;
end $$;

-- 4c. Derivations must reference real test observations and approved derivations are append-only/versioned.
do $$
declare f uuid; a uuid; d uuid; fake uuid := gen_random_uuid(); rejected boolean := false; immutable boolean := false;
begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST-REVIEW','GAL-TEST-REVIEW-DERIV','DRIVER','Review Derivation Driver','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_attribute_definitions(attribute_key,category,use_scope,value_type,definition_version)
  values('review_derivation','DRIVER','GLOBAL','NUMBER','1') returning id into a;
  begin
    insert into public.gal_equipment_derivations(family_id,attribute_definition_id,contributing_observation_ids,methodology_version,derived_value,generalization_scope,approved_generalization_methodology,derivation_status)
    values(f,a,array[fake],'1','1'::jsonb,'FAMILY',true,'APPROVED');
  exception when foreign_key_violation or check_violation or raise_exception then rejected := true;
  end;
  if not rejected then raise exception 'approved derivation accepted nonexistent test observation'; end if;
  -- Use DRAFT with an empty evidence set only to verify the transition/immutability guard itself.
  insert into public.gal_equipment_derivations(family_id,attribute_definition_id,contributing_observation_ids,methodology_version,derived_value,generalization_scope,approved_generalization_methodology,derivation_status)
  values(f,a,'{}'::uuid[],'1','1'::jsonb,'FAMILY',true,'DRAFT') returning id into d;
  update public.gal_equipment_derivations set derivation_status='APPROVED' where id=d;
  begin
    update public.gal_equipment_derivations set derived_value='2'::jsonb where id=d;
  exception when raise_exception then immutable := true;
  end;
  if not immutable then raise exception 'approved derivation was mutable in place'; end if;
end $$;

-- 5. Browser roles must not have direct access to privileged gal_private helpers/schema.
do $$ begin
  if has_schema_privilege('anon','gal_private','USAGE') or has_schema_privilege('authenticated','gal_private','USAGE') then
    raise exception 'browser role retains gal_private schema USAGE';
  end if;
  if has_function_privilege('anon','gal_private.equipment_guide_reader()','EXECUTE')
     or has_function_privilege('authenticated','gal_private.equipment_guide_reader()','EXECUTE')
     or has_function_privilege('authenticated','gal_private.equipment_ai_fit_reader()','EXECUTE') then
    raise exception 'browser role retains direct private reader EXECUTE';
  end if;
end $$;
