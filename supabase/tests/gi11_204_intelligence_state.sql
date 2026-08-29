-- GI-1.1 Longitudinal Intelligence Task 4 — compatibility contract
-- Complements gi11_204_state_structure.sql without relabeling legacy/unrebuilt rows.

begin;
create extension if not exists pgtap;
select plan(14);

select has_column('public', 'gal_intelligence_state', 'state_schema_version', 'GI-STATE-COMPAT-001 state_schema_version exists');
select has_column('public', 'gal_intelligence_state', 'state_generation_id', 'GI-STATE-COMPAT-002 state_generation_id exists');
select has_column('public', 'gal_intelligence_state', 'status', 'GI-STATE-COMPAT-003 status exists');
select has_column('public', 'gal_intelligence_state', 'latest_source_event_at', 'GI-STATE-COMPAT-004 latest_source_event_at exists');
select has_column('public', 'gal_intelligence_state', 'domain_status', 'GI-STATE-COMPAT-005 domain_status exists');

select ok(not has_table_privilege('authenticated', 'public.gal_intelligence_state', 'INSERT'), 'GI-STATE-COMPAT-006 golfer cannot insert derived state');
select ok(not has_table_privilege('authenticated', 'public.gal_intelligence_state', 'UPDATE'), 'GI-STATE-COMPAT-007 golfer cannot update derived state');
select ok(has_table_privilege('service_role', 'public.gal_intelligence_state', 'INSERT'), 'GI-STATE-COMPAT-008 service role may insert derived state');
select ok(has_table_privilege('service_role', 'public.gal_intelligence_state', 'UPDATE'), 'GI-STATE-COMPAT-009 service role may update derived state');

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000020401', 'state-a@example.invalid'),
  ('00000000-0000-0000-0000-000000020402', 'state-b@example.invalid');

insert into public.gal_users (id, auth_user_id)
values
  ('10000000-0000-0000-0000-000000020401', '00000000-0000-0000-0000-000000020401'),
  ('10000000-0000-0000-0000-000000020402', '00000000-0000-0000-0000-000000020402');

set local role service_role;
insert into public.gal_intelligence_state (
  user_id,
  engine_version,
  state,
  event_count,
  latest_event_at,
  state_schema_version,
  state_generation_id,
  status,
  latest_source_event_at,
  domain_status
) values (
  '10000000-0000-0000-0000-000000020401',
  'GI-STATE-BUILDER-1.0',
  '{"stateSchemaVersion":"GI-STATE-1.1","profile":{"confidence":0.91}}'::jsonb,
  12,
  '2026-08-29T20:00:00Z',
  'GI-STATE-1.1',
  '24000000-0000-0000-0000-000000020401',
  'HEALTHY',
  '2026-08-29T20:05:00Z',
  '{"profile":"HEALTHY","bag":"HEALTHY","behavior":"STALE"}'::jsonb
);
reset role;

select is((select state_schema_version from public.gal_intelligence_state where user_id='10000000-0000-0000-0000-000000020401'), 'GI-STATE-1.1', 'GI-STATE-COMPAT-010 rebuilt row records state schema version');
select is((select status from public.gal_intelligence_state where user_id='10000000-0000-0000-0000-000000020401'), 'HEALTHY', 'GI-STATE-COMPAT-011 governed health status is preserved');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000020401', true);
select is((select count(*)::bigint from public.gal_intelligence_state), 1::bigint, 'GI-STATE-COMPAT-012 golfer reads own intelligence state');
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000020402', true);
select is((select count(*)::bigint from public.gal_intelligence_state), 0::bigint, 'GI-STATE-COMPAT-013 golfer cannot read another golfer intelligence state');
reset role;

select throws_ok(
  $$insert into public.gal_intelligence_state (
      user_id, engine_version, state_schema_version, state_generation_id, status, domain_status
    ) values (
      '10000000-0000-0000-0000-000000020402', 'GI-STATE-BUILDER-1.0', 'GI-STATE-1.1',
      '24000000-0000-0000-0000-000000020402', 'NOT_A_STATUS', '{}'::jsonb
    )$$,
  '23514',
  null,
  'GI-STATE-COMPAT-014 status vocabulary is database constrained'
);

select * from finish();
rollback;
