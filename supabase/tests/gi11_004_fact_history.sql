-- GI-1.1 Foundation Task 4: append-only golfer fact history.
-- TDD contract: lifecycle/security assertions are committed before history DDL.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(18);

-- Synthetic auth + canonical GAL users. Test data is transaction-scoped and rolled back.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-0000000000a1'::uuid, 'gi11-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-0000000000b2'::uuid, 'gi11-b@example.test', '{}'::jsonb, '{}'::jsonb);

insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-0000000000a1'::uuid, 'GAL-TEST-A', '00000000-0000-0000-0000-0000000000a1'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-0000000000b2'::uuid, 'GAL-TEST-B', '00000000-0000-0000-0000-0000000000b2'::uuid, 'ACTIVE');

select has_table('public', 'gal_profile_fact_history', 'GI-HIST-001 history table exists');

select ok(exists(
  select 1
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gal_set_profile_fact'
    and pg_get_function_identity_arguments(p.oid) = 'p_fact_key text, p_fact_value jsonb, p_scope text, p_provenance jsonb'
), 'GI-HIST-002 public gal_set_profile_fact contract exists');

select ok(coalesce((
  select not p.prosecdef
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gal_set_profile_fact'
    and pg_get_function_identity_arguments(p.oid) = 'p_fact_key text, p_fact_value jsonb, p_scope text, p_provenance jsonb'
), false), 'GI-HIST-003 public mutation function remains SECURITY INVOKER');

select ok(coalesce((
  select c.relrowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_profile_fact_history'
), false), 'GI-HIST-004 history has RLS enabled');

select ok(coalesce((
  select has_table_privilege('authenticated', c.oid, 'SELECT')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_profile_fact_history'
), false), 'GI-HIST-005 authenticated may read governed history');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'INSERT')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_profile_fact_history'
), false), 'GI-HIST-006 authenticated cannot directly insert history');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'UPDATE')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_profile_fact_history'
), false), 'GI-HIST-007 authenticated cannot rewrite history');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'DELETE')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_profile_fact_history'
), false), 'GI-HIST-008 authenticated cannot delete history');

select ok(exists(
  select 1
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'gal_private'
    and p.proname = 'gal_capture_profile_fact_history'
    and p.prosecdef
), 'GI-HIST-009 private SECURITY DEFINER trigger captures immutable history');

select ok(not exists(
  select 1
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gal_capture_profile_fact_history'
), 'GI-HIST-010 privileged history trigger is not in exposed public schema');

-- Authenticate as Golfer A.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}',
  true
);

select lives_ok(
  $$select public.gal_set_profile_fact(
      'game.handicap_index',
      '14.2'::jsonb,
      'global',
      '{"source":"golfer","source_category":"DECLARED","source_type":"DECLARED","user_confirmed":true}'::jsonb
    )$$,
  'GI-HIST-011 initial current fact can be set through governed function'
);

select lives_ok(
  $$select public.gal_set_profile_fact(
      'game.handicap_index',
      '12.8'::jsonb,
      'global',
      '{"source":"golfer","source_category":"DECLARED","source_type":"DECLARED","user_confirmed":true,"superseded_reason":"measurement_update"}'::jsonb
    )$$,
  'GI-HIST-012 replacing a current fact succeeds atomically'
);

select results_eq(
  $$select (fact_value #>> '{}')::numeric
    from public.gal_profile_facts
    where fact_key = 'game.handicap_index' and scope = 'global'$$,
  $$values (12.8::numeric)$$,
  'GI-HIST-013 current fact is replaced with 12.8'
);

select results_eq(
  $$select (fact_value #>> '{}')::numeric
    from public.gal_profile_fact_history
    where fact_key = 'game.handicap_index' and scope = 'global'
    order by created_at$$,
  $$values (14.2::numeric)$$,
  'GI-HIST-014 prior 14.2 value is preserved in history'
);

select results_eq(
  $$select superseded_reason
    from public.gal_profile_fact_history
    where fact_key = 'game.handicap_index' and scope = 'global'
    order by created_at$$,
  $$values ('measurement_update'::text)$$,
  'GI-HIST-015 supersession reason is preserved'
);

select results_eq(
  $$select count(*)::bigint from public.gal_profile_fact_history$$,
  $$values (1::bigint)$$,
  'GI-HIST-016 Golfer A can read own history'
);

-- Switch JWT identity while keeping authenticated database role.
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}',
  true
);

select results_eq(
  $$select count(*)::bigint from public.gal_profile_fact_history$$,
  $$values (0::bigint)$$,
  'GI-HIST-017 Golfer B cannot read Golfer A history'
);

reset role;

select ok(coalesce((
  select has_function_privilege(
    'authenticated',
    p.oid,
    'EXECUTE'
  )
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gal_set_profile_fact'
    and pg_get_function_identity_arguments(p.oid) = 'p_fact_key text, p_fact_value jsonb, p_scope text, p_provenance jsonb'
), false), 'GI-HIST-018 authenticated can execute only the invoker mutation endpoint');

select * from finish();
rollback;
