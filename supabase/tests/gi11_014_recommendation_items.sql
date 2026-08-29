-- GI-1.1 Recommendation Auditability Task 6: recommendation items + Fit Score components.
-- TDD contract: deterministic item results remain commerce-independent, Fit Score is 0-100,
-- confidence is separate, current-equipment outcomes are first-class, and component math reconciles.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(38);

select has_table('public','gal_recommendation_items','GI-REC-ITEM-001 recommendation items table exists');
select has_column('public','gal_recommendation_items','recommendation_item_id','GI-REC-ITEM-002 stable public item id exists');
select has_column('public','gal_recommendation_items','recommendation_run_id','GI-REC-ITEM-003 run reference exists');
select has_column('public','gal_recommendation_items','user_id','GI-REC-ITEM-004 canonical golfer id exists');
select has_column('public','gal_recommendation_items','result_type','GI-REC-ITEM-005 result type exists');
select has_column('public','gal_recommendation_items','canonical_product_id','GI-REC-ITEM-006 optional canonical product exists');
select has_column('public','gal_recommendation_items','configuration','GI-REC-ITEM-007 recommendation configuration exists');
select has_column('public','gal_recommendation_items','eligibility_status','GI-REC-ITEM-008 eligibility status exists');
select has_column('public','gal_recommendation_items','exclusion_reason','GI-REC-ITEM-009 exclusion reason exists');
select has_column('public','gal_recommendation_items','fit_score','GI-REC-ITEM-010 Fit Score exists');
select has_column('public','gal_recommendation_items','recommendation_rank','GI-REC-ITEM-011 rank exists');
select has_column('public','gal_recommendation_items','confidence','GI-REC-ITEM-012 confidence exists separately');
select has_column('public','gal_recommendation_items','strengths','GI-REC-ITEM-013 structured strengths exist');
select has_column('public','gal_recommendation_items','tradeoffs','GI-REC-ITEM-014 structured tradeoffs exist');
select has_column('public','gal_recommendation_items','current_equipment_delta','GI-REC-ITEM-015 current-equipment delta exists');
select has_column('public','gal_recommendation_items','price_evidence','GI-REC-ITEM-016 price evidence exists');
select has_column('public','gal_recommendation_items','availability_evidence','GI-REC-ITEM-017 availability evidence exists');

select has_table('public','gal_fit_score_components','GI-REC-COMP-001 Fit Score components table exists');
select has_column('public','gal_fit_score_components','recommendation_item_id','GI-REC-COMP-002 component links recommendation item');
select has_column('public','gal_fit_score_components','component_key','GI-REC-COMP-003 component key exists');
select has_column('public','gal_fit_score_components','raw_score','GI-REC-COMP-004 raw score exists');
select has_column('public','gal_fit_score_components','normalized_score','GI-REC-COMP-005 normalized score exists');
select has_column('public','gal_fit_score_components','weight','GI-REC-COMP-006 weight exists');
select has_column('public','gal_fit_score_components','weighted_score','GI-REC-COMP-007 weighted score exists');
select has_column('public','gal_fit_score_components','evidence','GI-REC-COMP-008 evidence exists');
select has_column('public','gal_fit_score_components','model_version','GI-REC-COMP-009 model version exists');

select ok(not exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name in ('gal_recommendation_items','gal_fit_score_components')
    and column_name in ('commission','commission_rate','affiliate_payout','retailer_payout','network_payout','affiliate_network','commerce_score')
), 'GI-REC-005 recommendation scoring schema contains no commerce payout fields');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_recommendation_items'),false),
 'GI-REC-ITEM-018 recommendation item RLS is enabled');
select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_fit_score_components'),false),
 'GI-REC-COMP-010 components RLS is enabled');
select ok(case when to_regclass('public.gal_recommendation_items') is null then false else has_table_privilege('authenticated','public.gal_recommendation_items','SELECT') end,
 'GI-REC-ITEM-019 golfer can read own recommendation items');
select ok(case when to_regclass('public.gal_recommendation_items') is null then false else not has_table_privilege('authenticated','public.gal_recommendation_items','INSERT') end,
 'GI-REC-ITEM-020 golfer cannot forge recommendation items');
select ok(case when to_regclass('public.gal_fit_score_components') is null then false else has_table_privilege('authenticated','public.gal_fit_score_components','SELECT') end,
 'GI-REC-COMP-011 golfer can read own score components');
select ok(case when to_regclass('public.gal_fit_score_components') is null then false else not has_table_privilege('authenticated','public.gal_fit_score_components','INSERT') end,
 'GI-REC-COMP-012 golfer cannot forge score components');

insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000114','gi11-item-a@example.test','{}','{}');
insert into public.gal_users(id,gal_user_id,auth_user_id,account_status) values
 ('10000000-0000-0000-0000-000000000114','GAL-ITEM-A','00000000-0000-0000-0000-000000000114','ACTIVE');
insert into public.gal_bags(id,bag_id,user_id,name,is_active,market_code,currency) values
 ('20000000-0000-0000-0000-000000000114','GAL-BAG-ITEM-A','10000000-0000-0000-0000-000000000114','Primary',true,'US','USD');
insert into public.gal_catalog_products(canonical_product_id,canonical_brand_id,category,display_brand,display_model,source_dataset,source_dataset_version,is_active)
values ('GAL-PROD-REC-DRIVER','GAL-BRAND-REC','DRIVER','Test Brand','Fit Driver','GI11_TEST','1.0',true);

set local role service_role;
insert into public.gal_profile_snapshots(id,profile_snapshot_id,user_id,snapshot_type,profile_version,facts_snapshot,inference_snapshot,captured_at)
values ('30000000-0000-0000-0000-000000000114','GAL-PS-ITEM-A','10000000-0000-0000-0000-000000000114','RECOMMENDATION','PROFILE-1.0','{}','{}','2026-08-29T20:00:00Z');
insert into public.gal_bag_snapshots(id,bag_snapshot_id,user_id,bag_id,snapshot_type,bag_version,items_snapshot,club_count,market_code,currency,captured_at)
values ('40000000-0000-0000-0000-000000000114','GAL-BS-ITEM-A','10000000-0000-0000-0000-000000000114','20000000-0000-0000-0000-000000000114','RECOMMENDATION','BAG-1.0','[]',14,'US','USD','2026-08-29T20:00:00Z');
insert into public.gal_recommendation_runs(
 id,recommendation_run_id,user_id,run_type,category,status,profile_snapshot_id,bag_snapshot_id,
 equipment_data_version,fit_model_version,category_model_version,guide_version,question_engine_version,
 normalized_inputs,result_summary,market_code,currency,started_at,completed_at
) values (
 '50000000-0000-0000-0000-000000000114','GAL-RUN-ITEM-A','10000000-0000-0000-0000-000000000114','BUYER_GUIDE','DRIVER','COMPLETED',
 '30000000-0000-0000-0000-000000000114','40000000-0000-0000-0000-000000000114',
 'EQ-TEST-1','FIT-1.0','DRIVER-FIT-1.0','DRIVER-GUIDE-1.0','QUESTION-1.0','{}','{}','US','USD','2026-08-29T20:01:00Z','2026-08-29T20:02:00Z'
);

select lives_ok($q$
 insert into public.gal_recommendation_items(
   id,recommendation_item_id,recommendation_run_id,user_id,result_type,canonical_product_id,configuration,
   eligibility_status,fit_score,recommendation_rank,confidence,strengths,tradeoffs,current_equipment_delta,
   price_evidence,availability_evidence
 ) values
 ('60000000-0000-0000-0000-000000000114','GAL-RI-PRODUCT','50000000-0000-0000-0000-000000000114','10000000-0000-0000-0000-000000000114',
  'PRODUCT_OPTION','GAL-PROD-REC-DRIVER','{"loft":10.5}','ELIGIBLE',88.0,1,0.91,'["forgiveness"]','["higher flight"]',4.0,
  '{"amount":499,"currency":"USD"}','{"status":"AVAILABLE"}'),
 ('60000000-0000-0000-0000-000000000214','GAL-RI-KEEP','50000000-0000-0000-0000-000000000114','10000000-0000-0000-0000-000000000114',
  'KEEP_CURRENT',null,'{}','ELIGIBLE',86.0,2,0.95,'["already fits well"]','["small distance gap remains"]',0.0,'{}','{}'),
 ('60000000-0000-0000-0000-000000000314','GAL-RI-RECONFIG','50000000-0000-0000-0000-000000000114','10000000-0000-0000-0000-000000000114',
  'RECONFIGURE_CURRENT',null,'{"loft":9.5}','ELIGIBLE',87.0,3,0.89,'["lower launch"]','["requires adjustment"]',2.0,'{}','{}')
$q$, 'GI-REC-004 KEEP_CURRENT and RECONFIGURE_CURRENT are valid first-class results');

select lives_ok($q$
 insert into public.gal_fit_score_components(
   recommendation_item_id,user_id,component_key,raw_score,normalized_score,weight,weighted_score,evidence,model_version
 ) values
 ('60000000-0000-0000-0000-000000000114','10000000-0000-0000-0000-000000000114','launch_fit',92,92,0.50,46.0,'{"source":"deterministic"}','FIT-1.0'),
 ('60000000-0000-0000-0000-000000000114','10000000-0000-0000-0000-000000000114','forgiveness_fit',84,84,0.50,42.0,'{"source":"deterministic"}','FIT-1.0')
$q$, 'GI-REC-001 deterministic Fit Score components are persisted');

select is(
 (select round(sum(weighted_score)::numeric,2) from public.gal_fit_score_components where recommendation_item_id='60000000-0000-0000-0000-000000000114'),
 (select round(fit_score::numeric,2) from public.gal_recommendation_items where id='60000000-0000-0000-0000-000000000114'),
 'GI-REC-002 component weighted scores reconcile to stored Fit Score'
);

select throws_ok($q$
 insert into public.gal_recommendation_items(recommendation_run_id,user_id,result_type,eligibility_status,fit_score,confidence)
 values ('50000000-0000-0000-0000-000000000114','10000000-0000-0000-0000-000000000114','PRODUCT_OPTION','ELIGIBLE',101,0.8)
$q$, '23514', null, 'GI-REC-006 Fit Score is bounded at 100');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000114","role":"authenticated"}',true);
select is((select count(*)::integer from public.gal_recommendation_items),3,'GI-REC-ITEM-021 golfer reads own complete shortlist evidence');
select is((select count(*)::integer from public.gal_fit_score_components),2,'GI-REC-COMP-013 golfer reads own component evidence');

reset role;
select * from finish();
rollback;
