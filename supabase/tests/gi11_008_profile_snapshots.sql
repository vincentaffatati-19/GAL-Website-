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

select ok(case when to_regclass('public.gal_profile_snapshots') is null then false else has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'SELECT') end,
  'GI-SNAP-013 authenticated can read snapshots');
select ok(case when to_regclass('public.gal_profile_snapshots') is null then false else not has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'INSERT') end,
  'GI-SNAP-014 authenticated cannot insert snapshots');
select ok(case when to_regclass('public.gal_profile_snapshots') is null then false else not has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'UPDATE') end,
  'GI-SNAP-015 authenticated cannot update snapshots');
select ok(case when to_regclass('public.gal_profile_snapshots') is null then false else not has_table_privilege('authenticated', 'public.gal_profile_snapshots', 'DELETE') end,
  'GI-SNAP-016 authenticated cannot delete snapshots');
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

select lives_ok($q$
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
  )
$q$, 'GI-SNAP-019 trusted system path can create immutable snapshots');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000108","role":"authenticated"}', true);

select lives_ok($q$
  do $d$
  declare v_count bigint;
  begin
    execute 'select count(*) from public.gal_profile_snapshots' into v_count;
    if v_count <> 1 then raise exception 'expected exactly one visible own snapshot, got %', v_count; end if;
  end
  $d$
$q$, 'GI-SNAP-020 golfer reads only own snapshot');

select lives_ok($q$
  do $d$
  declare v_value text;
  begin
    execute $$select facts_snapshot #>> '{game.handicap_index,value}' from public.gal_profile_snapshots where profile_snapshot_id='GAL-PS-TEST-A1'$$ into v_value;
    if v_value is distinct from '12.8' then raise exception 'fact evidence changed: %', v_value; end if;
  end
  $d$
$q$, 'GI-SNAP-021 fact evidence is preserved');

select lives_ok($q$
  do $d$
  declare v_value text;
  begin
    execute $$select inference_snapshot #>> '{swing.driver.speed_mph,model_version}' from public.gal_profile_snapshots where profile_snapshot_id='GAL-PS-TEST-A1'$$ into v_value;
    if v_value is distinct from 'MODEL-1.0' then raise exception 'inference provenance changed: %', v_value; end if;
  end
  $d$
$q$, 'GI-SNAP-022 inference provenance is preserved');

select throws_ok(
  $$update public.gal_profile_snapshots set profile_version='MUTATED' where profile_snapshot_id='GAL-PS-TEST-A1'$$,
  '42501', null,
  'GI-SNAP-023 golfer cannot update own snapshot'
);

reset role;
select ok(exists(
  select 1 from pg_indexes
  where schemaname='public' and tablename='gal_profile_snapshots'
    and indexdef ~* '\(user_id, captured_at DESC\)'
), 'GI-SNAP-024 user/captured-at replay index exists');

select * from finish();
rollback;
