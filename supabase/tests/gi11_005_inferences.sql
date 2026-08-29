-- GI-1.1 Foundation Task 5: inference provenance.
-- TDD contract: system-generated inference rows are golfer-readable, provenance-immutable,
-- and lifecycle confirmation/rejection occurs only through governed invoker endpoints.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(27);

-- Structure and access contract.
select has_table('public', 'gal_inferences', 'GI-INF-001 inference table exists');
select has_column('public', 'gal_inferences', 'inference_id', 'GI-INF-002 public inference ID exists');
select has_column('public', 'gal_inferences', 'inference_key', 'GI-INF-003 canonical inference key exists');
select has_column('public', 'gal_inferences', 'inferred_value', 'GI-INF-004 inferred value exists');
select has_column('public', 'gal_inferences', 'confidence', 'GI-INF-005 confidence exists');
select has_column('public', 'gal_inferences', 'status', 'GI-INF-006 lifecycle status exists');
select has_column('public', 'gal_inferences', 'model_key', 'GI-INF-007 model key exists');
select has_column('public', 'gal_inferences', 'model_version', 'GI-INF-008 model version exists');
select has_column('public', 'gal_inferences', 'evidence_snapshot', 'GI-INF-009 evidence snapshot exists');

select ok(coalesce((
  select c.relrowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_inferences'
), false), 'GI-INF-010 inference table has RLS enabled');

select ok(coalesce((
  select has_table_privilege('authenticated', c.oid, 'SELECT')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_inferences'
), false), 'GI-INF-011 authenticated may read governed inferences');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'INSERT')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_inferences'
), false), 'GI-INF-012 authenticated cannot insert arbitrary inference');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'UPDATE')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_inferences'
), false), 'GI-INF-013 authenticated cannot rewrite inference provenance');

select ok(coalesce((
  select not has_table_privilege('authenticated', c.oid, 'DELETE')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'gal_inferences'
), false), 'GI-INF-014 authenticated cannot delete inference provenance');

select ok(exists(
  select 1
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gal_confirm_inference'
    and pg_get_function_identity_arguments(p.oid) = 'p_inference_id text'
    and not p.prosecdef
), 'GI-INF-015 confirm endpoint exists and remains SECURITY INVOKER');

select ok(exists(
  select 1
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gal_reject_inference'
    and pg_get_function_identity_arguments(p.oid) = 'p_inference_id text'
    and not p.prosecdef
), 'GI-INF-016 reject endpoint exists and remains SECURITY INVOKER');

-- Synthetic users and governed model provenance.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-0000000000c3'::uuid, 'gi11-inf-a@example.test', '{}'::jsonb, '{}'::jsonb),
  ('00000000-0000-0000-0000-0000000000d4'::uuid, 'gi11-inf-b@example.test', '{}'::jsonb, '{}'::jsonb);

insert into public.gal_users (id, gal_user_id, auth_user_id, account_status)
values
  ('10000000-0000-0000-0000-0000000000c3'::uuid, 'GAL-INF-A', '00000000-0000-0000-0000-0000000000c3'::uuid, 'ACTIVE'),
  ('10000000-0000-0000-0000-0000000000d4'::uuid, 'GAL-INF-B', '00000000-0000-0000-0000-0000000000d4'::uuid, 'ACTIVE');

insert into public.gal_model_registry (
  id, model_key, model_version, model_type, category, status, config, change_summary
) values (
  '20000000-0000-0000-0000-000000000501'::uuid,
  'driver_speed_proxy', 'MODEL-1.0', 'INFERENCE', 'DRIVER', 'VALIDATED',
  '{"method":"carry_proxy"}'::jsonb,
  'Synthetic Task 5 model fixture'
);

select lives_ok(
  $$insert into public.gal_inferences (
      id, inference_id, user_id, inference_key, inferred_value, value_state,
      confidence, status, model_key, model_version, evidence_snapshot, explanation,
      scope, privacy_class, commercial_class
    ) values (
      '30000000-0000-0000-0000-000000000501'::uuid,
      'GAL-INF-TEST-501',
      '10000000-0000-0000-0000-0000000000c3'::uuid,
      'swing.driver.speed_mph',
      '{"min":90,"max":96,"unit":"mph"}'::jsonb,
      'INFERRED_ONLY',
      0.82,
      'ACTIVE',
      'driver_speed_proxy',
      'MODEL-1.0',
      '{"driver_carry_yards":235,"source":"golfer_declared"}'::jsonb,
      'Estimated from declared driver carry.',
      'global',
      'aggregate_eligible',
      'aggregate_eligible'
    )$$,
  'GI-INF-017 trusted system can store a governed inference'
);

select results_eq(
  $$select confidence, status, model_version
    from public.gal_inferences
    where inference_id = 'GAL-INF-TEST-501'$$,
  $$values (0.820::numeric, 'ACTIVE'::text, 'MODEL-1.0'::text)$$,
  'GI-INF-018 confidence, status, and model provenance are preserved'
);

select results_eq(
  $$select inferred_value
    from public.gal_inferences
    where inference_id = 'GAL-INF-TEST-501'$$,
  $$values ('{"max": 96, "min": 90, "unit": "mph"}'::jsonb)$$,
  'GI-INF-019 inferred range is stored without fake scalar precision'
);

-- Golfer A may read and confirm own inference.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000c3","role":"authenticated"}',
  true
);

select results_eq(
  $$select count(*)::bigint from public.gal_inferences$$,
  $$values (1::bigint)$$,
  'GI-INF-020 Golfer A reads own inference'
);

select lives_ok(
  $$select public.gal_confirm_inference('GAL-INF-TEST-501')$$,
  'GI-INF-021 golfer can confirm own active inference'
);

select results_eq(
  $$select status, (confirmed_at is not null), evidence_snapshot
    from public.gal_inferences
    where inference_id = 'GAL-INF-TEST-501'$$,
  $$values (
      'CONFIRMED'::text,
      true,
      '{"driver_carry_yards":235,"source":"golfer_declared"}'::jsonb
    )$$,
  'GI-INF-022 confirmation changes lifecycle only and preserves evidence'
);

-- Create a second system inference for rejection behavior.
reset role;
insert into public.gal_inferences (
  id, inference_id, user_id, inference_key, inferred_value, value_state,
  confidence, status, model_key, model_version, evidence_snapshot, explanation,
  scope, privacy_class, commercial_class
) values (
  '30000000-0000-0000-0000-000000000502'::uuid,
  'GAL-INF-TEST-502',
  '10000000-0000-0000-0000-0000000000c3'::uuid,
  'swing.driver.speed_mph',
  '{"min":97,"max":101,"unit":"mph"}'::jsonb,
  'INFERRED_ONLY',
  0.61,
  'CANDIDATE',
  'driver_speed_proxy',
  'MODEL-1.0',
  '{"driver_total_yards":255,"source":"observed"}'::jsonb,
  'Lower-confidence alternative estimate.',
  'global',
  'aggregate_eligible',
  'aggregate_eligible'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000c3","role":"authenticated"}',
  true
);

select lives_ok(
  $$select public.gal_reject_inference('GAL-INF-TEST-502')$$,
  'GI-INF-023 golfer can reject own candidate inference'
);

select results_eq(
  $$select status, (rejected_at is not null), confidence
    from public.gal_inferences
    where inference_id = 'GAL-INF-TEST-502'$$,
  $$values ('REJECTED'::text, true, 0.610::numeric)$$,
  'GI-INF-024 rejection changes lifecycle only and preserves confidence'
);

-- Golfer B cannot see or mutate Golfer A inference.
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000d4","role":"authenticated"}',
  true
);

select results_eq(
  $$select count(*)::bigint from public.gal_inferences$$,
  $$values (0::bigint)$$,
  'GI-INF-025 Golfer B cannot read Golfer A inferences'
);

select throws_ok(
  $$select public.gal_confirm_inference('GAL-INF-TEST-502')$$,
  '42501',
  'GI11_INFERENCE_NOT_OWNED',
  'GI-INF-026 Golfer B cannot confirm Golfer A inference'
);

reset role;

select ok(exists(
  select 1
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname = 'public'
    and t.relname = 'gal_inferences'
    and c.contype = 'c'
    and pg_get_constraintdef(c.oid) ilike '%confidence%'
), 'GI-INF-027 confidence is database-constrained');

select * from finish();
rollback;
