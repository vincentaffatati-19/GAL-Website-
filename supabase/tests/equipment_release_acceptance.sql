-- GAL Equipment Knowledge full staging acceptance gate.

-- Structural and rollback-path checks.
do $$ begin
  if to_regclass('public.gal_equipment_guide_v') is null then raise exception 'guide view missing'; end if;
  if to_regclass('public.gal_equipment_ai_fit_v') is null then raise exception 'ai fit view missing'; end if;
  if to_regclass('public.gal_driver_master_registry') is null then raise exception 'legacy rollback registry missing'; end if;
  if to_regclass('public.gal_catalog_products') is null then raise exception 'legacy catalog compatibility missing'; end if;
  if to_regclass('public.gal_equipment_legacy_reconciliation') is null then raise exception 'legacy reconciliation missing'; end if;
end $$;

-- Readiness and configuration safety invariants.
do $$ begin
  if exists (select 1 from public.gal_equipment_readiness_state where readiness_state='AI_FIT_READY' and blocking_gap_count>0) then raise exception 'AI_FIT_READY has blockers'; end if;
  if exists (select 1 from public.gal_equipment_configuration_eligible_v where support_state='UNVERIFIED_INVALID') then raise exception 'invalid configuration is fitting eligible'; end if;
  if exists (select 1 from public.gal_equipment_guide_v g join public.gal_equipment_readiness_state r on r.id=g.readiness_state_id where r.readiness_state not in ('GUIDE_READY','AI_FIT_READY')) then raise exception 'guide readiness gate violated'; end if;
end $$;

-- One-truth consistency across shared consumer views.
do $$ begin
  if exists (
    select 1 from public.gal_equipment_guide_v g
    join public.gal_equipment_ai_fit_v a on a.canonical_product_id=g.canonical_product_id
    where g.category is distinct from a.category
       or g.family_name is distinct from a.family_name
       or g.lifecycle_state is distinct from a.lifecycle_state
       or g.approved_characteristics is distinct from a.approved_characteristics
  ) then raise exception 'Guide and AI Fit disagree on governed equipment truth'; end if;
end $$;

-- Browser privilege boundary.
do $$ declare t text; begin
  foreach t in array array['gal_equipment_observations','gal_equipment_conflicts','gal_equipment_test_observations','gal_equipment_readiness_state','gal_equipment_media_assets'] loop
    if has_table_privilege('authenticated',format('public.%I',t),'INSERT')
       or has_table_privilege('authenticated',format('public.%I',t),'UPDATE')
       or has_table_privilege('authenticated',format('public.%I',t),'DELETE') then
      raise exception 'browser mutation privilege remains on %',t;
    end if;
  end loop;
end $$;

-- Legacy reconciliation invariant.
do $$ declare legacy_count bigint; reconciliation_count bigint; begin
  select count(*) into legacy_count from public.gal_driver_master_registry;
  select count(*) into reconciliation_count from public.gal_equipment_legacy_reconciliation where legacy_table='gal_driver_master_registry';
  if legacy_count <> reconciliation_count then raise exception 'legacy reconciliation count mismatch'; end if;
end $$;
