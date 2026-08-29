-- GI-1.1 backend readiness regression tests.
-- Run only in local/development/staging test databases.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(5);

select ok(
  (
    select p.proconfig is not null
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'gal_parse_set_club_count'
      and pg_get_function_identity_arguments(p.oid) = 'p_set text'
  ),
  'GI-SEC-001 gal_parse_set_club_count has a fixed function search_path'
);

select ok(
  not has_function_privilege(
    'authenticated',
    'public.gal_add_to_my_bag(jsonb)',
    'EXECUTE'
  ),
  'GI-SEC-002 authenticated cannot directly execute SECURITY DEFINER gal_add_to_my_bag'
);

select ok(
  not has_table_privilege(
    'authenticated',
    'public.gal_consent_records',
    'UPDATE'
  ),
  'GI-RLS-006 authenticated cannot rewrite consent history'
);

select ok(
  not has_table_privilege(
    'authenticated',
    'public.gal_consent_records',
    'DELETE'
  ),
  'GI-RLS-006 authenticated cannot delete consent history'
);

select ok(
  to_regprocedure('public.gal_v64320_import(text,text,jsonb)') is null,
  'GI-SEC-003 obsolete temporary import RPC is removed'
);

select * from finish();
rollback;
