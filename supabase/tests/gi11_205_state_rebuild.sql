-- GI-1.1 Longitudinal Intelligence Task 6: trusted state persistence/rebuild contract.
-- Durable facts/events remain source-of-truth; gal_intelligence_state is a replaceable cache.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(21);

select has_function(
  'public',
  'gal_persist_intelligence_state',
  array['uuid','jsonb'],
  'GI-STATE-REBUILD-001 trusted persistence function exists'
);

select ok(coalesce((
  select not p.prosecdef
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname='public'
    and p.proname='gal_persist_intelligence_state'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_payload jsonb'
), false), 'GI-STATE-REBUILD-002 persistence function is SECURITY INVOKER');

select ok(coalesce(not has_function_privilege('anon',to_regprocedure('public.gal_persist_intelligence_state(uuid,jsonb)'),'EXECUTE'),true),
  'GI-STATE-REBUILD-003 anon cannot persist intelligence state');
select ok(coalesce(not has_function_privilege('authenticated',to_regprocedure('public.gal_persist_intelligence_state(uuid,jsonb)'),'EXECUTE'),true),
  'GI-STATE-REBUILD-004 golfer cannot persist intelligence state directly');
select ok(coalesce(has_function_privilege('service_role',to_regprocedure('public.gal_persist_intelligence_state(uuid,jsonb)'),'EXECUTE'),false),
  'GI-STATE-REBUILD-005 trusted service may persist intelligence state');

with au as (
  insert into auth.users(id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  values ('20500000-0000-0000-0000-000000000001'::uuid,'authenticated','authenticated','gi205@example.invalid','',now(),'{}'::jsonb,'{}'::jsonb,now(),now())
  returning id
), gu as (
  insert into public.gal_users(id,auth_user_id)
  values ('20510000-0000-0000-0000-000000000001'::uuid,(select id from au))
  returning id
)
insert into public.gal_profile_facts(
  id,user_id,fact_key,fact_value,source,source_type,source_detail,confidence,user_confirmed,scope,effective_at,observed_at
)
values (
  '20520000-0000-0000-0000-000000000001'::uuid,
  (select id from gu),
  'game.handicap_index',
  '10.9'::jsonb,
  'verified_handicap_import',
  'IMPORTED',
  '{"verified":true}'::jsonb,
  0.990,
  false,
  'global',
  '2026-08-20T12:00:00Z'::timestamptz,
  '2026-08-20T12:00:00Z'::timestamptz
);

create temp table gi205_source_before as
select fact_value,source,source_type,source_detail,confidence,user_confirmed,effective_at,observed_at
from public.gal_profile_facts
where id='20520000-0000-0000-0000-000000000001'::uuid;

select lives_ok(
  $$
    select public.gal_persist_intelligence_state(
      '20510000-0000-0000-0000-000000000001'::uuid,
      '{
        "stateGenerationId":"GI-GEN-205-A",
        "status":"HEALTHY",
        "state":{"stateSchemaVersion":"GI-STATE-1.1","status":"HEALTHY","domains":{"game":{"facts":{"game.handicap_index":{"resolution":"RESOLVED","value":10.9,"valueState":"KNOWN"}}}}},
        "domainStatus":{"game":{"status":"HEALTHY","resolved":1,"inferred":0,"unknown":0,"conflicts":0}},
        "eventCount":2,
        "latestSourceEventAt":"2026-08-28T15:00:00Z"
      }'::jsonb
    )
  $$,
  'GI-STATE-REBUILD-006 trusted persistence call succeeds'
);

select is((select count(*) from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),1::bigint,
  'GI-STATE-REBUILD-007 rebuild creates exactly one cache row');
select is((select state_schema_version from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'GI-STATE-1.1',
  'GI-STATE-REBUILD-008 persisted row is explicitly GI-STATE-1.1');
select is((select engine_version from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'GI-STATE-BUILDER-1.0',
  'GI-STATE-REBUILD-009 deterministic engine version is persisted');
select is((select state_generation_id from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'GI-GEN-205-A',
  'GI-STATE-REBUILD-010 generation id is persisted');
select is((select status from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'HEALTHY',
  'GI-STATE-REBUILD-011 state health is persisted');
select is((select state #>> '{domains,game,facts,game.handicap_index,value}' from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'10.9',
  'GI-STATE-REBUILD-012 semantic state JSON is preserved');
select is((select domain_status #>> '{game,status}' from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'HEALTHY',
  'GI-STATE-REBUILD-013 domain status is persisted');
select is((select event_count from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),2::bigint,
  'GI-STATE-REBUILD-014 valid event count is persisted');
select is((select latest_event_at from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'2026-08-28T15:00:00Z'::timestamptz,
  'GI-STATE-REBUILD-015 legacy latest_event_at remains aligned with valid source event');
select is((select latest_source_event_at from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'2026-08-28T15:00:00Z'::timestamptz,
  'GI-STATE-REBUILD-016 latest source event timestamp is persisted');

select is(
  (select to_jsonb(x) from (
    select fact_value,source,source_type,source_detail,confidence,user_confirmed,effective_at,observed_at
    from public.gal_profile_facts
    where id='20520000-0000-0000-0000-000000000001'::uuid
  ) x),
  (select to_jsonb(x) from gi205_source_before x),
  'GI-STATE-REBUILD-017 persisting derived state leaves durable profile fact untouched'
);

select lives_ok(
  $$
    select public.gal_persist_intelligence_state(
      '20510000-0000-0000-0000-000000000001'::uuid,
      '{
        "stateGenerationId":"GI-GEN-205-B",
        "status":"PARTIAL",
        "state":{"stateSchemaVersion":"GI-STATE-1.1","status":"PARTIAL","domains":{"game":{"facts":{"game.handicap_index":{"resolution":"RESOLVED","value":10.9,"valueState":"KNOWN"}}}},"dependencyStatus":{"bag":{"status":"MISSING"}}},
        "domainStatus":{"game":{"status":"HEALTHY","resolved":1,"inferred":0,"unknown":0,"conflicts":0}},
        "eventCount":2,
        "latestSourceEventAt":"2026-08-28T15:00:00Z"
      }'::jsonb
    )
  $$,
  'GI-STATE-REBUILD-018 subsequent rebuild upsert succeeds'
);

select is((select count(*) from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),1::bigint,
  'GI-STATE-REBUILD-019 rebuild replaces cache rather than appending competing current state');
select is((select state_generation_id from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'GI-GEN-205-B',
  'GI-STATE-REBUILD-020 subsequent rebuild advances generation id');
select is((select status from public.gal_intelligence_state where user_id='20510000-0000-0000-0000-000000000001'::uuid),'PARTIAL',
  'GI-STATE-REBUILD-021 partial rebuild status can replace prior cache health');

select * from finish();
rollback;
