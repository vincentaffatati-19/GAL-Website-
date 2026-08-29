-- GI-1.1 Foundation Task 7: append-only consent governance.
-- TDD contract: preserve existing consent values, add GI-1.1 consent classes/metadata,
-- allow golfers to read + append their own history, and deny mutation/deletion of prior rows.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(27);

-- Keep the final metadata assertion parser-safe while the columns are intentionally absent in RED.
create or replace function pg_temp.gi11_consent_metadata_matches(p_consent_id text)
returns boolean
language plpgsql
as $$
declare
  v_match boolean;
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_consent_records' and column_name='interface'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_consent_records' and column_name='jurisdiction'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='gal_consent_records' and column_name='metadata'
  ) then
    return false;
  end if;

  execute $sql$
    select exists(
      select 1 from public.gal_consent_records
      where consent_id=$1
        and interface='web'
        and jurisdiction='US-SD'
        and metadata @> '{"surface":"onboarding"}'::jsonb
    )
  $sql$ into v_match using p_consent_id;

  return coalesce(v_match, false);
end;
$$;

-- Additive metadata required by the approved GI-1.1 design.
select has_column('public', 'gal_consent_records', 'interface', 'GI-CNS-001 consent interface metadata exists');
select has_column('public', 'gal_consent_records', 'jurisdiction', 'GI-CNS-002 consent jurisdiction metadata exists');
select has_column('public', 'gal_consent_records', 'metadata', 'GI-CNS-003 consent structured metadata exists');

-- Additive consent types: existing values remain valid while GI-1.1 adds finer-grained permissions.
select ok(exists(
  select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname='gal_consent_type' and e.enumlabel='PERSONALIZATION'
), 'GI-CNS-004 PERSONALIZATION consent type exists');
select ok(exists(
  select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname='gal_consent_type' and e.enumlabel='PRODUCT_ANALYTICS'
), 'GI-CNS-005 PRODUCT_ANALYTICS consent type exists');
select ok(exists(
  select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname='gal_consent_type' and e.enumlabel='COMMERCIAL_AGGREGATE_ANALYTICS'
), 'GI-CNS-006 COMMERCIAL_AGGREGATE_ANALYTICS consent type exists');
select ok(exists(
  select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname='gal_consent_type' and e.enumlabel='RESEARCH_PARTICIPATION'
), 'GI-CNS-007 RESEARCH_PARTICIPATION consent type exists');
select ok(exists(
  select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname='gal_consent_type' and e.enumlabel='DATA_IMPORT'
), 'GI-CNS-008 DATA_IMPORT consent type exists');
select ok(exists(
  select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public' and t.typname='gal_consent_type' and e.enumlabel='TERMS'
), 'GI-CNS-009 existing TERMS consent type is preserved');

-- Access contract. Backend readiness already removed broad self-ALL; Task 7 makes this permanent and explicit.
select ok(coalesce((
  select c.relrowsecurity
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='gal_consent_records'
), false), 'GI-CNS-010 consent table has RLS enabled');
select ok(has_table_privilege('authenticated', 'public.gal_consent_records', 'SELECT'), 'GI-CNS-011 authenticated can SELECT consent history');
select ok(has_table_privilege('authenticated', 'public.gal_consent_records', 'INSERT'), 'GI-CNS-012 authenticated can append consent history');
select ok(not has_table_privilege('authenticated', 'public.gal_consent_records', 'UPDATE'), 'GI-CNS-013 authenticated cannot UPDATE consent history');
select ok(not has_table_privilege('authenticated', 'public.gal_consent_records', 'DELETE'), 'GI-CNS-014 authenticated cannot DELETE consent history');
select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_consent_records'
    and policyname='gal_consent_self_select' and cmd='SELECT' and roles @> array['authenticated']::name[]
), 'GI-CNS-015 explicit own SELECT policy exists');
select ok(exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_consent_records'
    and policyname='gal_consent_self_insert' and cmd='INSERT' and roles @> array['authenticated']::name[]
), 'GI-CNS-016 explicit own INSERT policy exists');
select ok(not exists(
  select 1 from pg_policies
  where schemaname='public' and tablename='gal_consent_records'
    and cmd in ('UPDATE','DELETE') and roles @> array['authenticated']::name[]
), 'GI-CNS-017 no authenticated UPDATE/DELETE consent policy exists');

-- Synthetic golfers and initial immutable consent evidence.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-000000000107'::uuid, 'gi11-consent-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-000000000207'::uuid, 'gi11-consent-b@example.test', '{}'::jsonb, '{}'::jsonb);

insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-000000000107'::uuid, 'GAL-CNS-A', '00000000-0000-0000-0000-000000000107'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-000000000207'::uuid, 'GAL-CNS-B', '00000000-0000-0000-0000-000000000207'::uuid, 'ACTIVE');

insert into public.gal_consent_records (
  consent_id, user_id, consent_type, status, policy_version, source
) values
  ('GAL-CNS-TEST-A1', '10000000-0000-0000-0000-000000000107'::uuid, 'TERMS', 'ACCEPTED', 'TERMS-1.0', 'TEST'),
  ('GAL-CNS-TEST-B1', '10000000-0000-0000-0000-000000000207'::uuid, 'TERMS', 'ACCEPTED', 'TERMS-1.0', 'TEST');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000107","role":"authenticated"}', true);

select results_eq(
  $$select count(*)::bigint from public.gal_consent_records$$,
  $$values (1::bigint)$$,
  'GI-CNS-018 Golfer A reads only own consent history'
);

select is(
  (select count(*)::bigint from public.gal_consent_records where consent_id='GAL-CNS-TEST-B1'),
  0::bigint,
  'GI-CNS-019 Golfer B consent is hidden from Golfer A'
);

select lives_ok($q$
  insert into public.gal_consent_records (
    consent_id, user_id, consent_type, status, policy_version, source,
    interface, jurisdiction, metadata
  ) values (
    'GAL-CNS-TEST-A2',
    '10000000-0000-0000-0000-000000000107'::uuid,
    'TERMS',
    'WITHDRAWN',
    'TERMS-1.0',
    'PROFILE_PRIVACY',
    'web',
    'US-SD',
    '{"reason":"user_choice"}'::jsonb
  )
$q$, 'GI-CNS-020 Golfer A can append a withdrawal record');

select results_eq(
  $$select count(*)::bigint from public.gal_consent_records$$,
  $$values (2::bigint)$$,
  'GI-CNS-021 withdrawal appends history rather than replacing it'
);

select ok(exists(
  select 1 from public.gal_consent_records
  where consent_id='GAL-CNS-TEST-A1' and status='ACCEPTED'
), 'GI-CNS-022 original accepted consent remains unchanged');

select throws_ok(
  $$update public.gal_consent_records set status='DECLINED' where consent_id='GAL-CNS-TEST-A1'$$,
  '42501', null,
  'GI-CNS-023 authenticated cannot rewrite an earlier own consent row'
);

select throws_ok(
  $$delete from public.gal_consent_records where consent_id='GAL-CNS-TEST-A1'$$,
  '42501', null,
  'GI-CNS-024 authenticated cannot delete an earlier own consent row'
);

select throws_ok($q$
  insert into public.gal_consent_records (
    consent_id, user_id, consent_type, status, policy_version, source,
    interface, jurisdiction, metadata
  ) values (
    'GAL-CNS-TEST-CROSS',
    '10000000-0000-0000-0000-000000000207'::uuid,
    'TERMS',
    'WITHDRAWN',
    'TERMS-1.0',
    'PROFILE_PRIVACY',
    'web',
    'US-SD',
    '{}'::jsonb
  )
$q$, '42501', null, 'GI-CNS-025 Golfer A cannot append consent for Golfer B');

reset role;

select lives_ok($q$
  insert into public.gal_consent_records (
    consent_id, user_id, consent_type, status, policy_version, source,
    interface, jurisdiction, metadata
  ) values (
    'GAL-CNS-TEST-PERSONALIZATION',
    '10000000-0000-0000-0000-000000000107'::uuid,
    'PERSONALIZATION',
    'ACCEPTED',
    'PERSONALIZATION-1.0',
    'ONBOARDING',
    'web',
    'US-SD',
    '{"surface":"onboarding"}'::jsonb
  )
$q$, 'GI-CNS-026 trusted path can record new GI-1.1 consent type');

select ok(
  pg_temp.gi11_consent_metadata_matches('GAL-CNS-TEST-PERSONALIZATION'),
  'GI-CNS-027 consent provenance metadata is preserved'
);

select * from finish();
rollback;
