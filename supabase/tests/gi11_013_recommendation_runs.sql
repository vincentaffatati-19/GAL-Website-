-- GI-1.1 Recommendation Auditability Task 5: recommendation runs.
-- TDD contract: each run freezes the input/snapshot/version chain while allowing only
-- bounded trusted lifecycle transitions; golfers may read only their own runs.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(32);

select has_table('public','gal_recommendation_runs','GI-REC-RUN-001 recommendation runs table exists');
select has_column('public','gal_recommendation_runs','recommendation_run_id','GI-REC-RUN-002 stable public run id exists');
select has_column('public','gal_recommendation_runs','user_id','GI-REC-RUN-003 canonical golfer id exists');
select has_column('public','gal_recommendation_runs','run_type','GI-REC-RUN-004 run type exists');
select has_column('public','gal_recommendation_runs','category','GI-REC-RUN-005 category exists');
select has_column('public','gal_recommendation_runs','status','GI-REC-RUN-006 lifecycle status exists');
select has_column('public','gal_recommendation_runs','profile_snapshot_id','GI-REC-RUN-007 profile snapshot reference exists');
select has_column('public','gal_recommendation_runs','bag_snapshot_id','GI-REC-RUN-008 bag snapshot reference exists');
select has_column('public','gal_recommendation_runs','scenario_id','GI-REC-RUN-009 optional scenario reference exists');
select has_column('public','gal_recommendation_runs','equipment_data_version','GI-REC-RUN-010 equipment data version exists');
select has_column('public','gal_recommendation_runs','fit_model_version','GI-REC-RUN-011 fit model version exists');
select has_column('public','gal_recommendation_runs','category_model_version','GI-REC-RUN-012 category model version exists');
select has_column('public','gal_recommendation_runs','guide_version','GI-REC-RUN-013 guide version exists');
select has_column('public','gal_recommendation_runs','bag_optimization_version','GI-REC-RUN-014 bag optimization version exists');
select has_column('public','gal_recommendation_runs','question_engine_version','GI-REC-RUN-015 question engine version exists');
select has_column('public','gal_recommendation_runs','ai_explanation_version','GI-REC-RUN-016 AI explanation version metadata exists');
select has_column('public','gal_recommendation_runs','normalized_inputs','GI-REC-RUN-017 normalized deterministic inputs are frozen');
select has_column('public','gal_recommendation_runs','result_summary','GI-REC-RUN-018 structured result summary exists');
select has_column('public','gal_recommendation_runs','market_code','GI-REC-RUN-019 market context exists');
select has_column('public','gal_recommendation_runs','currency','GI-REC-RUN-020 currency context exists');
select has_column('public','gal_recommendation_runs','started_at','GI-REC-RUN-021 start timestamp exists');
select has_column('public','gal_recommendation_runs','completed_at','GI-REC-RUN-022 completion timestamp exists');
select has_column('public','gal_recommendation_runs','superseded_at','GI-REC-RUN-023 superseded timestamp exists');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_recommendation_runs'),false),
 'GI-REC-RUN-024 RLS is enabled');
select ok(case when to_regclass('public.gal_recommendation_runs') is null then false else has_table_privilege('authenticated','public.gal_recommendation_runs','SELECT') end,
 'GI-REC-RUN-025 golfer can read own runs');
select ok(case when to_regclass('public.gal_recommendation_runs') is null then false else not has_table_privilege('authenticated','public.gal_recommendation_runs','INSERT') end,
 'GI-REC-RUN-026 golfer cannot forge a recommendation run');
select ok(case when to_regclass('public.gal_recommendation_runs') is null then false else not has_table_privilege('authenticated','public.gal_recommendation_runs','UPDATE') end,
 'GI-REC-RUN-027 golfer cannot rewrite a run');
select ok(case when to_regclass('public.gal_recommendation_runs') is null then false else not has_table_privilege('authenticated','public.gal_recommendation_runs','DELETE') end,
 'GI-REC-RUN-028 golfer cannot delete a run');

insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000113','gi11-run-a@example.test','{}','{}'),
 ('00000000-0000-0000-0000-000000000213','gi11-run-b@example.test','{}','{}');
insert into public.gal_users(id,gal_user_id,auth_user_id,account_status) values
 ('10000000-0000-0000-0000-000000000113','GAL-RUN-A','00000000-0000-0000-0000-000000000113','ACTIVE'),
 ('10000000-0000-0000-0000-000000000213','GAL-RUN-B','00000000-0000-0000-0000-000000000213','ACTIVE');
insert into public.gal_bags(id,bag_id,user_id,name,is_active,market_code,currency) values
 ('20000000-0000-0000-0000-000000000113','GAL-BAG-RUN-A','10000000-0000-0000-0000-000000000113','Primary',true,'US','USD'),
 ('20000000-0000-0000-0000-000000000213','GAL-BAG-RUN-B','10000000-0000-0000-0000-000000000213','Primary',true,'US','USD');

set local role service_role;
insert into public.gal_profile_snapshots(id,profile_snapshot_id,user_id,snapshot_type,profile_version,facts_snapshot,inference_snapshot,captured_at) values
 ('30000000-0000-0000-0000-000000000113','GAL-PS-RUN-A','10000000-0000-0000-0000-000000000113','RECOMMENDATION','PROFILE-1.0','{}','{}','2026-08-29T19:50:00Z'),
 ('30000000-0000-0000-0000-000000000213','GAL-PS-RUN-B','10000000-0000-0000-0000-000000000213','RECOMMENDATION','PROFILE-1.0','{}','{}','2026-08-29T19:50:00Z');
insert into public.gal_bag_snapshots(id,bag_snapshot_id,user_id,bag_id,snapshot_type,bag_version,items_snapshot,club_count,market_code,currency,captured_at) values
 ('40000000-0000-0000-0000-000000000113','GAL-BS-RUN-A','10000000-0000-0000-0000-000000000113','20000000-0000-0000-0000-000000000113','RECOMMENDATION','BAG-1.0','[]',14,'US','USD','2026-08-29T19:50:00Z'),
 ('40000000-0000-0000-0000-000000000213','GAL-BS-RUN-B','10000000-0000-0000-0000-000000000213','20000000-0000-0000-0000-000000000213','RECOMMENDATION','BAG-1.0','[]',14,'US','USD','2026-08-29T19:50:00Z');

select lives_ok($q$
 insert into public.gal_recommendation_runs(
   id,recommendation_run_id,user_id,run_type,category,status,profile_snapshot_id,bag_snapshot_id,
   equipment_data_version,fit_model_version,category_model_version,guide_version,bag_optimization_version,
   question_engine_version,ai_explanation_version,normalized_inputs,result_summary,market_code,currency,started_at
 ) values
 ('50000000-0000-0000-0000-000000000113','GAL-RUN-TEST-A','10000000-0000-0000-0000-000000000113','BUYER_GUIDE','DRIVER','RUNNING',
  '30000000-0000-0000-0000-000000000113','40000000-0000-0000-0000-000000000113',
  'EQ-TEST-1','FIT-1.0','DRIVER-FIT-1.0','DRIVER-GUIDE-1.0','BAG-OPT-1.0','QUESTION-1.0','EXPLAIN-1.0',
  '{"handedness":"RIGHT","driver_speed_mph":95}','{}','US','USD','2026-08-29T19:51:00Z'),
 ('50000000-0000-0000-0000-000000000213','GAL-RUN-TEST-B','10000000-0000-0000-0000-000000000213','BUYER_GUIDE','DRIVER','COMPLETED',
  '30000000-0000-0000-0000-000000000213','40000000-0000-0000-0000-000000000213',
  'EQ-TEST-1','FIT-1.0','DRIVER-FIT-1.0','DRIVER-GUIDE-1.0','BAG-OPT-1.0','QUESTION-1.0','EXPLAIN-1.0',
  '{}','{"result_count":3}','US','USD','2026-08-29T19:51:00Z')
$q$, 'GI-REC-RUN-029 trusted system creates fully versioned runs');

select lives_ok($q$
 update public.gal_recommendation_runs
 set status='COMPLETED',completed_at='2026-08-29T19:52:00Z',result_summary='{"result_count":4}'
 where recommendation_run_id='GAL-RUN-TEST-A'
$q$, 'GI-REC-RUN-030 trusted lifecycle completion is allowed');

select throws_ok(
 $$update public.gal_recommendation_runs set fit_model_version='FIT-MUTATED' where recommendation_run_id='GAL-RUN-TEST-A'$$,
 '42501', null,
 'GI-REC-RUN-031 frozen version chain cannot be rewritten after creation'
);

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000113","role":"authenticated"}',true);
select lives_ok($q$
 do $d$ declare v_count bigint; begin
   select count(*) into v_count from public.gal_recommendation_runs;
   if v_count <> 1 then raise exception 'expected one own recommendation run, got %',v_count; end if;
 end $d$
$q$, 'GI-REC-RUN-032 golfer reads only own recommendation history');

reset role;
select * from finish();
rollback;
