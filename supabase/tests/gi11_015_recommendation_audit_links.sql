-- GI-1.1 Recommendation Auditability Task 7: link legacy decision snapshots into normalized audit chain.
-- TDD contract: links are additive/nullable, owned by the same golfer, and preserve legacy read-only behavior.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(25);

create or replace function pg_temp.gi11_fk_exists(p_column text, p_ref_table text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    join pg_class rt on rt.oid = c.confrelid
    join pg_namespace rn on rn.oid = rt.relnamespace
    join unnest(c.conkey) with ordinality ck(attnum, ord) on true
    join pg_attribute a on a.attrelid = t.oid and a.attnum = ck.attnum
    where c.contype = 'f'
      and n.nspname = 'public'
      and t.relname = 'gal_decision_snapshots'
      and a.attname = p_column
      and rn.nspname = 'public'
      and rt.relname = p_ref_table
  );
$$;

create or replace function pg_temp.gi11_audit_chain_ok()
returns boolean
language plpgsql
as $$
declare
  v_ok boolean;
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_decision_snapshots'
      and column_name in ('recommendation_run_id','recommendation_item_id','profile_snapshot_id','bag_snapshot_id')
    group by table_schema, table_name
    having count(*) = 4
  ) then
    return false;
  end if;

  execute $q$
    select exists (
      select 1
      from public.gal_decision_snapshots d
      join public.gal_recommendation_items i on i.id = d.recommendation_item_id
      join public.gal_recommendation_runs r on r.id = d.recommendation_run_id and r.id = i.recommendation_run_id
      join public.gal_profile_snapshots ps on ps.id = d.profile_snapshot_id and ps.id = r.profile_snapshot_id
      join public.gal_bag_snapshots bs on bs.id = d.bag_snapshot_id and bs.id = r.bag_snapshot_id
      where d.decision_snapshot_id = 'GAL-DS-AUDIT-A'
        and d.user_id = i.user_id
        and d.user_id = r.user_id
        and d.user_id = ps.user_id
        and d.user_id = bs.user_id
    )
  $q$ into v_ok;
  return coalesce(v_ok,false);
end;
$$;

select has_column('public','gal_decision_snapshots','recommendation_run_id','GI-REC-AUDIT-001 recommendation run link exists');
select has_column('public','gal_decision_snapshots','recommendation_item_id','GI-REC-AUDIT-002 recommendation item link exists');
select has_column('public','gal_decision_snapshots','profile_snapshot_id','GI-REC-AUDIT-003 profile snapshot link exists');
select has_column('public','gal_decision_snapshots','bag_snapshot_id','GI-REC-AUDIT-004 bag snapshot link exists');

select ok(pg_temp.gi11_fk_exists('recommendation_run_id','gal_recommendation_runs'),'GI-REC-AUDIT-005 run link is a foreign key');
select ok(pg_temp.gi11_fk_exists('recommendation_item_id','gal_recommendation_items'),'GI-REC-AUDIT-006 item link is a foreign key');
select ok(pg_temp.gi11_fk_exists('profile_snapshot_id','gal_profile_snapshots'),'GI-REC-AUDIT-007 profile link is a foreign key');
select ok(pg_temp.gi11_fk_exists('bag_snapshot_id','gal_bag_snapshots'),'GI-REC-AUDIT-008 bag link is a foreign key');

select ok((select count(*) = 4 from pg_indexes where schemaname='public' and tablename='gal_decision_snapshots' and indexname in (
  'gal_decision_snapshots_run_idx','gal_decision_snapshots_item_idx','gal_decision_snapshots_profile_idx','gal_decision_snapshots_bag_idx'
)), 'GI-REC-AUDIT-009 audit links are indexed');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_decision_snapshots'),false),
 'GI-REC-AUDIT-010 decision snapshot RLS remains enabled');
select ok(has_table_privilege('authenticated','public.gal_decision_snapshots','SELECT'),'GI-REC-AUDIT-011 golfer retains read access');
select ok(not has_table_privilege('authenticated','public.gal_decision_snapshots','INSERT'),'GI-REC-AUDIT-012 golfer cannot forge decisions');
select ok(not has_table_privilege('authenticated','public.gal_decision_snapshots','UPDATE'),'GI-REC-AUDIT-013 golfer cannot rewrite decisions');
select ok(not has_table_privilege('authenticated','public.gal_decision_snapshots','DELETE'),'GI-REC-AUDIT-014 golfer cannot delete decisions');
select ok(has_table_privilege('service_role','public.gal_decision_snapshots','INSERT'),'GI-REC-AUDIT-015 trusted system can create decision evidence');
select ok(not has_table_privilege('service_role','public.gal_decision_snapshots','UPDATE'),'GI-REC-AUDIT-016 trusted system cannot rewrite decision evidence');
select ok(not has_table_privilege('service_role','public.gal_decision_snapshots','DELETE'),'GI-REC-AUDIT-017 trusted system cannot delete decision evidence');

insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000115','gi11-audit-a@example.test','{}','{}'),
 ('00000000-0000-0000-0000-000000000215','gi11-audit-b@example.test','{}','{}');
insert into public.gal_users(id,gal_user_id,auth_user_id,account_status) values
 ('10000000-0000-0000-0000-000000000115','GAL-AUDIT-A','00000000-0000-0000-0000-000000000115','ACTIVE'),
 ('10000000-0000-0000-0000-000000000215','GAL-AUDIT-B','00000000-0000-0000-0000-000000000215','ACTIVE');
insert into public.gal_bags(id,bag_id,user_id,name,is_active,market_code,currency) values
 ('20000000-0000-0000-0000-000000000115','GAL-BAG-AUDIT-A','10000000-0000-0000-0000-000000000115','Primary',true,'US','USD');
insert into public.gal_catalog_products(canonical_product_id,canonical_brand_id,category,display_brand,display_model,source_dataset,source_dataset_version,is_active)
values ('GAL-PROD-AUDIT-DRIVER','GAL-BRAND-AUDIT','DRIVER','Audit Brand','Audit Driver','GI11_TEST','1.0',true);

set local role service_role;
insert into public.gal_profile_snapshots(id,profile_snapshot_id,user_id,snapshot_type,profile_version,facts_snapshot,inference_snapshot,captured_at)
values ('30000000-0000-0000-0000-000000000115','GAL-PS-AUDIT-A','10000000-0000-0000-0000-000000000115','RECOMMENDATION','PROFILE-1.0','{}','{}','2026-08-29T20:20:00Z');
insert into public.gal_bag_snapshots(id,bag_snapshot_id,user_id,bag_id,snapshot_type,bag_version,items_snapshot,club_count,market_code,currency,captured_at)
values ('40000000-0000-0000-0000-000000000115','GAL-BS-AUDIT-A','10000000-0000-0000-0000-000000000115','20000000-0000-0000-0000-000000000115','RECOMMENDATION','BAG-1.0','[]',14,'US','USD','2026-08-29T20:20:00Z');
insert into public.gal_recommendation_runs(
 id,recommendation_run_id,user_id,run_type,category,status,profile_snapshot_id,bag_snapshot_id,
 equipment_data_version,fit_model_version,category_model_version,guide_version,question_engine_version,
 normalized_inputs,result_summary,market_code,currency,started_at,completed_at
) values (
 '50000000-0000-0000-0000-000000000115','GAL-RUN-AUDIT-A','10000000-0000-0000-0000-000000000115','BUYER_GUIDE','DRIVER','COMPLETED',
 '30000000-0000-0000-0000-000000000115','40000000-0000-0000-0000-000000000115',
 'EQ-TEST-1','FIT-1.0','DRIVER-FIT-1.0','DRIVER-GUIDE-1.0','QUESTION-1.0','{}','{}','US','USD','2026-08-29T20:21:00Z','2026-08-29T20:22:00Z'
);
insert into public.gal_recommendation_items(
 id,recommendation_item_id,recommendation_run_id,user_id,result_type,canonical_product_id,configuration,
 eligibility_status,fit_score,recommendation_rank,confidence,strengths,tradeoffs,current_equipment_delta,price_evidence,availability_evidence
) values (
 '60000000-0000-0000-0000-000000000115','GAL-RI-AUDIT-A','50000000-0000-0000-0000-000000000115','10000000-0000-0000-0000-000000000115',
 'PRODUCT_OPTION','GAL-PROD-AUDIT-DRIVER','{}','ELIGIBLE',91,1,0.94,'[]','[]',5,'{}','{}'
);

select lives_ok($q$
 insert into public.gal_decision_snapshots(
   id,decision_snapshot_id,user_id,canonical_product_id,canonical_brand_id,captured_at,source_tool,source_tool_version,
   recommendation_rank,user_inputs,metrics,reason_summary,market_code,immutable
 ) values (
   '70000000-0000-0000-0000-000000000215','GAL-DS-LEGACY-A','10000000-0000-0000-0000-000000000115',
   'GAL-PROD-AUDIT-DRIVER','GAL-BRAND-AUDIT','2026-08-29T20:22:30Z','DRIVER_GUIDE','1.0',1,'{}','[]','legacy-compatible','US',true
 )
$q$, 'GI-REC-AUDIT-018 legacy unlinked decision snapshots remain insert-compatible');

select lives_ok($q$
 insert into public.gal_decision_snapshots(
   id,decision_snapshot_id,user_id,canonical_product_id,canonical_brand_id,captured_at,source_tool,source_tool_version,
   recommendation_rank,user_inputs,metrics,reason_summary,market_code,immutable,
   recommendation_run_id,recommendation_item_id,profile_snapshot_id,bag_snapshot_id
 ) values (
   '70000000-0000-0000-0000-000000000115','GAL-DS-AUDIT-A','10000000-0000-0000-0000-000000000115',
   'GAL-PROD-AUDIT-DRIVER','GAL-BRAND-AUDIT','2026-08-29T20:23:00Z','DRIVER_GUIDE','GI-1.1',1,'{}','[]','normalized audit','US',true,
   '50000000-0000-0000-0000-000000000115','60000000-0000-0000-0000-000000000115',
   '30000000-0000-0000-0000-000000000115','40000000-0000-0000-0000-000000000115'
 )
$q$, 'GI-REC-AUDIT-019 trusted system can create a fully linked decision snapshot');

select ok(pg_temp.gi11_audit_chain_ok(),'GI-REC-003 decision traces through item/run to frozen profile and bag snapshots');
select throws_ok($q$
 update public.gal_decision_snapshots set recommendation_rank=2 where decision_snapshot_id='GAL-DS-AUDIT-A'
$q$, '42501', null, 'GI-REC-AUDIT-020 decision evidence cannot be rewritten');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000115","role":"authenticated"}',true);
select is((select count(*)::integer from public.gal_decision_snapshots where decision_snapshot_id in ('GAL-DS-AUDIT-A','GAL-DS-LEGACY-A')),2,
 'GI-REC-AUDIT-021 golfer reads own linked and legacy decision evidence');

select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000215","role":"authenticated"}',true);
select is((select count(*)::integer from public.gal_decision_snapshots where decision_snapshot_id in ('GAL-DS-AUDIT-A','GAL-DS-LEGACY-A')),0,
 'GI-REC-AUDIT-022 cross-golfer decision history is denied');

reset role;
select * from finish();
rollback;
