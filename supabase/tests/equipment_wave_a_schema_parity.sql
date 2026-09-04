-- Equipment Knowledge Wave A schema parity verification
-- Verifies the legacy/reference structures required by later normalized migrations.

do $$
declare
  missing text[];
begin
  select array_agg(t)
  into missing
  from unnest(array[
    'gal_catalog_products',
    'gal_bags',
    'gal_bag_items',
    'gal_profile_facts',
    'gal_decision_snapshots',
    'gal_valuation_snapshots',
    'gal_release_registry',
    'gal_release_artifacts',
    'gal_driver_registry',
    'gal_driver_master_registry',
    'gal_driver_sources'
  ]) as t
  where to_regclass('public.' || t) is null;

  if missing is not null then
    raise exception 'equipment schema parity missing tables: %', missing;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_catalog_products'
      and column_name='canonical_product_id'
  ) then raise exception 'gal_catalog_products.canonical_product_id missing'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_bag_items'
      and column_name='configuration'
  ) then raise exception 'gal_bag_items.configuration missing'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_profile_facts'
      and column_name='fact_key'
  ) then raise exception 'gal_profile_facts.fact_key missing'; end if;
end $$;

-- Fingerprint-critical constraints used by later migrations.
do $$
begin
  if not exists (select 1 from pg_constraint where conname='gal_catalog_products_pkey') then
    raise exception 'gal_catalog_products primary key missing';
  end if;
  if not exists (select 1 from pg_constraint where conname='gal_bag_items_canonical_product_id_fkey') then
    raise exception 'gal_bag_items canonical product FK missing';
  end if;
  if not exists (select 1 from pg_constraint where conname='gal_profile_facts_user_fact_scope_key') then
    raise exception 'gal_profile_facts unique scope constraint missing';
  end if;
end $$;
