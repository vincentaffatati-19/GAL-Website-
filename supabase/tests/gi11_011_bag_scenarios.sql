-- GI-1.1 Jerry's Bag Task 3: what-if scenarios + explicit atomic adoption.
-- TDD contract: golfer-owned scenarios are isolated from the live bag until a trusted adoption;
-- adoption applies scenario actions, writes bag history through existing triggers, and freezes the result.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(34);

select has_table('public', 'gal_bag_scenarios', 'GI-BAG-SCN-001 scenario table exists');
select has_column('public', 'gal_bag_scenarios', 'scenario_id', 'GI-BAG-SCN-002 stable public scenario id exists');
select has_column('public', 'gal_bag_scenarios', 'user_id', 'GI-BAG-SCN-003 scenario has canonical golfer id');
select has_column('public', 'gal_bag_scenarios', 'bag_id', 'GI-BAG-SCN-004 scenario has live bag id');
select has_column('public', 'gal_bag_scenarios', 'status', 'GI-BAG-SCN-005 scenario status exists');
select has_column('public', 'gal_bag_scenarios', 'profile_snapshot_id', 'GI-BAG-SCN-006 optional profile snapshot exists');
select has_column('public', 'gal_bag_scenarios', 'base_bag_snapshot_id', 'GI-BAG-SCN-007 base bag snapshot exists');
select has_column('public', 'gal_bag_scenarios', 'context', 'GI-BAG-SCN-008 scenario context exists');
select has_column('public', 'gal_bag_scenarios', 'fit_model_version', 'GI-BAG-SCN-009 fit model version exists');
select has_column('public', 'gal_bag_scenarios', 'equipment_data_version', 'GI-BAG-SCN-010 equipment data version exists');

select has_table('public', 'gal_bag_scenario_items', 'GI-BAG-SCN-011 scenario items table exists');
select has_column('public', 'gal_bag_scenario_items', 'action_type', 'GI-BAG-SCN-012 scenario action type exists');
select has_column('public', 'gal_bag_scenario_items', 'target_bag_item_id', 'GI-BAG-SCN-013 target live item reference exists');
select has_column('public', 'gal_bag_scenario_items', 'canonical_product_id', 'GI-BAG-SCN-014 proposed product identity exists');
select has_column('public', 'gal_bag_scenario_items', 'configuration', 'GI-BAG-SCN-015 proposed configuration exists');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_bag_scenarios'), false),
  'GI-BAG-SCN-016 scenario RLS is enabled');
select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_bag_scenario_items'), false),
  'GI-BAG-SCN-017 scenario item RLS is enabled');
select ok(case when to_regclass('public.gal_bag_scenarios') is null then false else has_table_privilege('authenticated','public.gal_bag_scenarios','SELECT') end,
  'GI-BAG-SCN-018 authenticated can select own scenarios');
select ok(case when to_regclass('public.gal_bag_scenarios') is null then false else has_table_privilege('authenticated','public.gal_bag_scenarios','INSERT') end,
  'GI-BAG-SCN-019 authenticated can create own scenarios');
select ok(case when to_regclass('public.gal_bag_scenarios') is null then false else has_table_privilege('authenticated','public.gal_bag_scenarios','UPDATE') end,
  'GI-BAG-SCN-020 authenticated can edit open scenarios');
select ok(case when to_regclass('public.gal_bag_scenarios') is null then false else has_table_privilege('authenticated','public.gal_bag_scenarios','DELETE') end,
  'GI-BAG-SCN-021 authenticated can discard/delete own draft scenarios');
select ok(exists(select 1 from pg_policies where schemaname='public' and tablename='gal_bag_scenarios' and policyname='gal_bag_scenarios_self_all' and roles @> array['authenticated']::name[]),
  'GI-BAG-SCN-022 scenario owner ALL policy exists');
select ok(exists(select 1 from pg_policies where schemaname='public' and tablename='gal_bag_scenario_items' and policyname='gal_bag_scenario_items_self_all' and roles @> array['authenticated']::name[]),
  'GI-BAG-SCN-023 scenario item owner ALL policy exists');

select ok(to_regprocedure('gal_private.gal_adopt_bag_scenario(uuid,text)') is not null,
  'GI-BAG-SCN-024 trusted adoption routine exists');
select ok(case when to_regprocedure('gal_private.gal_adopt_bag_scenario(uuid,text)') is null then false else not has_function_privilege('authenticated','gal_private.gal_adopt_bag_scenario(uuid,text)','EXECUTE') end,
  'GI-BAG-SCN-025 golfer cannot directly execute trusted adoption');
select ok(case when to_regprocedure('gal_private.gal_adopt_bag_scenario(uuid,text)') is null then false else has_function_privilege('service_role','gal_private.gal_adopt_bag_scenario(uuid,text)','EXECUTE') end,
  'GI-BAG-SCN-026 service role can execute trusted adoption');

insert into auth.users (id,email,raw_app_meta_data,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000111','gi11-scn-a@example.test','{}','{}'),
 ('00000000-0000-0000-0000-000000000211','gi11-scn-b@example.test','{}','{}');
insert into public.gal_users (id,gal_user_id,auth_user_id,account_status) values
 ('10000000-0000-0000-0000-000000000111','GAL-SCN-A','00000000-0000-0000-0000-000000000111','ACTIVE'),
 ('10000000-0000-0000-0000-000000000211','GAL-SCN-B','00000000-0000-0000-0000-000000000211','ACTIVE');
insert into public.gal_bags (id,bag_id,user_id,name,is_active,market_code,currency) values
 ('20000000-0000-0000-0000-000000000111','GAL-BAG-SCN-A','10000000-0000-0000-0000-000000000111','Primary',true,'US','USD'),
 ('20000000-0000-0000-0000-000000000211','GAL-BAG-SCN-B','10000000-0000-0000-0000-000000000211','Primary',true,'US','USD');
insert into public.gal_bag_items (
 id,bag_item_id,bag_id,user_id,item_type,category,slot_code,slot_label,display_snapshot,configuration,
 bag_status,counts_toward_14,club_count,owned,identification_status,identification_confidence
) values (
 '30000000-0000-0000-0000-000000000111','GAL-BI-SCN-DRIVER','20000000-0000-0000-0000-000000000111','10000000-0000-0000-0000-000000000111',
 'CLUB','DRIVER','DRIVER','Driver','{"model":"Current Driver"}','{"loft":10.5,"shaft":"Blue"}','IN_BAG',true,1,true,'PARTIAL',0.8
);

set local role service_role;
insert into public.gal_bag_snapshots (
 bag_snapshot_id,user_id,bag_id,snapshot_type,bag_version,items_snapshot,club_count,market_code,currency,captured_at
) values (
 'GAL-BS-SCN-BASE','10000000-0000-0000-0000-000000000111','20000000-0000-0000-0000-000000000111','MANUAL','BAG-1.0',
 '[{"bag_item_id":"GAL-BI-SCN-DRIVER","configuration":{"loft":10.5,"shaft":"Blue"}}]',1,'US','USD','2026-08-29T19:20:00Z'
);

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000111","role":"authenticated"}',true);

select lives_ok($q$
  insert into public.gal_bag_scenarios (
    id,scenario_id,user_id,bag_id,base_bag_snapshot_id,name,status,category,context,
    fit_model_version,bag_optimization_version,equipment_data_version,market_code,currency
  ) values (
    '40000000-0000-0000-0000-000000000111','GAL-SCN-TEST-A','10000000-0000-0000-0000-000000000111',
    '20000000-0000-0000-0000-000000000111','50000000-0000-0000-0000-000000000111','Try a different top end','OPEN','DRIVER',
    '{"surface":"jerrys_bag"}','DRIVER-FIT-1.0','BAG-OPT-1.0','EQ-TEST-1','US','USD'
  )
$q$, 'GI-BAG-SCN-027 golfer can create an owned what-if scenario');

-- The base snapshot's internal id is dynamic in production, so repair the synthetic FK dynamically after insert.
select lives_ok($q$
  update public.gal_bag_scenarios
  set base_bag_snapshot_id=(select id from public.gal_bag_snapshots where bag_snapshot_id='GAL-BS-SCN-BASE')
  where scenario_id='GAL-SCN-TEST-A'
$q$, 'GI-BAG-SCN-028 scenario can bind to an immutable base bag snapshot');

select lives_ok($q$
  insert into public.gal_bag_scenario_items (
    scenario_id,user_id,action_type,target_bag_item_id,item_type,category,slot_code,slot_label,
    canonical_product_id,canonical_brand_id,display_snapshot,configuration,
    identification_status,identification_confidence,counts_toward_14,club_count,owned
  ) values
  (
    '40000000-0000-0000-0000-000000000111','10000000-0000-0000-0000-000000000111','RECONFIGURE',
    '30000000-0000-0000-0000-000000000111','CLUB','DRIVER','DRIVER','Driver',null,null,'{}',
    '{"loft":9.0,"shaft":"Black"}','PARTIAL',0.8,true,1,true
  ),
  (
    '40000000-0000-0000-0000-000000000111','10000000-0000-0000-0000-000000000111','ADD',
    null,'CLUB','HYBRID','HYBRID-4','4 Hybrid',null,'GAL-BRAND-UNKNOWN','{"brand":"Known Brand","model":"Unknown Hybrid"}',
    '{}','PARTIAL',0.6,true,1,true
  )
$q$, 'GI-BAG-SCN-029 partial product identity is valid inside a what-if scenario');

select is((select configuration->>'shaft' from public.gal_bag_items where bag_item_id='GAL-BI-SCN-DRIVER'),'Blue'::text,
  'GI-BAG-004 scenario editing does not mutate the live bag');

set local role service_role;
do $d$
begin
  begin
    execute $sql$
      insert into public.gal_bag_scenarios (id,scenario_id,user_id,bag_id,name,status,context,fit_model_version,bag_optimization_version,equipment_data_version)
      values ('40000000-0000-0000-0000-000000000211','GAL-SCN-TEST-B','10000000-0000-0000-0000-000000000211','20000000-0000-0000-0000-000000000211','Other golfer','OPEN','{}','FIT-1','BAG-1','EQ-1')
    $sql$;
  exception when undefined_table then
    null;
  end;
end
$d$;

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000111","role":"authenticated"}',true);
select lives_ok($q$
 do $d$ declare v_count bigint; begin
   execute 'select count(*) from public.gal_bag_scenarios' into v_count;
   if v_count <> 1 then raise exception 'expected only own scenario, got %',v_count; end if;
 end $d$
$q$, 'GI-BAG-SCN-031 cross-user scenario is invisible');

set local role service_role;
select lives_ok($q$
  select gal_private.gal_adopt_bag_scenario('40000000-0000-0000-0000-000000000111'::uuid,'BAG-1.1')
$q$, 'GI-BAG-005 trusted adoption transaction succeeds');

select lives_ok($q$
 do $d$ declare v_status text; begin
   execute $$select status from public.gal_bag_scenarios where scenario_id='GAL-SCN-TEST-A'$$ into v_status;
   if v_status is distinct from 'ADOPTED' then raise exception 'expected ADOPTED, got %',v_status; end if;
 end $d$
$q$, 'GI-BAG-SCN-033 adopted scenario is closed as ADOPTED');
select is((select configuration->>'shaft' from public.gal_bag_items where bag_item_id='GAL-BI-SCN-DRIVER'),'Black'::text,
  'GI-BAG-SCN-034 adoption updates the real bag only after explicit adoption');

-- Snapshot evidence of the adoption is verified more deeply in later phase replay tests.

reset role;
select * from finish();
rollback;
