-- GI-1.1 Longitudinal Intelligence Task 2: extend canonical buyer events.
-- Behavior remains evidence, not truth. This test requires versioned/session-aware append-only events.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(25);

select has_column('public','gal_buyer_events','event_version','GI-BUYER-EVT-001 event_version exists');
select has_column('public','gal_buyer_events','session_id','GI-BUYER-EVT-002 session_id exists');
select has_column('public','gal_buyer_events','journey_id','GI-BUYER-EVT-003 journey_id exists');
select has_column('public','gal_buyer_events','recommendation_run_id','GI-BUYER-EVT-004 recommendation_run_id exists');
select has_column('public','gal_buyer_events','signal_class','GI-BUYER-EVT-005 signal_class exists');
select has_column('public','gal_buyer_events','invalidated_at','GI-BUYER-EVT-006 invalidated_at exists');
select has_column('public','gal_buyer_events','invalidation_reason','GI-BUYER-EVT-007 invalidation_reason exists');

select col_is_not_null('public','gal_buyer_events','event_version','GI-BUYER-EVT-008 event_version is required for governed events');
select col_is_not_null('public','gal_buyer_events','signal_class','GI-BUYER-EVT-009 signal_class is required');

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid=c.conrelid
  join pg_namespace n on n.oid=t.relnamespace
  where n.nspname='public' and t.relname='gal_buyer_events' and c.contype='f'
    and pg_get_constraintdef(c.oid) ilike '%(event_type, event_version)%gal_event_catalog%'
), 'GI-BUYER-EVT-010 event type/version is governed by Event Catalog');

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid=c.conrelid
  join pg_namespace n on n.oid=t.relnamespace
  where n.nspname='public' and t.relname='gal_buyer_events' and c.contype='f'
    and pg_get_constraintdef(c.oid) ilike '%recommendation_run_id%gal_recommendation_runs%'
), 'GI-BUYER-EVT-011 recommendation run linkage is constrained');

select has_index('public','gal_buyer_events','gal_buyer_events_user_session_time_idx','GI-BUYER-EVT-012 session timeline index exists');
select has_index('public','gal_buyer_events','gal_buyer_events_user_journey_time_idx','GI-BUYER-EVT-013 journey timeline index exists');
select has_index('public','gal_buyer_events','gal_buyer_events_recommendation_run_idx','GI-BUYER-EVT-014 recommendation run index exists');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_buyer_events'),false),
 'GI-BUYER-EVT-015 buyer events RLS remains enabled');
select ok(has_table_privilege('authenticated','public.gal_buyer_events','SELECT'),'GI-BUYER-EVT-016 golfer may read own event history');
select ok(has_table_privilege('authenticated','public.gal_buyer_events','INSERT'),'GI-BUYER-EVT-017 golfer may append own governed events');
select ok(not has_table_privilege('authenticated','public.gal_buyer_events','UPDATE'),'GI-BUYER-EVT-018 golfer cannot rewrite event history');
select ok(not has_table_privilege('authenticated','public.gal_buyer_events','DELETE'),'GI-BUYER-EVT-019 golfer cannot delete event history');

select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_buyer_events'
    and cmd='SELECT' and roles::text like '%authenticated%'
), 'GI-BUYER-EVT-020 own-history SELECT policy remains present');
select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_buyer_events'
    and cmd='INSERT' and roles::text like '%authenticated%'
), 'GI-BUYER-EVT-021 own-event INSERT policy remains present');
select ok(not exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_buyer_events'
    and cmd in ('UPDATE','DELETE') and roles::text like '%authenticated%'
), 'GI-BUYER-EVT-022 no golfer UPDATE/DELETE policy exists');

select ok(exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_buyer_events' and column_name='event_type'
), 'GI-BUYER-EVT-023 legacy event_type is preserved');
select ok(exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_buyer_events' and column_name='metadata'
), 'GI-BUYER-EVT-024 existing metadata payload is preserved');
select ok(exists(
  select 1 from information_schema.columns
  where table_schema='public' and table_name='gal_buyer_events' and column_name='occurred_at'
), 'GI-BUYER-EVT-025 existing occurred_at evidence timestamp is preserved');

select * from finish();
rollback;
