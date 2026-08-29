-- GI-1.1 Foundation Task 1: governance catalog structure.
-- TDD contract: this test is added before the governance-table migration.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(5);

select has_table('public', 'gal_fact_catalog', 'GI-STRUCT-001 fact catalog exists');
select has_table('public', 'gal_question_catalog', 'GI-STRUCT-002 question catalog exists');
select has_table('public', 'gal_event_catalog', 'GI-STRUCT-003 event catalog exists');
select has_table('public', 'gal_model_registry', 'GI-STRUCT-004 model registry exists');
select has_table('public', 'gal_external_source_catalog', 'GI-STRUCT-005 external source catalog exists');

select * from finish();
rollback;
