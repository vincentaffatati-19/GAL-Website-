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
    if to_regclass('public.'||t) is not null
       and not exists(select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon,authenticated using(false) with check(false)',t);
    end if;
  end loop;
end $$;

create index if not exists gal_wedge_commerce_routes_product_fk_idx on public.gal_wedge_commerce_routes(canonical_product_id);
create index if not exists gal_wedge_prices_product_fk_idx on public.gal_wedge_prices(canonical_product_id);
