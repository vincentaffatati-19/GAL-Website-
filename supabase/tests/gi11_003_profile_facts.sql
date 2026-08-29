-- GI-1.1 Foundation Task 3: additive gal_profile_facts extension.
-- TDD contract: these assertions precede the profile-fact extension migration.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(16);

select has_column('public', 'gal_profile_facts', 'value_state', 'GI-PF-001 value_state exists');
select has_column('public', 'gal_profile_facts', 'unit', 'GI-PF-002 unit exists');
select has_column('public', 'gal_profile_facts', 'source_type', 'GI-PF-003 source_type exists');
select has_column('public', 'gal_profile_facts', 'source_detail', 'GI-PF-004 source_detail exists');
select has_column('public', 'gal_profile_facts', 'fact_catalog_version', 'GI-PF-005 fact_catalog_version exists');
select has_column('public', 'gal_profile_facts', 'effective_at', 'GI-PF-006 effective_at exists');
select has_column('public', 'gal_profile_facts', 'last_confirmed_at', 'GI-PF-007 last_confirmed_at exists');
select has_column('public', 'gal_profile_facts', 'model_version', 'GI-PF-008 model_version exists');
select has_column('public', 'gal_profile_facts', 'question_version', 'GI-PF-009 question_version exists');
select has_column('public', 'gal_profile_facts', 'privacy_class', 'GI-PF-010 privacy_class exists');
select has_column('public', 'gal_profile_facts', 'commercial_class', 'GI-PF-011 commercial_class exists');
select has_column('public', 'gal_profile_facts', 'data_source_id', 'GI-PF-012 data_source_id exists');

select has_column('public', 'gal_profile_facts', 'source', 'GI-PF-013 legacy source column is preserved');
select has_column('public', 'gal_profile_facts', 'source_category', 'GI-PF-014 legacy source_category column is preserved');

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  join pg_class rt on rt.oid = c.confrelid
  join pg_namespace rn on rn.oid = rt.relnamespace
  where n.nspname = 'public'
    and t.relname = 'gal_profile_facts'
    and c.contype = 'f'
    and rn.nspname = 'public'
    and rt.relname = 'gal_fact_catalog'
    and pg_get_constraintdef(c.oid) like 'FOREIGN KEY (fact_key)%'
), 'GI-PF-015 fact_key is governed by gal_fact_catalog');

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname = 'public'
    and t.relname = 'gal_profile_facts'
    and c.contype = 'u'
    and pg_get_constraintdef(c.oid) = 'UNIQUE (user_id, fact_key, scope)'
), 'GI-PF-016 existing user/fact/scope uniqueness is preserved');

select * from finish();
rollback;
