-- Equipment Knowledge Wave A schema parity verification
-- Expected RED before 20260904010000_equipment_wave_a_schema_parity.sql and GREEN after.

do $$
declare
  missing text[];
begin
  select array_agg(t)
  into missing
  from unnest(array[
    'gal_catalog_products','gal_bags','gal_bag_items','gal_profile_facts',
    'gal_decision_snapshots','gal_valuation_snapshots','gal_release_registry',
    'gal_release_artifacts','gal_driver_registry','gal_driver_master_registry','gal_driver_sources'
  ]) as t
  where to_regclass('public.' || t) is null;

  if missing is not null then
    raise exception 'equipment schema parity missing tables: %', missing;
  end if;
end $$;

do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_catalog_products' and column_name='canonical_product_id') then
    raise exception 'gal_catalog_products.canonical_product_id missing';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_bag_items' and column_name='configuration') then
    raise exception 'gal_bag_items.configuration missing';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_profile_facts' and column_name='fact_key') then
    raise exception 'gal_profile_facts.fact_key missing';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_decision_snapshots' and column_name='immutable') then
    raise exception 'gal_decision_snapshots.immutable missing';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_valuation_snapshots' and column_name='valuation_type') then
    raise exception 'gal_valuation_snapshots.valuation_type missing';
  end if;
end $$;

do $$
declare
  missing_type text;
begin
  select v into missing_type
  from unnest(array['gal_category','gal_item_type','gal_bag_status','gal_valuation_type','gal_valuation_status','gal_confidence']) v
  where not exists (select 1 from pg_type where typname=v)
  limit 1;
  if missing_type is not null then raise exception 'equipment schema parity missing enum: %', missing_type; end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='gal_catalog_category_idx') then raise exception 'gal_catalog_category_idx missing'; end if;
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='gal_bag_items_product_idx') then raise exception 'gal_bag_items_product_idx missing'; end if;
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='gal_profile_facts_user_key_idx') then raise exception 'gal_profile_facts_user_key_idx missing'; end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_catalog_products' and policyname='gal_catalog_read_authenticated') then raise exception 'catalog RLS policy missing'; end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_bags' and policyname='gal_bags_self_all') then raise exception 'bags RLS policy missing'; end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_profile_facts' and policyname='gal_profile_facts_self_select') then raise exception 'profile RLS policy missing'; end if;
end $$;
