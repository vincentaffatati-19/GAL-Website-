-- GI-1.1 Jerry's Bag Task 4: immutable bag optimization score snapshots.
-- TDD contract: bag optimization is separate from product Fit Score, versioned,
-- confidence-aware, evidence-bearing, golfer-readable, and system-written/immutable.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(28);

select has_table('public','gal_bag_score_snapshots','GI-BAG-SCORE-001 bag score snapshot table exists');
select has_column('public','gal_bag_score_snapshots','bag_score_snapshot_id','GI-BAG-SCORE-002 stable score snapshot id exists');
select has_column('public','gal_bag_score_snapshots','user_id','GI-BAG-SCORE-003 canonical golfer id exists');
select has_column('public','gal_bag_score_snapshots','bag_id','GI-BAG-SCORE-004 bag id exists');
select has_column('public','gal_bag_score_snapshots','bag_snapshot_id','GI-BAG-SCORE-005 immutable bag snapshot reference exists');
select has_column('public','gal_bag_score_snapshots','scenario_id','GI-BAG-SCORE-006 optional scenario reference exists');
select has_column('public','gal_bag_score_snapshots','profile_snapshot_id','GI-BAG-SCORE-007 immutable profile snapshot reference exists');
select has_column('public','gal_bag_score_snapshots','optimization_score','GI-BAG-SCORE-008 optimization score exists');
select has_column('public','gal_bag_score_snapshots','confidence','GI-BAG-SCORE-009 confidence exists separately');
select has_column('public','gal_bag_score_snapshots','components','GI-BAG-SCORE-010 component evidence exists');
select has_column('public','gal_bag_score_snapshots','bag_optimization_version','GI-BAG-SCORE-011 optimization model version exists');
select has_column('public','gal_bag_score_snapshots','equipment_data_version','GI-BAG-SCORE-012 equipment data version exists');
select has_column('public','gal_bag_score_snapshots','captured_at','GI-BAG-SCORE-013 capture timestamp exists');
select has_column('public','gal_bag_score_snapshots','created_at','GI-BAG-SCORE-014 created timestamp exists');

select ok(not exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_bag_score_snapshots'
    and column_name in ('age_penalty','age_score','equipment_age_penalty')
), 'GI-BAG-SCORE-015 age is not a required penalty field');

select ok(coalesce((
  select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='gal_bag_score_snapshots'
),false),'GI-BAG-SCORE-016 RLS is enabled');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else has_table_privilege('authenticated','public.gal_bag_score_snapshots','SELECT') end,
  'GI-BAG-SCORE-017 golfer can read owned bag score snapshots');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else not has_table_privilege('authenticated','public.gal_bag_score_snapshots','INSERT') end,
  'GI-BAG-SCORE-018 golfer cannot create score evidence');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else not has_table_privilege('authenticated','public.gal_bag_score_snapshots','UPDATE') end,
  'GI-BAG-SCORE-019 golfer cannot rewrite score evidence');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else not has_table_privilege('authenticated','public.gal_bag_score_snapshots','DELETE') end,
  'GI-BAG-SCORE-020 golfer cannot delete score evidence');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else has_table_privilege('service_role','public.gal_bag_score_snapshots','INSERT') end,
  'GI-BAG-SCORE-021 trusted system can create score evidence');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else not has_table_privilege('service_role','public.gal_bag_score_snapshots','UPDATE') end,
  'GI-BAG-SCORE-022 trusted system cannot rewrite score snapshots');
select ok(case when to_regclass('public.gal_bag_score_snapshots') is null then false else not has_table_privilege('service_role','public.gal_bag_score_snapshots','DELETE') end,
  'GI-BAG-SCORE-023 trusted system cannot delete score snapshots');
select ok(exists(
  select 1 from pg_policies where schemaname='public' and tablename='gal_bag_score_snapshots'
    and policyname='gal_bag_score_snapshots_self_select' and cmd='SELECT'
    and roles @> array['authenticated']::name[]
), 'GI-BAG-SCORE-024 owner SELECT policy exists');

insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000112','gi11-score-a@example.test','{}','{}'),
 ('00000000-0000-0000-0000-000000000212','gi11-score-b@example.test','{}','{}');
insert into public.gal_users(id,gal_user_id,auth_user_id,account_status) values
 ('10000000-0000-0000-0000-000000000112','GAL-SCORE-A','00000000-0000-0000-0000-000000000112','ACTIVE'),
 ('10000000-0000-0000-0000-000000000212','GAL-SCORE-B','00000000-0000-0000-0000-000000000212','ACTIVE');
insert into public.gal_bags(id,bag_id,user_id,name,is_active,market_code,currency) values
 ('20000000-0000-0000-0000-000000000112','GAL-BAG-SCORE-A','10000000-0000-0000-0000-000000000112','Primary',true,'US','USD'),
 ('20000000-0000-0000-0000-000000000212','GAL-BAG-SCORE-B','10000000-0000-0000-0000-000000000212','Primary',true,'US','USD');

set local role service_role;
insert into public.gal_profile_snapshots(
 id,profile_snapshot_id,user_id,snapshot_type,profile_version,facts_snapshot,inference_snapshot,captured_at
) values
 ('30000000-0000-0000-0000-000000000112','GAL-PS-SCORE-A','10000000-0000-0000-0000-000000000112','RECOMMENDATION','PROFILE-1.0','{}','{}','2026-08-29T19:40:00Z'),
 ('30000000-0000-0000-0000-000000000212','GAL-PS-SCORE-B','10000000-0000-0000-0000-000000000212','RECOMMENDATION','PROFILE-1.0','{}','{}','2026-08-29T19:40:00Z');
insert into public.gal_bag_snapshots(
 id,bag_snapshot_id,user_id,bag_id,snapshot_type,bag_version,items_snapshot,club_count,market_code,currency,captured_at
) values
 ('40000000-0000-0000-0000-000000000112','GAL-BS-SCORE-A','10000000-0000-0000-0000-000000000112','20000000-0000-0000-0000-000000000112','RECOMMENDATION','BAG-1.0','[]',14,'US','USD','2026-08-29T19:40:00Z'),
 ('40000000-0000-0000-0000-000000000212','GAL-BS-SCORE-B','10000000-0000-0000-0000-000000000212','20000000-0000-0000-0000-000000000212','RECOMMENDATION','BAG-1.0','[]',14,'US','USD','2026-08-29T19:40:00Z');

select lives_ok($q$
  insert into public.gal_bag_score_snapshots(
    bag_score_snapshot_id,user_id,bag_id,bag_snapshot_id,profile_snapshot_id,
    optimization_score,confidence,components,bag_optimization_version,equipment_data_version,captured_at
  ) values
  ('GAL-BSS-TEST-A','10000000-0000-0000-0000-000000000112','20000000-0000-0000-0000-000000000112',
   '40000000-0000-0000-0000-000000000112','30000000-0000-0000-0000-000000000112',
   87.5,0.920,'[{"component":"gapping","score":90},{"component":"structure","score":85}]',
   'BAG-OPT-1.0','EQ-TEST-1','2026-08-29T19:41:00Z'),
  ('GAL-BSS-TEST-B','10000000-0000-0000-0000-000000000212','20000000-0000-0000-0000-000000000212',
   '40000000-0000-0000-0000-000000000212','30000000-0000-0000-0000-000000000212',
   72.0,0.800,'[]','BAG-OPT-1.0','EQ-TEST-1','2026-08-29T19:41:00Z')
$q$, 'GI-BAG-SCORE-025 trusted system writes bounded, versioned scores');

select throws_ok($q$
  insert into public.gal_bag_score_snapshots(
    user_id,bag_id,bag_snapshot_id,profile_snapshot_id,optimization_score,confidence,components,bag_optimization_version,equipment_data_version
  ) values (
    '10000000-0000-0000-0000-000000000112','20000000-0000-0000-0000-000000000112',
    '40000000-0000-0000-0000-000000000112','30000000-0000-0000-0000-000000000112',101,0.9,'[]','BAG-OPT-1.0','EQ-TEST-1'
  )
$q$, '23514', null, 'GI-BAG-SCORE-026 optimization score cannot exceed 100');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000112","role":"authenticated"}',true);
select lives_ok($q$
 do $d$ declare v_count bigint; begin
   select count(*) into v_count from public.gal_bag_score_snapshots;
   if v_count <> 1 then raise exception 'expected one owned score snapshot, got %',v_count; end if;
 end $d$
$q$, 'GI-BAG-SCORE-027 golfer sees only own immutable score evidence');
select throws_ok(
  $$update public.gal_bag_score_snapshots set optimization_score=1 where bag_score_snapshot_id='GAL-BSS-TEST-A'$$,
  '42501', null,
  'GI-BAG-SCORE-028 golfer cannot rewrite stored optimization evidence'
);

reset role;
select * from finish();
rollback;
