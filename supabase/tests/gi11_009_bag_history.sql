-- GI-1.1 Jerry's Bag Task 1: current bag metadata + immutable item lifecycle history.
-- TDD contract: current bag remains golfer-editable, while lifecycle evidence is append-only,
-- owner-readable, partial identification is valid, and existing 14-club validation still works.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(30);

select has_column('public', 'gal_bags', 'bag_type', 'GI-BAG-001A bag type metadata exists');
select has_column('public', 'gal_bags', 'archived_at', 'GI-BAG-001B bag archive timestamp exists');
select has_column('public', 'gal_bag_items', 'identification_status', 'GI-BAG-001C item identification status exists');
select has_column('public', 'gal_bag_items', 'identification_confidence', 'GI-BAG-001D item identification confidence exists');
select has_column('public', 'gal_bag_items', 'effective_from', 'GI-BAG-001E item effective-from timestamp exists');

select has_table('public', 'gal_bag_item_history', 'GI-BAG-002A bag item history table exists');
select has_column('public', 'gal_bag_item_history', 'history_id', 'GI-BAG-002B stable history id exists');
select has_column('public', 'gal_bag_item_history', 'user_id', 'GI-BAG-002C history has canonical golfer id');
select has_column('public', 'gal_bag_item_history', 'bag_id', 'GI-BAG-002D history has bag id');
select has_column('public', 'gal_bag_item_history', 'bag_item_id', 'GI-BAG-002E history preserves internal bag-item id');
select has_column('public', 'gal_bag_item_history', 'bag_item_public_id', 'GI-BAG-002F history preserves public bag-item id');
select has_column('public', 'gal_bag_item_history', 'change_type', 'GI-BAG-002G history has lifecycle change type');
select has_column('public', 'gal_bag_item_history', 'configuration', 'GI-BAG-002H history preserves configuration');
select has_column('public', 'gal_bag_item_history', 'effective_from', 'GI-BAG-002I history has effective-from');
select has_column('public', 'gal_bag_item_history', 'effective_to', 'GI-BAG-002J history has effective-to');

select ok(coalesce((
  select c.relrowsecurity
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='gal_bag_item_history'
), false), 'GI-BAG-002K history RLS is enabled');
select ok(case when to_regclass('public.gal_bag_item_history') is null then false else has_table_privilege('authenticated', 'public.gal_bag_item_history', 'SELECT') end,
  'GI-BAG-002L authenticated can read owned history');
select ok(case when to_regclass('public.gal_bag_item_history') is null then false else not has_table_privilege('authenticated', 'public.gal_bag_item_history', 'INSERT') end,
  'GI-BAG-002M authenticated cannot insert history directly');
select ok(case when to_regclass('public.gal_bag_item_history') is null then false else not has_table_privilege('authenticated', 'public.gal_bag_item_history', 'UPDATE') end,
  'GI-BAG-002N authenticated cannot update history');
select ok(case when to_regclass('public.gal_bag_item_history') is null then false else not has_table_privilege('authenticated', 'public.gal_bag_item_history', 'DELETE') end,
  'GI-BAG-002O authenticated cannot delete history');
select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_bag_item_history'
    and policyname='gal_bag_item_history_self_select' and cmd='SELECT'
    and roles @> array['authenticated']::name[]
), 'GI-BAG-002P owner SELECT policy exists');
select ok(not exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_bag_item_history'
    and cmd in ('INSERT','UPDATE','DELETE') and roles @> array['authenticated']::name[]
), 'GI-BAG-002Q no authenticated mutation policy exists');
select ok(exists(
  select 1 from pg_indexes
  where schemaname='public' and tablename='gal_bag_item_history'
    and indexdef ~* '\(user_id, bag_id, created_at DESC\)'
), 'GI-BAG-002R user/bag history replay index exists');

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-000000000109'::uuid, 'gi11-bag-history-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000209'::uuid, 'gi11-bag-history-b@example.test', '{}'::jsonb, '{}'::jsonb);

insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-000000000109'::uuid, 'GAL-BH-A', '00000000-0000-0000-0000-000000000109'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-000000000209'::uuid, 'GAL-BH-B', '00000000-0000-0000-0000-000000000209'::uuid, 'ACTIVE');

insert into public.gal_catalog_products (
  canonical_product_id, canonical_brand_id, category, display_brand, display_model,
  source_dataset, source_dataset_version, is_active
) values
  ('GAL-PROD-BH-IRON-A', 'GAL-BRAND-BH', 'IRON', 'Test Brand', 'Iron A', 'GI11_TEST', '1.0', true),
  ('GAL-PROD-BH-IRON-B', 'GAL-BRAND-BH', 'IRON', 'Test Brand', 'Iron B', 'GI11_TEST', '1.0', true);

insert into public.gal_bags (id, bag_id, user_id, name, is_active, market_code, currency)
values
  ('20000000-0000-0000-0000-000000000109'::uuid, 'GAL-BAG-BH-A', '10000000-0000-0000-0000-000000000109'::uuid, 'Primary Bag', true, 'US', 'USD'),
  ('20000000-0000-0000-0000-000000000209'::uuid, 'GAL-BAG-BH-B', '10000000-0000-0000-0000-000000000209'::uuid, 'Other Bag', true, 'US', 'USD');

insert into public.gal_bag_items (
  id, bag_item_id, bag_id, user_id, item_type, category, slot_code, slot_label,
  canonical_product_id, canonical_brand_id, display_snapshot, configuration,
  bag_status, counts_toward_14, club_count, owned
) values
  (
    '30000000-0000-0000-0000-000000000109'::uuid, 'GAL-BI-BH-A1',
    '20000000-0000-0000-0000-000000000109'::uuid,
    '10000000-0000-0000-0000-000000000109'::uuid,
    'CLUB', 'IRON', 'IRONS', 'Iron Set', 'GAL-PROD-BH-IRON-A', 'GAL-BRAND-BH',
    '{"model":"Iron A"}'::jsonb, '{"shaft":"Steel A"}'::jsonb,
    'IN_BAG', true, 14, true
  ),
  (
    '30000000-0000-0000-0000-000000000209'::uuid, 'GAL-BI-BH-B1',
    '20000000-0000-0000-0000-000000000209'::uuid,
    '10000000-0000-0000-0000-000000000209'::uuid,
    'CLUB', 'IRON', 'IRONS', 'Iron Set', 'GAL-PROD-BH-IRON-A', 'GAL-BRAND-BH',
    '{"model":"Iron A"}'::jsonb, '{"shaft":"Steel X"}'::jsonb,
    'IN_BAG', false, 1, true
  );

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000109","role":"authenticated"}', true);

select lives_ok($q$
  insert into public.gal_bag_items (
    bag_item_id, bag_id, user_id, item_type, category, slot_code, slot_label,
    canonical_product_id, canonical_brand_id, display_snapshot, configuration,
    bag_status, counts_toward_14, club_count, owned,
    identification_status, identification_confidence, effective_from
  ) values (
    'GAL-BI-BH-PARTIAL',
    '20000000-0000-0000-0000-000000000109'::uuid,
    '10000000-0000-0000-0000-000000000109'::uuid,
    'CLUB', 'HYBRID', 'HYBRID-4', '4 Hybrid',
    null, 'GAL-BRAND-BH', '{"brand":"Test Brand","model":"Unknown Hybrid"}'::jsonb,
    '{}'::jsonb, 'IN_BAG', false, 1, true,
    'PARTIAL', 0.650, '2026-08-29T18:00:00Z'::timestamptz
  )
$q$, 'GI-BAG-003 partial product identity is valid and not fabricated');

select lives_ok($q$
  update public.gal_bag_items
  set configuration='{"shaft":"Steel B"}'::jsonb,
      effective_from='2026-08-29T18:10:00Z'::timestamptz
  where bag_item_id='GAL-BI-BH-A1'
$q$, 'GI-BAG-004 golfer can reconfigure current owned item');

select lives_ok($q$
  do $d$
  declare v_count bigint;
  begin
    execute $$select count(*) from public.gal_bag_item_history
             where bag_item_public_id='GAL-BI-BH-A1'
               and change_type='RECONFIGURED'
               and configuration->>'shaft'='Steel A'$$ into v_count;
    if v_count <> 1 then raise exception 'expected one preserved reconfiguration row, got %', v_count; end if;
  end
  $d$
$q$, 'GI-BAG-005 reconfiguration preserves prior configuration');

select lives_ok($q$
  update public.gal_bag_items
  set canonical_product_id='GAL-PROD-BH-IRON-B',
      display_snapshot='{"model":"Iron B"}'::jsonb,
      effective_from='2026-08-29T18:20:00Z'::timestamptz
  where bag_item_id='GAL-BI-BH-A1'
$q$, 'GI-BAG-006 golfer can replace current item identity');

select lives_ok($q$
  do $d$
  declare v_count bigint;
  begin
    execute $$select count(*) from public.gal_bag_item_history
             where bag_item_public_id='GAL-BI-BH-A1'
               and change_type='REPLACED'
               and canonical_product_id='GAL-PROD-BH-IRON-A'$$ into v_count;
    if v_count <> 1 then raise exception 'expected one preserved replacement row, got %', v_count; end if;
  end
  $d$
$q$, 'GI-BAG-007 replacement preserves prior product identity');

select lives_ok($q$
  do $d$
  declare v_other bigint;
  begin
    execute $$select count(*) from public.gal_bag_item_history where user_id='10000000-0000-0000-0000-000000000209'::uuid$$ into v_other;
    if v_other <> 0 then raise exception 'cross-user history leaked: %', v_other; end if;
  end
  $d$
$q$, 'GI-BAG-008 golfer cannot read another golfer history');

select throws_ok(
  $$update public.gal_bag_item_history set change_reason='tampered' where bag_item_public_id='GAL-BI-BH-A1'$$,
  '42501', null,
  'GI-BAG-009 golfer cannot mutate immutable history'
);

select is(
  (select club_count from public.gal_my_bag_validation where bag_id='20000000-0000-0000-0000-000000000109'::uuid),
  14,
  'GI-BAG-010 existing 14-club current-bag validation remains correct'
);

reset role;
select * from finish();
rollback;
