-- PR #26 architectural review regression suite.

-- Current production characteristic only.
do $$ declare f uuid; a uuid; oldc uuid; cnt int; val text; begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST','GAL-TEST-CHAR','DRIVER','Review Characteristic','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_attribute_definitions(attribute_key,category,use_scope,value_type,definition_version)
  values('review_char','DRIVER','GLOBAL','TEXT','1') returning id into a;
  insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,governance_status,effective_from)
  values(f,a,'"OLD"'::jsonb,'KNOWN','1','PRODUCTION',now()-interval '2 years') returning id into oldc;
  insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,governance_status,effective_from,supersedes_characteristic_id)
  values(f,a,'"CURRENT"'::jsonb,'KNOWN','2','PRODUCTION',now()-interval '1 year',oldc);
  select jsonb_array_length(approved_characteristics),approved_characteristics->0->>'value' into cnt,val from public.gal_equipment_detail_v where family_id=f;
  if cnt<>1 or val<>'CURRENT' then raise exception 'current characteristic selection failed'; end if;
end $$;

-- AI Fit requires configuration-level readiness.
do $$ declare f uuid; ready uuid; unproven uuid; cnt int; begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST','GAL-TEST-READY','DRIVER','Review Readiness','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'READY','Ready','FACTORY_STANDARD') returning id into ready;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'UNPROVEN','Unproven','FACTORY_STANDARD') returning id into unproven;
  insert into public.gal_equipment_readiness_state(family_id,use_case,readiness_state,policy_version,blocking_gap_count) values(f,'AI_FIT','AI_FIT_READY','1',0);
  insert into public.gal_equipment_readiness_state(configuration_id,use_case,readiness_state,policy_version,blocking_gap_count) values(ready,'AI_FIT','AI_FIT_READY','1',0);
  select count(*) into cnt from public.gal_equipment_ai_fit_v where family_id=f;
  if cnt<>1 or not exists(select 1 from public.gal_equipment_ai_fit_v where family_id=f and configuration_id=ready) or exists(select 1 from public.gal_equipment_ai_fit_v where family_id=f and configuration_id=unproven) then
    raise exception 'configuration readiness gate failed';
  end if;
end $$;

-- Component-scoped compatibility applies only when relevant components are present.
do $$ declare f uuid; h uuid; s uuid; a uuid; ch uuid; cp uuid; r uuid; begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version)
  values('GAL-TEST','GAL-TEST-COMPAT','DRIVER','Review Compatibility','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_components(component_type,manufacturer_key,display_name) values('HEAD','H','Head') returning id into h;
  insert into public.gal_equipment_components(component_type,manufacturer_key,display_name) values('SHAFT','S','Shaft') returning id into s;
  insert into public.gal_equipment_components(component_type,manufacturer_key,display_name) values('ADAPTER','A','Adapter') returning id into a;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'HEAD','Head','FACTORY_STANDARD') returning id into ch;
  insert into public.gal_equipment_configuration_components(configuration_id,component_id,component_role) values(ch,h,'HEAD');
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'PAIR','Pair','FACTORY_CUSTOM') returning id into cp;
  insert into public.gal_equipment_configuration_components(configuration_id,component_id,component_role) values(cp,h,'HEAD'),(cp,s,'SHAFT'),(cp,a,'ADAPTER');
  insert into public.gal_equipment_compatibility_rules(category,subject_component_type,target_component_type,predicate_key,operator,predicate_value,hard_rule,rule_version,evidence_reference)
  values('DRIVER','SHAFT','ADAPTER','match','EQ','true'::jsonb,true,'1','SYNTHETIC:RULE') returning id into r;
  if not exists(select 1 from public.gal_equipment_configuration_eligible_v where id=ch) or exists(select 1 from public.gal_equipment_configuration_eligible_v where id=cp) then raise exception 'compatibility applicability failed'; end if;
  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version,evidence_reference) values(cp,r,'PASS','1','SYNTHETIC:EVAL');
  if not exists(select 1 from public.gal_equipment_configuration_eligible_v where id=cp) then raise exception 'compatibility PASS failed'; end if;
end $$;

-- Characteristic evidence IDs are validated and production rows are immutable.
do $$ declare f uuid; a uuid; ch uuid; fake uuid:=gen_random_uuid(); rejected boolean:=false; immutable boolean:=false; begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version) values('GAL-TEST','GAL-TEST-PROV','DRIVER','Review Provenance','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_attribute_definitions(attribute_key,category,use_scope,value_type,definition_version) values('review_prov','DRIVER','GLOBAL','TEXT','1') returning id into a;
  begin insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,evidence_observation_ids,governance_status) values(f,a,'"BAD"'::jsonb,'DERIVED','1',array[fake],'PRODUCTION'); exception when foreign_key_violation or check_violation or raise_exception then rejected:=true; end;
  if not rejected then raise exception 'invalid characteristic evidence accepted'; end if;
  insert into public.gal_equipment_characteristics(family_id,attribute_definition_id,value_json,claim_state,methodology_version,governance_status) values(f,a,'"GOOD"'::jsonb,'KNOWN','1','PRODUCTION') returning id into ch;
  begin update public.gal_equipment_characteristics set value_json='"MUTATED"'::jsonb where id=ch; exception when raise_exception then immutable:=true; end;
  if not immutable then raise exception 'production characteristic mutable'; end if;
end $$;

-- Compatibility evaluations are append-only and superseded by a new row.
do $$ declare f uuid; c uuid; r uuid; e uuid; immutable boolean:=false; begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version) values('GAL-TEST','GAL-TEST-EVAL','DRIVER','Review Eval','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_configurations(family_id,configuration_key,display_name,support_state) values(f,'CFG','Config','FACTORY_STANDARD') returning id into c;
  insert into public.gal_equipment_compatibility_rules(category,predicate_key,operator,predicate_value,hard_rule,rule_version,evidence_reference) values('DRIVER','category','EQ','true'::jsonb,true,'1','SYNTHETIC:RULE') returning id into r;
  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version,evidence_reference) values(c,r,'PASS','1','SYNTHETIC:E1') returning id into e;
  begin update public.gal_equipment_configuration_rule_evaluations set result_state='FAIL' where id=e; exception when raise_exception then immutable:=true; end;
  if not immutable then raise exception 'compatibility evaluation mutable'; end if;
  insert into public.gal_equipment_configuration_rule_evaluations(configuration_id,compatibility_rule_id,result_state,evaluator_version,evidence_reference,supersedes_evaluation_id) values(c,r,'FAIL','2','SYNTHETIC:E2',e);
  if exists(select 1 from public.gal_equipment_configuration_eligible_v where id=c) then raise exception 'superseding FAIL did not block configuration'; end if;
end $$;

-- Derivation evidence IDs are validated and approved derivations are immutable.
do $$ declare f uuid; a uuid; d uuid; fake uuid:=gen_random_uuid(); rejected boolean:=false; immutable boolean:=false; begin
  insert into public.gal_equipment_families(canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version) values('GAL-TEST','GAL-TEST-DERIV','DRIVER','Review Derivation','CURRENT','SYNTHETIC','1') returning id into f;
  insert into public.gal_equipment_attribute_definitions(attribute_key,category,use_scope,value_type,definition_version) values('review_deriv','DRIVER','GLOBAL','NUMBER','1') returning id into a;
  begin insert into public.gal_equipment_derivations(family_id,attribute_definition_id,contributing_observation_ids,methodology_version,derived_value,generalization_scope,approved_generalization_methodology,derivation_status) values(f,a,array[fake],'1','1'::jsonb,'FAMILY',true,'APPROVED'); exception when foreign_key_violation or check_violation or raise_exception then rejected:=true; end;
  if not rejected then raise exception 'invalid derivation evidence accepted'; end if;
  insert into public.gal_equipment_derivations(family_id,attribute_definition_id,contributing_observation_ids,methodology_version,derived_value,generalization_scope,approved_generalization_methodology,derivation_status) values(f,a,'{}'::uuid[],'1','1'::jsonb,'FAMILY',true,'DRAFT') returning id into d;
  update public.gal_equipment_derivations set derivation_status='APPROVED' where id=d;
  begin update public.gal_equipment_derivations set derived_value='2'::jsonb where id=d; exception when raise_exception then immutable:=true; end;
  if not immutable then raise exception 'approved derivation mutable'; end if;
end $$;

-- Read contracts use least privilege: no private CREATE, no anon AI Fit helper, no direct view reads, public wrappers remain SECURITY INVOKER.
do $$ begin
  if has_schema_privilege('anon','gal_private','CREATE') or has_schema_privilege('authenticated','gal_private','CREATE') then raise exception 'browser has private schema CREATE'; end if;
  if not has_schema_privilege('anon','gal_private','USAGE') or not has_schema_privilege('authenticated','gal_private','USAGE') then raise exception 'required private schema USAGE missing'; end if;
  if not has_function_privilege('anon','gal_private.equipment_guide_reader()','EXECUTE') or not has_function_privilege('authenticated','gal_private.equipment_guide_reader()','EXECUTE') then raise exception 'guide helper execute missing'; end if;
  if has_function_privilege('anon','gal_private.equipment_ai_fit_reader()','EXECUTE') or not has_function_privilege('authenticated','gal_private.equipment_ai_fit_reader()','EXECUTE') then raise exception 'AI Fit helper privilege boundary wrong'; end if;
  if has_table_privilege('anon','public.gal_equipment_guide_v','SELECT') or has_table_privilege('authenticated','public.gal_equipment_ai_fit_v','SELECT') then raise exception 'browser can directly read internal views'; end if;
  if (select prosecdef from pg_proc where oid='public.gal_public_equipment_guide()'::regprocedure) or (select prosecdef from pg_proc where oid='public.gal_authenticated_equipment_ai_fit()'::regprocedure) then raise exception 'public wrapper unexpectedly SECURITY DEFINER'; end if;
end $$;
