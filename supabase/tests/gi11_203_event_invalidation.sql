-- GI-1.1 Longitudinal Intelligence Task 3: governed buyer-event invalidation.
-- Invalidation records error state without rewriting original event semantics.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(14);

select has_function('public','gal_invalidate_buyer_event',array['text','text'],'GI-EVT-INV-001 invalidation function exists');

select ok(coalesce(not has_function_privilege('anon',to_regprocedure('public.gal_invalidate_buyer_event(text,text)'),'EXECUTE'),true),
 'GI-EVT-INV-002 anon cannot invalidate events');
select ok(coalesce(not has_function_privilege('authenticated',to_regprocedure('public.gal_invalidate_buyer_event(text,text)'),'EXECUTE'),true),
 'GI-EVT-INV-003 normal golfer cannot invalidate events directly');
select ok(coalesce(has_function_privilege('service_role',to_regprocedure('public.gal_invalidate_buyer_event(text,text)'),'EXECUTE'),false),
 'GI-EVT-INV-004 trusted service may invalidate events');

with au as (
  insert into auth.users(id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  values ('20300000-0000-0000-0000-000000000001'::uuid,'authenticated','authenticated','gi203@example.invalid','',now(),'{}'::jsonb,'{}'::jsonb,now(),now())
  returning id
), gu as (
  insert into public.gal_users(id,auth_user_id)
  values ('20310000-0000-0000-0000-000000000001'::uuid,(select id from au))
  returning id
)
insert into public.gal_buyer_events(
  event_id,user_id,event_type,event_version,signal_class,category,canonical_product_id,product_name,metadata,source_tool,source_tool_version,occurred_at
)
values (
  'EVT-GI203-1',(select id from gu),'product.viewed','EVENT-1.0','ENGAGEMENT','DRIVER','TEST-DRIVER-1','Test Driver','{"placement":"guide"}'::jsonb,'test','1.0','2026-08-29T20:00:00Z'::timestamptz
);

create temp table gi203_before as
select event_type,event_version,signal_class,category,canonical_product_id,product_name,metadata,source_tool,source_tool_version,occurred_at
from public.gal_buyer_events where event_id='EVT-GI203-1';

select lives_ok(
  $$ select public.gal_invalidate_buyer_event('EVT-GI203-1','duplicate client telemetry') $$,
  'GI-EVT-INV-005 trusted invalidation call succeeds'
);

select ok((select invalidated_at is not null from public.gal_buyer_events where event_id='EVT-GI203-1'),
 'GI-EVT-INV-006 invalidated_at is populated');
select is((select invalidation_reason from public.gal_buyer_events where event_id='EVT-GI203-1'),'duplicate client telemetry',
 'GI-EVT-INV-007 invalidation reason is recorded');
select is((select event_type from public.gal_buyer_events where event_id='EVT-GI203-1'),(select event_type from gi203_before),
 'GI-EVT-INV-008 event type remains unchanged');
select is((select canonical_product_id from public.gal_buyer_events where event_id='EVT-GI203-1'),(select canonical_product_id from gi203_before),
 'GI-EVT-INV-009 product remains unchanged');
select is((select occurred_at from public.gal_buyer_events where event_id='EVT-GI203-1'),(select occurred_at from gi203_before),
 'GI-EVT-INV-010 occurred_at remains unchanged');
select is((select metadata from public.gal_buyer_events where event_id='EVT-GI203-1'),(select metadata from gi203_before),
 'GI-EVT-INV-011 metadata remains unchanged');

select throws_ok(
  $$ select public.gal_invalidate_buyer_event('EVT-GI203-1','') $$,
  '22023',
  'invalidation reason is required',
  'GI-EVT-INV-012 blank invalidation reason is rejected'
);

select throws_ok(
  $$ select public.gal_invalidate_buyer_event('EVT-GI203-MISSING','duplicate client telemetry') $$,
  'P0002',
  'buyer event not found',
  'GI-EVT-INV-013 unknown event is rejected'
);

select ok(not has_table_privilege('authenticated','public.gal_buyer_events','UPDATE'),
 'GI-EVT-INV-014 golfer still cannot update buyer events directly');

select * from finish();
rollback;
