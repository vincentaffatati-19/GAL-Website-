-- GI-1.1 Foundation Task 8: immutable profile snapshots.
-- TDD contract: recommendation-time profile state is preserved as immutable evidence,
-- system-written and readable only by the owning golfer.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(24);

select has_table('public', 'gal_profile_snapshots', 'GI-SNAP-001 profile snapshots table exists');
select has_column('public', 'gal_profile_snapshots', 'id', 'GI-SNAP-002 internal UUID id exists');
select has_column('public', 'gal_profile_snapshots', 'profile_snapshot_id', 'GI-SNAP-003 stable public snapshot id exists');
select has_column('public', 'gal_profile_snapshots', 'user_id', 'GI-SNAP-004 canonical golfer FK exists');
select has_column('public', 'gal_profile_snapshots', 'snapshot_type', 'GI-SNAP-005 snapshot type exists');
select has_column('public', 'gal_profile_snapshots', 'profile_version', 'GI-SNAP-006 profile version exists');
select has_column('public', 'gal_profile_snapshots', 'facts_snapshot', 'GI-SNAP-007 facts snapshot JSON exists');
select has_column('public', 'gal_profile_snapshots', 'inference_snapshot', 'GI-SNAP-008 inference snapshot JSON exists');
select has_column('public', 'gal_profile_snapshots', 'state_generation_id', 'GI-SNAP-009 optional state generation id exists');
select has_column('public', 'gal_profile_snapshots', 'captured_at', 'GI-SNAP-010 captured timestamp exists');
select has_column('public', 'gal_profile_snapshots', 'created_at', 'GI-SNAP-011 created timestamp exists');

select ok(coalesce((
  select c.relrowsecurity
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='gal_profile_snapshots'
), false), 'GI-SNAP-012 RLS is enabled');
select ok(has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'SELECT'), 'GI-SNAP-013 authenticated can read snapshots');
select ok(not has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'INSERT'), 'GI-SNAP-014 authenticated cannot insert snapshots');
select ok(not has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'UPDATE'), 'GI-SNAP-015 authenticated cannot update snapshots');
select ok(not has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'DELETE'), 'GI-SNAP-016 authenticated cannot delete snapshots');
select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_profile_snapshots'
    and policyname='gal_profile_snapshots_self_select' and cmd='SELECT'
    and roles @> array['authenticated']::name[]
), 'GI-SNAP-017 own SELECT policy exists');
select ok(not exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_profile_snapshots'
    and cmd in ('INSERT','UPDATE','DELETE') and roles @> array['authenticated']::name[]
), 'GI-SNAP-018 no authenticated mutation policy exists');

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-000000000108'::uuid, 'gi11-snapshot-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000208'::uuid, 'gi11-snapshot-b@example.test', '{}'::jsonb, '{}'::jsonb);

insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-000000000108'::uuid, 'GAL-SNAP-A', '00000000-0000-0000-0000-000000000108'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-000000000208'::uuid, 'GAL-SNAP-B', '00000000-0000-0000-0000-000000000208'::uuid, 'ACTIVE');

insert into public.gal_profile_snapshots (
  profile_snapshot_id, user_id, snapshot_type, profile_version,
  facts_snapshot, inference_snapshot, state_generation_id, captured_at
) values
  (
    'GAL-PS-TEST-A1',
    '10000000-0000-0000-0000-000000000108'::uuid,
    'RECOMMENDATION',
    'GI-1.1',
    '{"game.handicap_index":{"value":12.8,"source_type":"DECLARED"}}'::jsonb,
    '{"swing.driver.speed_mph":{"value":{"min":90,"max":96},"confidence":0.82,"model_version":"MODEL-1.0"}}'::jsonb,
    'STATE-GEN-TEST-001',
    '2026-08-29T17:10:00Z'::timestamptz
  ),
  (
    'GAL-PS-TEST-B1',
    '10000000-0000-0000-0000-000000000208'::uuid,
    'RECOMMENDATION',
    'GI-1.1',
    '{"game.handicap_index":{"value":8.4,"source_type":"DECLARED"}}'::jsonb,
    '{}'::jsonb,
    null,
    '2026-08-29T17:11:00Z'::timestamptz
  );

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000108","role":"authenticated"}', true);

select results_eq(
  $$select profile_snapshot_id from public.gal_profile_snapshots order by profile_snapshot_id$$,
  $$values ('GAL-PS-TEST-A1'::text)$$,
  'GI-SNAP-019 golfer reads only own snapshot'
);
select is(
  (select facts_snapshot #>> '{game.handicap_index,value}' from public.gal_profile_snapshots where profile_snapshot_id='GAL-PS-TEST-A1'),
  '12.8'::text,
  'GI-SNAP-020 fact evidence is preserved'
);
select is(
  (select inference_snapshot #>> '{swing.driver.speed_mph,model_version}' from public.gal_profile_snapshots where profile_snapshot_id='GAL-PS-TEST-A1'),
  'MODEL-1.0'::text,
  'GI-SNAP-021 inference provenance is preserved'
);
select throws_ok(
  $$update public.gal_profile_snapshots set profile_version='MUTATED' where profile_snapshot_id='GAL-PS-TEST-A1'$$,
  '42501', null,
  'GI-SNAP-022 golfer cannot update own snapshot'
);
select throws_ok(
  $$delete from public.gal_profile_snapshots where profile_snapshot_id='GAL-PS-TEST-A1'$$,
  '42501', null,
  'GI-SNAP-023 golfer cannot delete own snapshot'
);

reset role;
select ok(exists(
  select 1 from pg_indexes
  where schemaname='public' and tablename='gal_profile_snapshots'
    and indexdef ~* '\(user_id, captured_at DESC\)'
), 'GI-SNAP-024 user/captured-at replay index exists');

select * from finish();
rollback;
