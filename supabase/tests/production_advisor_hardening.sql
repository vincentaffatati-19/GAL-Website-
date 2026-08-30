begin;

do $$
declare
  t text;
  tables text[] := array[
    'gal_driver_brand_intelligence','gal_driver_commerce_routes','gal_driver_commerce_routes_registry','gal_driver_markets','gal_driver_master_registry','gal_driver_prices','gal_driver_prices_registry','gal_driver_product_markets','gal_driver_product_markets_registry','gal_driver_registry','gal_driver_release_snapshots','gal_driver_retailers','gal_driver_sources',
    'gal_putter_commerce_routes','gal_putter_master_registry','gal_putter_prices','gal_putter_release_snapshots','gal_putter_sources',
    'gal_release_artifacts','gal_release_data_files','gal_release_registry',
    'gal_wedge_commerce_routes','gal_wedge_master_registry','gal_wedge_prices','gal_wedge_release_snapshots','gal_wedge_sources'
  ];
begin
  foreach t in array tables loop
    if to_regclass('public.'||t) is not null and not exists(
      select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access'
    ) then raise exception 'missing explicit deny policy on %',t; end if;
  end loop;
  if to_regclass('public.gal_wedge_commerce_routes_product_fk_idx') is null then raise exception 'missing wedge commerce FK index'; end if;
  if to_regclass('public.gal_wedge_prices_product_fk_idx') is null then raise exception 'missing wedge prices FK index'; end if;
end $$;

rollback;
