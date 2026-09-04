-- GAL Equipment Knowledge security/performance hardening

-- Explicitly revoke browser mutation privileges on global/internal equipment knowledge tables.
do $$ declare t text; begin
  foreach t in array array[
    'gal_equipment_families','gal_equipment_variants','gal_equipment_components','gal_equipment_aliases','gal_equipment_lifecycle_events',
    'gal_equipment_attribute_definitions','gal_equipment_sources','gal_equipment_observations','gal_equipment_conflicts','gal_equipment_characteristics',
    'gal_equipment_configurations','gal_equipment_configuration_components','gal_equipment_configuration_settings','gal_equipment_compatibility_rules','gal_equipment_dependency_rules',
    'gal_equipment_samples','gal_equipment_tested_configurations','gal_equipment_test_sessions','gal_equipment_test_observations','gal_equipment_test_exclusions','gal_equipment_derivations',
    'gal_equipment_readiness_policies','gal_equipment_readiness_requirements','gal_equipment_readiness_state','gal_equipment_evidence_gaps','gal_equipment_readiness_evaluations',
    'gal_equipment_media_assets','gal_equipment_legacy_reconciliation'
  ] loop
    execute format('revoke all on table public.%I from anon, authenticated',t);
  end loop;
end $$;

-- Approved read contracts only.
revoke all on public.gal_equipment_guide_v from public;
revoke all on public.gal_equipment_ai_fit_v from public;
revoke all on public.gal_equipment_detail_v from public;
grant select on public.gal_equipment_guide_v to anon,authenticated;
grant select on public.gal_equipment_ai_fit_v to authenticated;
grant select on public.gal_equipment_detail_v to authenticated;

-- High-value FK/lookup indexes.
create index if not exists gal_equipment_obs_attr_idx on public.gal_equipment_observations(attribute_definition_id);
create index if not exists gal_equipment_obs_variant_idx on public.gal_equipment_observations(variant_id) where variant_id is not null;
create index if not exists gal_equipment_obs_component_idx on public.gal_equipment_observations(component_id) where component_id is not null;
create index if not exists gal_equipment_char_attr_idx on public.gal_equipment_characteristics(attribute_definition_id);
create index if not exists gal_equipment_config_component_config_idx on public.gal_equipment_configuration_components(configuration_id);
create index if not exists gal_equipment_config_setting_config_idx on public.gal_equipment_configuration_settings(configuration_id);
create index if not exists gal_equipment_test_obs_attr_idx on public.gal_equipment_test_observations(attribute_definition_id);
create index if not exists gal_equipment_test_exclusions_obs_idx on public.gal_equipment_test_exclusions(test_observation_id);
create index if not exists gal_equipment_readiness_config_idx on public.gal_equipment_readiness_state(configuration_id,use_case,readiness_state) where configuration_id is not null;
create index if not exists gal_equipment_readiness_family_idx on public.gal_equipment_readiness_state(family_id,use_case,readiness_state) where family_id is not null;
create index if not exists gal_equipment_gap_attr_idx on public.gal_equipment_evidence_gaps(attribute_definition_id,status) where attribute_definition_id is not null;
create index if not exists gal_equipment_readiness_eval_state_idx on public.gal_equipment_readiness_evaluations(readiness_state_id,evaluated_at desc);
create index if not exists gal_equipment_media_family_idx on public.gal_equipment_media_assets(family_id,approval_state) where family_id is not null;
