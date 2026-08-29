-- GI-1.1 Longitudinal Intelligence Task 7 — RED contract
-- Milestone snapshots are immutable evidence; current state remains rebuildable cache.

begin;
create extension if not exists pgtap;
select plan(25);

create or replace function pg_temp.gi11_table_priv(p_role text, p_priv text)
returns boolean
language plpgsql
as $$
begin
  if to_regclass('public.gal_intelligence_snapshots') is null then return false; end if;
  return has_table_privilege(p_role, 'public.gal_intelligence_snapshots', p_priv);
end;
$$;

create or replace function pg_temp.gi11_rls_enabled()
returns boolean
language sql
as $$
  select coalesce((
    select c.relrowsecurity
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='gal_intelligence_snapshots'
  ), false);
$$;

select has_table('public', 'gal_intelligence_snapshots', 'GI-SNAP-001 intelligence snapshots table exists');
select has_column('public', 'gal_intelligence_snapshots', 'intelligence_snapshot_id', 'GI-SNAP-002 public snapshot id exists');
select has_column('public', 'gal_intelligence_snapshots', 'user_id', 'GI-SNAP-003 user id exists');
select has_column('public', 'gal_intelligence_snapshots', 'state_generation_id', 'GI-SNAP-004 state generation id exists');
select has_column('public', 'gal_intelligence_snapshots', 'engine_version', 'GI-SNAP-005 engine version exists');
select has_column('public', 'gal_intelligence_snapshots', 'state_schema_version', 'GI-SNAP-006 state schema version exists');
select has_column('public', 'gal_intelligence_snapshots', 'state', 'GI-SNAP-007 state document exists');
select has_column('public', 'gal_intelligence_snapshots', 'domain_status', 'GI-SNAP-008 domain status exists');
select has_column('public', 'gal_intelligence_snapshots', 'trigger_type', 'GI-SNAP-009 trigger type exists');
select has_column('public', 'gal_intelligence_snapshots', 'trigger_id', 'GI-SNAP-010 trigger id exists');
select has_column('public', 'gal_intelligence_snapshots', 'profile_snapshot_id', 'GI-SNAP-011 optional profile snapshot link exists');
select has_column('public', 'gal_intelligence_snapshots', 'bag_snapshot_id', 'GI-SNAP-012 optional bag snapshot link exists');
select has_column('public', 'gal_intelligence_snapshots', 'created_at', 'GI-SNAP-013 created timestamp exists');

select ok(pg_temp.gi11_rls_enabled(), 'GI-SNAP-014 RLS is enabled');
select ok(pg_temp.gi11_table_priv('authenticated','SELECT'), 'GI-SNAP-015 golfer may select milestone snapshots');
select ok(not pg_temp.gi11_table_priv('authenticated','INSERT'), 'GI-SNAP-016 golfer cannot insert milestone snapshots');
select ok(not pg_temp.gi11_table_priv('authenticated','UPDATE'), 'GI-SNAP-017 golfer cannot update milestone snapshots');
select ok(not pg_temp.gi11_table_priv('authenticated','DELETE'), 'GI-SNAP-018 golfer cannot delete milestone snapshots');
select ok(pg_temp.gi11_table_priv('service_role','SELECT'), 'GI-SNAP-019 trusted service may read milestone snapshots');
select ok(pg_temp.gi11_table_priv('service_role','INSERT'), 'GI-SNAP-020 trusted service may create milestone snapshots');
select ok(not pg_temp.gi11_table_priv('service_role','UPDATE'), 'GI-SNAP-021 trusted service cannot rewrite milestone snapshots');
select ok(not pg_temp.gi11_table_priv('service_role','DELETE'), 'GI-SNAP-022 trusted service cannot delete milestone snapshots');

select ok(
  not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid=t.tgrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname='gal_intelligence_state'
      and not t.tgisinternal
      and lower(t.tgname) like '%snapshot%'
  ),
  'GI-SNAP-023 no automatic snapshot trigger is attached to every state write'
);

select ok(
  exists (
    select 1 from pg_indexes
    where schemaname='public'
      and tablename='gal_intelligence_snapshots'
      and indexdef ilike '%(user_id, created_at desc)%'
  ),
  'GI-SNAP-024 user/time milestone lookup index exists'
);

select ok(
  to_regclass('public.gal_intelligence_snapshots') is not null
  and exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid=c.conrelid
    join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='public'
      and t.relname='gal_intelligence_snapshots'
      and c.contype='f'
      and pg_get_constraintdef(c.oid) like '%profile_snapshot_id%gal_profile_snapshots%'
  )
  and exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid=c.conrelid
    join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='public'
      and t.relname='gal_intelligence_snapshots'
      and c.contype='f'
      and pg_get_constraintdef(c.oid) like '%bag_snapshot_id%gal_bag_snapshots%'
  ),
  'GI-SNAP-025 optional profile and bag snapshot links are foreign-key governed'
);

select * from finish();
rollback;
