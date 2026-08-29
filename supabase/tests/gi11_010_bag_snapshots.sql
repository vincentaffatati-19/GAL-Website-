-- GI-1.1 Jerry's Bag Task 2: immutable whole-bag snapshots.
-- TDD contract: trusted system freezes bag state; golfer can read only own snapshots;
-- later edits to the live bag cannot rewrite recommendation-time evidence.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(28);

select has_table('public', 'gal_bag_snapshots', 'GI-BAG-SNAP-001 bag snapshots table exists');
select has_column('public', 'gal_bag_snapshots', 'id', 'GI-BAG-SNAP-002 internal UUID id exists');
select has_column('public', 'gal_bag_snapshots', 'bag_snapshot_id', 'GI-BAG-SNAP-003 stable public snapshot id exists');
select has_column('public', 'gal_bag_snapshots', 'user_id', 'GI-BAG-SNAP-004 canonical golfer id exists');
select has_column('public', 'gal_bag_snapshots', 'bag_id', 'GI-BAG-SNAP-005 bag id exists');
select has_column('public', 'gal_bag_snapshots', 'snapshot_type', 'GI-BAG-SNAP-006 snapshot type exists');
select has_column('public', 'gal_bag_snapshots', 'bag_version', 'GI-BAG-SNAP-007 bag version exists');
select has_column('public', 'gal_bag_snapshots', 'items_snapshot', 'GI-BAG-SNAP-008 item evidence JSON exists');
select has_column('public', 'gal_bag_snapshots', 'club_count', 'GI-BAG-SNAP-009 physical club count exists');
select has_column('public', 'gal_bag_snapshots', 'market_code', 'GI-BAG-SNAP-010 market exists');
select has_column('public', 'gal_bag_snapshots', 'currency', 'GI-BAG-SNAP-011 currency exists');
select has_column('public', 'gal_bag_snapshots', 'captured_at', 'GI-BAG-SNAP-012 capture timestamp exists');
select has_column('public', 'gal_bag_snapshots', 'created_at', 'GI-BAG-SNAP-013 created timestamp exists');

select ok(coalesce((
  select c.relrowsecurity
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='gal_bag_snapshots'
), false), 'GI-BAG-SNAP-014 RLS is enabled');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else has_table_privilege('authenticated', 'public.gal_bag_snapshots', 'SELECT') end,
  'GI-BAG-SNAP-015 authenticated can read owned snapshots');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else not has_table_privilege('authenticated', 'public.gal_bag_snapshots', 'INSERT') end,
  'GI-BAG-SNAP-016 authenticated cannot insert snapshots');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else not has_table_privilege('authenticated', 'public.gal_bag_snapshots', 'UPDATE') end,
  'GI-BAG-SNAP-017 authenticated cannot update snapshots');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else not has_table_privilege('authenticated', 'public.gal_bag_snapshots', 'DELETE') end,
  'GI-BAG-SNAP-018 authenticated cannot delete snapshots');
select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_bag_snapshots'
    and policyname='gal_bag_snapshots_self_select' and cmd='SELECT'
    and roles @> array['authenticated']::name[]
), 'GI-BAG-SNAP-019 owner SELECT policy exists');
select ok(not exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_bag_snapshots'
    and cmd in ('INSERT','UPDATE','DELETE') and roles @> array['authenticated']::name[]
), 'GI-BAG-SNAP-020 no authenticated mutation policy exists');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else has_table_privilege('service_role', 'public.gal_bag_snapshots', 'INSERT') end,
  'GI-BAG-SNAP-021 trusted system can insert snapshots');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else not has_table_privilege('service_role', 'public.gal_bag_snapshots', 'UPDATE') end,
  'GI-BAG-SNAP-022 trusted system cannot rewrite snapshots');
select ok(case when to_regclass('public.gal_bag_snapshots') is null then false else not has_table_privilege('service_role', 'public.gal_bag_snapshots', 'DELETE') end,
  'GI-BAG-SNAP-023 trusted system cannot delete snapshots');
select ok(exists(
  select 1 from pg_indexes
  where schemaname='public' and tablename='gal_bag_snapshots'
    and indexdef ~* '\(user_id, captured_at DESC\)'
), 'GI-BAG-SNAP-024 user/time replay index exists');

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-000000000110'::uuid, 'gi11-bag-snap-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000210'::uuid, 'gi11-bag-snap-b@example.test', '{}'::jsonb, '{}'::jsonb);
insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-000000000110'::uuid, 'GAL-BS-A', '00000000-0000-0000-0000-000000000110'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-000000000210'::uuid, 'GAL-BS-B', '00000000-0000-0000-0000-000000000210'::uuid, 'ACTIVE');
insert into public.gal_bags (id, bag_id, user_id, name, is_active, market_code, currency)
values
  ('20000000-0000-0000-0000-000000000110'::uuid, 'GAL-BAG-BS-A', '10000000-0000-0000-0000-000000000110'::uuid, 'Primary Bag', true, 'US', 'USD'),
  ('20000000-0000-0000-0000-000000000210'::uuid, 'GAL-BAG-BS-B', '10000000-0000-0000-0000-000000000210'::uuid, 'Other Bag', true, 'US', 'USD');
insert into public.gal_bag_items (
  id, bag_item_id, bag_id, user_id, item_type, category, slot_code, slot_label,
  display_snapshot, configuration, bag_status, counts_toward_14, club_count, owned,
  identification_status, identification_confidence
) values (
  '30000000-0000-0000-0000-000000000110'::uuid, 'GAL-BI-BS-A1',
  '20000000-0000-0000-0000-000000000110'::uuid,
  '10000000-0000-0000-0000-000000000110'::uuid,
  'CLUB', 'DRIVER', 'DRIVER', 'Driver', '{"model":"Snapshot Driver"}'::jsonb,
  '{"loft":10.5,"shaft":"Blue"}'::jsonb, 'IN_BAG', true, 1, true, 'PARTIAL', 0.800
);

set local role service_role;
select lives_ok($q$
  insert into public.gal_bag_snapshots (
    bag_snapshot_id, user_id, bag_id, snapshot_type, bag_version,
    items_snapshot, club_count, market_code, currency, captured_at
  ) values
  (
    'GAL-BS-TEST-A1', '10000000-0000-0000-0000-000000000110'::uuid,
    '20000000-0000-0000-0000-000000000110'::uuid, 'RECOMMENDATION', 'BAG-1.0',
    '[{"bag_item_id":"GAL-BI-BS-A1","configuration":{"loft":10.5,"shaft":"Blue"}}]'::jsonb,
    1, 'US', 'USD', '2026-08-29T19:05:00Z'::timestamptz
  ),
  (
    'GAL-BS-TEST-B1', '10000000-0000-0000-0000-000000000210'::uuid,
    '20000000-0000-0000-0000-000000000210'::uuid, 'RECOMMENDATION', 'BAG-1.0',
    '[]'::jsonb, 0, 'US', 'USD', '2026-08-29T19:06:00Z'::timestamptz
  )
$q$, 'GI-BAG-SNAP-025 trusted system freezes two bag snapshots');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000110","role":"authenticated"}', true);
select lives_ok($q$
  do $d$
  declare v_count bigint;
  begin
    execute $$select count(*) from public.gal_bag_snapshots$$ into v_count;
    if v_count <> 1 then raise exception 'expected one visible own snapshot, got %', v_count; end if;
  end
  $d$
$q$, 'GI-BAG-SNAP-026 golfer reads only own snapshot');

update public.gal_bag_items
set configuration='{"loft":9.0,"shaft":"Black"}'::jsonb
where bag_item_id='GAL-BI-BS-A1';

select lives_ok($q$
  do $d$
  declare v_value text;
  begin
    execute $$select items_snapshot #>> '{0,configuration,shaft}' from public.gal_bag_snapshots where bag_snapshot_id='GAL-BS-TEST-A1'$$ into v_value;
    if v_value is distinct from 'Blue' then raise exception 'snapshot was rewritten: %', v_value; end if;
  end
  $d$
$q$, 'GI-BAG-SNAP-027 frozen snapshot survives later live-bag edits');
select throws_ok(
  $$update public.gal_bag_snapshots set bag_version='MUTATED' where bag_snapshot_id='GAL-BS-TEST-A1'$$,
  '42501', null,
  'GI-BAG-SNAP-028 golfer cannot rewrite frozen snapshot'
);

reset role;
select * from finish();
rollback;
