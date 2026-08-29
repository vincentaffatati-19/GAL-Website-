-- GI-1.1 Foundation Task 1: governance catalog structure and reference-table security.
-- TDD contract: this test is added before the governance-table migration.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(15);

select has_table('public', 'gal_fact_catalog', 'GI-STRUCT-001 fact catalog exists');
select has_table('public', 'gal_question_catalog', 'GI-STRUCT-002 question catalog exists');
select has_table('public', 'gal_event_catalog', 'GI-STRUCT-003 event catalog exists');
select has_table('public', 'gal_model_registry', 'GI-STRUCT-004 model registry exists');
select has_table('public', 'gal_external_source_catalog', 'GI-STRUCT-005 external source catalog exists');

with catalogs(table_name) as (
  values
    ('gal_fact_catalog'),
    ('gal_question_catalog'),
    ('gal_event_catalog'),
    ('gal_model_registry'),
    ('gal_external_source_catalog')
)
select ok(
  coalesce((
    select c.relrowsecurity
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = catalogs.table_name
  ), false),
  'GI-RLS-REF RLS enabled on ' || table_name
)
from catalogs;

with catalogs(table_name) as (
  values
    ('gal_fact_catalog'),
    ('gal_question_catalog'),
    ('gal_event_catalog'),
    ('gal_model_registry'),
    ('gal_external_source_catalog')
)
select ok(
  coalesce((
    select
      not has_table_privilege('authenticated', c.oid, 'INSERT')
      and not has_table_privilege('authenticated', c.oid, 'UPDATE')
      and not has_table_privilege('authenticated', c.oid, 'DELETE')
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = catalogs.table_name
  ), false),
  'GI-REF-WRITE authenticated cannot directly write ' || table_name
)
from catalogs;

select * from finish();
rollback;
