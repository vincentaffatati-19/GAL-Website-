-- GI-1.1 Longitudinal Intelligence Task 4: versioned rebuildable intelligence state.
-- gal_intelligence_state is derived/cache data, never historical truth.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(20);

select has_column('public','gal_intelligence_state','state_schema_version','GI-STATE-STRUCT-001 state schema version exists');
select has_column('public','gal_intelligence_state','state_generation_id','GI-STATE-STRUCT-002 state generation id exists');
select has_column('public','gal_intelligence_state','status','GI-STATE-STRUCT-003 state status exists');
select has_column('public','gal_intelligence_state','latest_source_event_at','GI-STATE-STRUCT-004 latest source event timestamp exists');
select has_column('public','gal_intelligence_state','domain_status','GI-STATE-STRUCT-005 domain status exists');

select ok(exists(
  select 1 from pg_constraint c
  join pg_class t on t.oid=c.conrelid
  join pg_namespace n on n.oid=t.relnamespace
  where n.nspname='public' and t.relname='gal_intelligence_state' and c.contype='c'
    and pg_get_constraintdef(c.oid) like '%HEALTHY%'
    and pg_get_constraintdef(c.oid) like '%STALE%'
    and pg_get_constraintdef(c.oid) like '%PARTIAL%'
    and pg_get_constraintdef(c.oid) like '%REBUILDING%'
    and pg_get_constraintdef(c.oid) like '%ERROR%'
), 'GI-STATE-STRUCT-006 status uses governed values');

select ok(exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_intelligence_state'
    and column_name='domain_status' and data_type='jsonb'
), 'GI-STATE-STRUCT-007 domain_status is structured JSON');

select ok(exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_intelligence_state'
    and column_name='state_generation_id' and is_nullable='YES'
), 'GI-STATE-STRUCT-008 generation id is nullable for legacy/unrebuilt rows');

select ok(exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_intelligence_state'
    and column_name='state_schema_version' and is_nullable='YES'
), 'GI-STATE-STRUCT-009 schema version is nullable for legacy/unrebuilt rows');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_intelligence_state'),false),
 'GI-STATE-STRUCT-010 state RLS remains enabled');
select ok(has_table_privilege('authenticated','public.gal_intelligence_state','SELECT'),'GI-STATE-STRUCT-011 golfer may read own derived state');
select ok(not has_table_privilege('authenticated','public.gal_intelligence_state','INSERT'),'GI-STATE-STRUCT-012 golfer cannot insert derived state');
select ok(not has_table_privilege('authenticated','public.gal_intelligence_state','UPDATE'),'GI-STATE-STRUCT-013 golfer cannot rewrite derived state');
select ok(not has_table_privilege('authenticated','public.gal_intelligence_state','DELETE'),'GI-STATE-STRUCT-014 golfer cannot delete derived state');
select ok(has_table_privilege('service_role','public.gal_intelligence_state','SELECT'),'GI-STATE-STRUCT-015 trusted service may read derived state');
select ok(has_table_privilege('service_role','public.gal_intelligence_state','INSERT'),'GI-STATE-STRUCT-016 trusted service may create derived state');
select ok(has_table_privilege('service_role','public.gal_intelligence_state','UPDATE'),'GI-STATE-STRUCT-017 trusted service may rebuild/upsert derived state');
select ok(has_table_privilege('service_role','public.gal_intelligence_state','DELETE'),'GI-STATE-STRUCT-018 trusted service may remove cache state for rebuild/testing');

-- Legacy rows must not be mislabeled GI-STATE-1.1 merely because the schema migration ran.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
values ('32000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','state-legacy@example.test','',now(),'{}','{}',now(),now(),'','','','');
insert into public.gal_users (id,auth_user_id)
values ('33000000-0000-0000-0000-000000000001','32000000-0000-0000-0000-000000000001');
insert into public.gal_intelligence_state (user_id,engine_version,state,event_count)
values ('33000000-0000-0000-0000-000000000001','LEGACY-ENGINE','{}',0);

select ok((select state_schema_version is null from public.gal_intelligence_state where user_id='33000000-0000-0000-0000-000000000001'),
 'GI-STATE-STRUCT-019 legacy state remains unversioned until rebuilt');
select ok((select state_generation_id is null from public.gal_intelligence_state where user_id='33000000-0000-0000-0000-000000000001'),
 'GI-STATE-STRUCT-020 legacy state has no fabricated generation id');

select * from finish();
rollback;
