-- GI-1.1 Longitudinal Intelligence Task 4 — RED contract
-- Rebuildable current intelligence cache with explicit version/generation/health metadata.

begin;
create extension if not exists pgtap;
select plan(20);

select has_column('public', 'gal_intelligence_state', 'state_schema_version', 'GI-STATE-001 state_schema_version exists');
select has_column('public', 'gal_intelligence_state', 'state_generation_id', 'GI-STATE-002 state_generation_id exists');
select has_column('public', 'gal_intelligence_state', 'status', 'GI-STATE-003 status exists');
select has_column('public', 'gal_intelligence_state', 'latest_source_event_at', 'GI-STATE-004 latest_source_event_at exists');
select has_column('public', 'gal_intelligence_state', 'domain_status', 'GI-STATE-005 domain_status exists');

select col_not_null('public', 'gal_intelligence_state', 'state_schema_version', 'GI-STATE-006 schema version is required');
select col_not_null('public', 'gal_intelligence_state', 'state_generation_id', 'GI-STATE-007 generation id is required');
select col_not_null('public', 'gal_intelligence_state', 'status', 'GI-STATE-008 status is required');
select col_not_null('public', 'gal_intelligence_state', 'domain_status', 'GI-STATE-009 domain status is required');

select ok(
  not has_table_privilege('authenticated', 'public.gal_intelligence_state', 'INSERT'),
  'GI-STATE-010 authenticated cannot insert intelligence state'
);
select ok(
  not has_table_privilege('authenticated', 'public.gal_intelligence_state', 'UPDATE'),
  'GI-STATE-011 authenticated cannot update intelligence state'
);
select ok(
  has_table_privilege('service_role', 'public.gal_intelligence_state', 'INSERT'),
  'GI-STATE-012 service role may insert intelligence state'
);
select ok(
  has_table_privilege('service_role', 'public.gal_intelligence_state', 'UPDATE'),
  'GI-STATE-013 service role may update intelligence state'
);

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
  status,
  latest_source_event_at,
  domain_status
) values (
  '10000000-0000-0000-0000-000000020401',
  'ENGINE-1.0',
  '{"profile":{"confidence":0.91}}'::jsonb,
  12,
  '2026-08-29T20:00:00Z',
  'STATE-1.0',
  'READY',
  '2026-08-29T20:05:00Z',
  '{"profile":"READY","bag":"READY","behavior":"STALE"}'::jsonb
);
reset role;

select ok(
  (select state_generation_id is not null from public.gal_intelligence_state where user_id = '10000000-0000-0000-0000-000000020401'),
  'GI-STATE-014 service write receives a generation id'
);
select is(
  (select state_schema_version from public.gal_intelligence_state where user_id = '10000000-0000-0000-0000-000000020401'),
  'STATE-1.0',
  'GI-STATE-015 schema version is preserved'
);
select is(
  (select status from public.gal_intelligence_state where user_id = '10000000-0000-0000-0000-000000020401'),
  'READY',
  'GI-STATE-016 health status is preserved'
);
select is(
  (select domain_status->>'behavior' from public.gal_intelligence_state where user_id = '10000000-0000-0000-0000-000000020401'),
  'STALE',
  'GI-STATE-017 domain health metadata is preserved'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000020401', true);
select is(
  (select count(*)::bigint from public.gal_intelligence_state),
  1::bigint,
  'GI-STATE-018 golfer reads own intelligence state'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000020402', true);
select is(
  (select count(*)::bigint from public.gal_intelligence_state),
  0::bigint,
  'GI-STATE-019 golfer cannot read another golfer intelligence state'
);
reset role;

select throws_ok(
  $$insert into public.gal_intelligence_state (
      user_id, engine_version, state_schema_version, status, domain_status
    ) values (
      '10000000-0000-0000-0000-000000020402', 'ENGINE-1.0', 'STATE-1.0', 'NOT_A_STATUS', '{}'::jsonb
    )$$,
  '23514',
  null,
  'GI-STATE-020 status vocabulary is database constrained'
);

select * from finish();
rollback;
