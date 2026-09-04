do $$
declare t text;
begin
  foreach t in array array[
    'gal_equipment_families','gal_equipment_variants','gal_equipment_components','gal_equipment_aliases','gal_equipment_lifecycle_events',
    'gal_equipment_attribute_definitions','gal_equipment_sources','gal_equipment_observations','gal_equipment_conflicts','gal_equipment_characteristics',
    'gal_equipment_configurations','gal_equipment_configuration_components','gal_equipment_configuration_settings','gal_equipment_compatibility_rules','gal_equipment_dependency_rules','gal_equipment_configuration_rule_evaluations',
    'gal_equipment_samples','gal_equipment_tested_configurations','gal_equipment_test_sessions','gal_equipment_test_observations','gal_equipment_test_exclusions','gal_equipment_derivations',
    'gal_equipment_readiness_policies','gal_equipment_readiness_requirements','gal_equipment_readiness_state','gal_equipment_evidence_gaps','gal_equipment_readiness_evaluations',
    'gal_equipment_media_assets','gal_equipment_legacy_reconciliation'
  ] loop
    if has_table_privilege('authenticated',format('public.%I',t),'INSERT')
       or has_table_privilege('authenticated',format('public.%I',t),'UPDATE')
       or has_table_privilege('authenticated',format('public.%I',t),'DELETE') then
      raise exception 'authenticated browser can mutate internal table %',t;
    end if;
  end loop;
end $$;

do $$ begin
  if has_table_privilege('anon','public.gal_equipment_guide_v','SELECT') then raise exception 'anon must not directly select internal guide view'; end if;
  if has_table_privilege('authenticated','public.gal_equipment_ai_fit_v','SELECT') then raise exception 'authenticated browser must not directly select internal AI Fit view'; end if;
  if not has_function_privilege('anon','public.gal_public_equipment_guide()','EXECUTE') then raise exception 'anon public guide RPC execute missing'; end if;
  if has_function_privilege('anon','public.gal_authenticated_equipment_ai_fit()','EXECUTE') then raise exception 'anon must not execute AI Fit RPC'; end if;
  if not has_function_privilege('authenticated','public.gal_authenticated_equipment_ai_fit()','EXECUTE') then raise exception 'authenticated AI Fit RPC execute missing'; end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='gal_equipment_obs_attr_idx') then raise exception 'observation attribute index missing'; end if;
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='gal_equipment_readiness_config_idx') then raise exception 'readiness configuration index missing'; end if;
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='gal_equipment_rule_eval_rule_idx') then raise exception 'compatibility evaluation rule index missing'; end if;
end $$;