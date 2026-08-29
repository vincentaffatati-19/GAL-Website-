-- GI-1.1 Foundation Task 6: Question Catalog + response history.
-- TDD contract: questions are versioned/governed, map to canonical facts,
-- support explicit unknown/proxy behavior, and response evidence is append-only.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(44);

-- Question Catalog structure added to the governance-level table.
select has_column('public', 'gal_question_catalog', 'question_text', 'GI-Q-001 question text exists');
select has_column('public', 'gal_question_catalog', 'response_type', 'GI-Q-002 response type exists');
select has_column('public', 'gal_question_catalog', 'primary_fact_key', 'GI-Q-003 primary fact mapping exists');
select has_column('public', 'gal_question_catalog', 'allow_unknown', 'GI-Q-004 explicit unknown handling exists');
select has_column('public', 'gal_question_catalog', 'proxy_group', 'GI-Q-005 proxy group exists');
select has_column('public', 'gal_question_catalog', 'branching_rule', 'GI-Q-006 branching rule exists');
select has_column('public', 'gal_question_catalog', 'commercial_class', 'GI-Q-007 commercial class exists');

-- Response history structure.
select has_table('public', 'gal_question_responses', 'GI-Q-008 response-history table exists');
select has_column('public', 'gal_question_responses', 'response_id', 'GI-Q-009 public response ID exists');
select has_column('public', 'gal_question_responses', 'user_id', 'GI-Q-010 response owner exists');
select has_column('public', 'gal_question_responses', 'question_catalog_id', 'GI-Q-011 exact catalog row reference exists');
select has_column('public', 'gal_question_responses', 'question_key', 'GI-Q-012 question key is preserved');
select has_column('public', 'gal_question_responses', 'question_version', 'GI-Q-013 question version is preserved');
select has_column('public', 'gal_question_responses', 'response_value', 'GI-Q-014 response value exists');
select has_column('public', 'gal_question_responses', 'response_state', 'GI-Q-015 response state exists');
select has_column('public', 'gal_question_responses', 'source_context', 'GI-Q-016 source context exists');
select has_column('public', 'gal_question_responses', 'session_id', 'GI-Q-017 session trace exists');
select has_column('public', 'gal_question_responses', 'resulting_fact_id', 'GI-Q-018 resulting fact trace exists');
select has_column('public', 'gal_question_responses', 'confidence_generated', 'GI-Q-019 generated confidence exists');
select has_column('public', 'gal_question_responses', 'answered_at', 'GI-Q-020 answered timestamp exists');
select has_column('public', 'gal_question_responses', 'superseded_at', 'GI-Q-021 supersession timestamp exists');

select ok(coalesce((
  select c.relrowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_question_responses'
), false), 'GI-Q-022 response history has RLS enabled');

select ok(coalesce((
  select has_table_privilege('authenticated', c.oid, 'SELECT')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_question_responses'
), false), 'GI-Q-023 golfer may read own response history');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'INSERT')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_question_responses'
), false), 'GI-Q-024 golfer cannot insert arbitrary response evidence');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'UPDATE')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_question_responses'
), false), 'GI-Q-025 golfer cannot rewrite response history');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'DELETE')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_question_responses'
), false), 'GI-Q-026 golfer cannot delete response history');

-- QUESTION-1.0 seed vocabulary.
select ok(exists(select 1 from public.gal_question_catalog where question_key='game.handicap_index' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-027 handicap question seeded');
select ok(exists(select 1 from public.gal_question_catalog where question_key='swing.iron_7.carry_yards' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-028 7-iron carry question seeded');
select ok(exists(select 1 from public.gal_question_catalog where question_key='swing.driver.speed_mph' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-029 driver-speed question seeded');
select ok(exists(select 1 from public.gal_question_catalog where question_key='swing.driver.carry_yards' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-030 driver-carry proxy question seeded');
select ok(exists(select 1 from public.gal_question_catalog where question_key='swing.driver.typical_miss' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-031 typical-miss question seeded');
select ok(exists(select 1 from public.gal_question_catalog where question_key='goal.equipment_priority' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-032 performance-priority question seeded');
select ok(exists(select 1 from public.gal_question_catalog where question_key='preference.value.price_sensitivity' and question_version='QUESTION-1.0' and status='ACTIVE'), 'GI-Q-033 price-sensitivity question seeded');

select ok(exists(
  select 1 from public.gal_question_catalog
  where question_key='swing.driver.speed_mph'
    and question_version='QUESTION-1.0'
    and allow_unknown
    and proxy_group='driver_speed_estimation'
    and branching_rule @> '{"when_unknown":{"next_question_key":"swing.driver.carry_yards"}}'::jsonb
), 'GI-Q-034 driver speed unknown declares approved carry proxy');

select ok(exists(
  select 1 from public.gal_question_catalog
  where question_key='swing.driver.carry_yards'
    and question_version='QUESTION-1.0'
    and proxy_group='driver_speed_estimation'
), 'GI-Q-035 driver carry participates in driver-speed proxy group');

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname='public' and t.relname='gal_question_catalog'
    and c.contype='u'
    and pg_get_constraintdef(c.oid) ilike '%question_key%question_version%'
), 'GI-Q-036 question key + version remain unique');

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname='public' and t.relname='gal_question_catalog'
    and c.contype='f'
    and pg_get_constraintdef(c.oid) ilike '%primary_fact_key%gal_fact_catalog%'
), 'GI-Q-037 primary fact mapping is FK-governed');

select ok(coalesce((
  select exists(
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname='public' and t.relname='gal_question_responses'
      and c.contype='f'
      and pg_get_constraintdef(c.oid) ilike '%question_catalog_id%question_key%question_version%gal_question_catalog%'
  )
), false), 'GI-Q-038 response row is bound to exact question version');

-- Synthetic golfer response evidence.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-0000000000e5'::uuid, 'gi11-q-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-0000000000f6'::uuid, 'gi11-q-b@example.test', '{}'::jsonb, '{}'::jsonb);

insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-0000000000e5'::uuid, 'GAL-Q-A', '00000000-0000-0000-0000-0000000000e5'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-0000000000f6'::uuid, 'GAL-Q-B', '00000000-0000-0000-0000-0000000000f6'::uuid, 'ACTIVE');

select lives_ok($q$
  insert into public.gal_question_responses (
    response_id, user_id, question_catalog_id, question_key, question_version,
    response_value, response_state, source_context, session_id, confidence_generated
  )
  select
    'GAL-QR-TEST-601',
    '10000000-0000-0000-0000-0000000000e5'::uuid,
    q.id,
    q.question_key,
    q.question_version,
    '12.4'::jsonb,
    'ANSWERED',
    'IRONS_GUIDE',
    'SESSION-601',
    1.0
  from public.gal_question_catalog q
  where q.question_key='game.handicap_index' and q.question_version='QUESTION-1.0'
$q$, 'GI-Q-039 trusted system can append response evidence');

select ok(coalesce((
  select exists(
    select 1 from public.gal_question_responses r
    where r.response_id='GAL-QR-TEST-601'
      and r.question_key='game.handicap_index'
      and r.question_version='QUESTION-1.0'
      and r.source_context='IRONS_GUIDE'
      and r.session_id='SESSION-601'
  )
), false), 'GI-Q-040 exact question version and source context are preserved');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000e5","role":"authenticated"}', true);

select results_eq(
  $$select count(*)::bigint from public.gal_question_responses$$,
  $$values (1::bigint)$$,
  'GI-Q-041 Golfer A reads own response history'
);

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000f6","role":"authenticated"}', true);

select results_eq(
  $$select count(*)::bigint from public.gal_question_responses$$,
  $$values (0::bigint)$$,
  'GI-Q-042 Golfer B cannot read Golfer A response history'
);

reset role;

select throws_ok($q$
  insert into public.gal_question_responses (
    response_id, user_id, question_catalog_id, question_key, question_version,
    response_value, response_state, source_context
  )
  select
    'GAL-QR-TEST-BADVER',
    '10000000-0000-0000-0000-0000000000e5'::uuid,
    q.id,
    q.question_key,
    'QUESTION-9.9',
    '13.0'::jsonb,
    'ANSWERED',
    'IRONS_GUIDE'
  from public.gal_question_catalog q
  where q.question_key='game.handicap_index' and q.question_version='QUESTION-1.0'
$q$, '23503', null, 'GI-Q-043 mismatched question version is rejected');

select lives_ok($q$
  insert into public.gal_question_responses (
    response_id, user_id, question_catalog_id, question_key, question_version,
    response_value, response_state, source_context
  )
  select
    'GAL-QR-TEST-UNKNOWN',
    '10000000-0000-0000-0000-0000000000e5'::uuid,
    q.id,
    q.question_key,
    q.question_version,
    null,
    'UNKNOWN_DECLARED',
    'DRIVER_GUIDE'
  from public.gal_question_catalog q
  where q.question_key='swing.driver.speed_mph' and q.question_version='QUESTION-1.0'
$q$, 'GI-Q-044 explicit unknown is valid response evidence');

select * from finish();
rollback;
