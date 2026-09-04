do $$ begin
  if to_regclass('public.gal_equipment_legacy_reconciliation') is null then raise exception 'legacy reconciliation table missing'; end if;
end $$;

do $$ declare legacy_count bigint; recon_count bigint; begin
  select count(*) into legacy_count from public.gal_driver_master_registry;
  select count(*) into recon_count from public.gal_equipment_legacy_reconciliation where legacy_table='gal_driver_master_registry';
  if legacy_count <> recon_count then raise exception 'legacy driver reconciliation mismatch: legacy %, reconciliation %',legacy_count,recon_count; end if;
end $$;

do $$ begin
  if exists (select canonical_product_id from public.gal_equipment_families where canonical_product_id is not null group by canonical_product_id having count(*)>1) then
    raise exception 'duplicate canonical product family mapping';
  end if;
  if to_regclass('public.gal_driver_master_registry') is null then raise exception 'legacy driver registry removed prematurely'; end if;
end $$;