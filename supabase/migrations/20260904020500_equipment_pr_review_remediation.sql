-- GAL Equipment Knowledge PR #26 architectural review remediation.
-- Additive hardening only; preserves legacy rollback sources and existing evidence history.

-- ---------------------------------------------------------------------------
-- 1. FK-backed evidence lineage + append-only governed characteristics.
-- ---------------------------------------------------------------------------
create table if not exists public.gal_equipment_characteristic_evidence (
  characteristic_id uuid not null references public.gal_equipment_characteristics(id) on delete cascade,
  observation_id uuid not null references public.gal_equipment_observations(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key(characteristic_id,observation_id)
);

alter table public.gal_equipment_characteristic_evidence enable row level security;
revoke all on public.gal_equipment_characteristic_evidence from anon,authenticated;
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_equipment_characteristic_evidence' and policyname='gal_internal_no_client_access') then
    create policy gal_internal_no_client_access on public.gal_equipment_characteristic_evidence as restrictive for all to anon,authenticated using(false) with check(false);
  end if;
end $$;

create index if not exists gal_equipment_characteristic_evidence_observation_idx
  on public.gal_equipment_characteristic_evidence(observation_id,characteristic_id);

create or replace function public.gal_validate_equipment_characteristic()
returns trigger language plpgsql set search_path=public as $$
declare current_head uuid; bad_observation uuid; prior record;
begin
  if tg_op in ('UPDATE','DELETE') and old.governance_status='PRODUCTION' then
    raise exception 'production equipment characteristics are immutable; create a superseding characteristic';
  end if;
  if tg_op='DELETE' then return old; end if;

  select u into bad_observation
  from unnest(coalesce(new.evidence_observation_ids,'{}'::uuid[])) u
  where not exists(select 1 from public.gal_equipment_observations o where o.id=u)
  limit 1;
  if bad_observation is not null then
    raise exception 'equipment characteristic references nonexistent evidence observation %',bad_observation using errcode='23503';
  end if;

  if new.supersedes_characteristic_id is not null then
    select * into prior from public.gal_equipment_characteristics where id=new.supersedes_characteristic_id;
    if not found then raise exception 'superseded characteristic not found' using errcode='23503'; end if;
    if prior.attribute_definition_id<>new.attribute_definition_id
       or prior.family_id is distinct from new.family_id
       or prior.variant_id is distinct from new.variant_id
       or prior.component_id is distinct from new.component_id then
      raise exception 'superseding characteristic must preserve subject and attribute';
    end if;
  end if;

  if new.governance_status='PRODUCTION' then
    select c.id into current_head
    from public.gal_equipment_characteristics c
    where c.governance_status='PRODUCTION'
      and c.attribute_definition_id=new.attribute_definition_id
      and c.family_id is not distinct from new.family_id
      and c.variant_id is not distinct from new.variant_id
      and c.component_id is not distinct from new.component_id
      and (c.effective_to is null or c.effective_to>now())
      and not exists(select 1 from public.gal_equipment_characteristics n where n.supersedes_characteristic_id=c.id and n.governance_status='PRODUCTION')
      and c.id is distinct from new.id
    order by c.effective_from desc nulls last,c.created_at desc
    limit 1;
    if current_head is not null and new.supersedes_characteristic_id is distinct from current_head then
      raise exception 'new production characteristic must supersede current production head %',current_head;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists gal_equipment_characteristic_governance on public.gal_equipment_characteristics;
create trigger gal_equipment_characteristic_governance
before insert or update or delete on public.gal_equipment_characteristics
for each row execute function public.gal_validate_equipment_characteristic();

create or replace function public.gal_sync_equipment_characteristic_evidence()
returns trigger language plpgsql set search_path=public as $$
begin
  delete from public.gal_equipment_characteristic_evidence where characteristic_id=new.id;
  insert into public.gal_equipment_characteristic_evidence(characteristic_id,observation_id)
  select new.id,u from unnest(coalesce(new.evidence_observation_ids,'{}'::uuid[])) u;
  return new;
end $$;

drop trigger if exists gal_equipment_characteristic_evidence_sync on public.gal_equipment_characteristics;
create trigger gal_equipment_characteristic_evidence_sync
after insert or update on public.gal_equipment_characteristics
for each row execute function public.gal_sync_equipment_characteristic_evidence();

insert into public.gal_equipment_characteristic_evidence(characteristic_id,observation_id)
select c.id,u
from public.gal_equipment_characteristics c
cross join lateral unnest(coalesce(c.evidence_observation_ids,'{}'::uuid[])) u
join public.gal_equipment_observations o on o.id=u
on conflict do nothing;

-- Current governed consumer truth: only effective, unsuperseded production heads.
create or replace view public.gal_equipment_detail_v with (security_invoker=true) as
select
  f.id as family_id,
  f.equipment_family_id,
  f.canonical_product_id,
  f.canonical_brand_id,
  f.category,
  f.family_name,
  f.lifecycle_state,
  coalesce(jsonb_agg(distinct jsonb_build_object(
    'attribute_key',ad.attribute_key,
    'value',ch.value_json,
    'unit',ch.unit,
    'claim_state',ch.claim_state,
    'methodology_version',ch.methodology_version
  )) filter (where ch.id is not null),'[]'::jsonb) as approved_characteristics
from public.gal_equipment_families f
left join public.gal_equipment_characteristics ch
  on ch.family_id=f.id
 and ch.governance_status='PRODUCTION'
 and (ch.effective_from is null or ch.effective_from<=now())
 and (ch.effective_to is null or ch.effective_to>now())
 and not exists(
   select 1 from public.gal_equipment_characteristics n
   where n.supersedes_characteristic_id=ch.id
     and n.governance_status='PRODUCTION'
     and (n.effective_from is null or n.effective_from<=now())
     and (n.effective_to is null or n.effective_to>now())
 )
left join public.gal_equipment_attribute_definitions ad on ad.id=ch.attribute_definition_id
group by f.id;

-- ---------------------------------------------------------------------------
-- 2. Configuration-level AI Fitting readiness.
-- ---------------------------------------------------------------------------
create or replace view public.gal_equipment_ai_fit_v with (security_invoker=true) as
select
  d.*,
  r.id as readiness_state_id,
  r.readiness_state,
  r.use_case,
  r.blocking_gap_count,
  c.id as configuration_id,
  c.equipment_configuration_id,
  c.configuration_key,
  c.display_name as configuration_name,
  c.support_state,
  (r.readiness_state='AI_FIT_LIMITED') as limited_evidence
from public.gal_equipment_detail_v d
join public.gal_equipment_configuration_eligible_v c
  on c.family_id=d.family_id
  or exists(select 1 from public.gal_equipment_variants v where v.id=c.variant_id and v.family_id=d.family_id)
join lateral (
  select rs.*
  from public.gal_equipment_readiness_state rs
  where rs.configuration_id=c.id
    and rs.use_case='AI_FIT'
    and rs.readiness_state in ('AI_FIT_LIMITED','AI_FIT_READY')
  order by rs.evaluated_at desc,rs.created_at desc
  limit 1
) r on true;

-- ---------------------------------------------------------------------------
-- 3. Scoped compatibility applicability + append-only evaluation history.
-- ---------------------------------------------------------------------------
alter table public.gal_equipment_compatibility_rules
  add column if not exists applies_to_configuration_id uuid references public.gal_equipment_configurations(id) on delete cascade,
  add column if not exists applicability_setting_key text;

create index if not exists gal_equipment_compatibility_config_idx
  on public.gal_equipment_compatibility_rules(applies_to_configuration_id,active)
  where applies_to_configuration_id is not null;

alter table public.gal_equipment_configuration_rule_evaluations
  add column if not exists supersedes_evaluation_id uuid references public.gal_equipment_configuration_rule_evaluations(id) on delete restrict;

-- The original uniqueness constraint prevented historical supersession chains.
do $$ declare n text; begin
  select conname into n
  from pg_constraint
  where conrelid='public.gal_equipment_configuration_rule_evaluations'::regclass
    and contype='u'
    and pg_get_constraintdef(oid) ilike '%configuration_id%compatibility_rule_id%'
  limit 1;
  if n is not null then execute format('alter table public.gal_equipment_configuration_rule_evaluations drop constraint %I',n); end if;
end $$;

create index if not exists gal_equipment_rule_eval_supersedes_idx
  on public.gal_equipment_configuration_rule_evaluations(supersedes_evaluation_id)
  where supersedes_evaluation_id is not null;

create or replace function public.gal_guard_compatibility_evaluation_history()
returns trigger language plpgsql set search_path=public as $$
declare head uuid; prior record;
begin
  if tg_op in ('UPDATE','DELETE') then
    raise exception 'compatibility evaluations are immutable; insert a superseding evaluation';
  end if;
  if nullif(btrim(coalesce(new.evidence_reference,'')),'') is null then
    raise exception 'compatibility evaluation requires evidence_reference';
  end if;
  select e.id into head
  from public.gal_equipment_configuration_rule_evaluations e
  where e.configuration_id=new.configuration_id
    and e.compatibility_rule_id=new.compatibility_rule_id
    and not exists(select 1 from public.gal_equipment_configuration_rule_evaluations n where n.supersedes_evaluation_id=e.id)
  order by e.evaluated_at desc,e.created_at desc limit 1;

  if new.supersedes_evaluation_id is not null then
    select * into prior from public.gal_equipment_configuration_rule_evaluations where id=new.supersedes_evaluation_id;
    if not found then raise exception 'superseded compatibility evaluation not found' using errcode='23503'; end if;
    if prior.configuration_id<>new.configuration_id or prior.compatibility_rule_id<>new.compatibility_rule_id then
      raise exception 'superseding evaluation must preserve configuration and rule';
    end if;
  end if;
  if head is not null and new.supersedes_evaluation_id is distinct from head then
    raise exception 'new compatibility evaluation must supersede current head %',head;
  elsif head is null and new.supersedes_evaluation_id is not null then
    raise exception 'cannot supersede a non-current compatibility evaluation';
  end if;
  return new;
end $$;

drop trigger if exists gal_equipment_rule_evaluation_history on public.gal_equipment_configuration_rule_evaluations;
create trigger gal_equipment_rule_evaluation_history
before insert or update or delete on public.gal_equipment_configuration_rule_evaluations
for each row execute function public.gal_guard_compatibility_evaluation_history();

create or replace view public.gal_equipment_configuration_eligible_v with (security_invoker=true) as
select c.*
from public.gal_equipment_configurations c
left join public.gal_equipment_families direct_family on direct_family.id=c.family_id
left join public.gal_equipment_variants v on v.id=c.variant_id
left join public.gal_equipment_families variant_family on variant_family.id=v.family_id
where c.support_state in ('FACTORY_STANDARD','FACTORY_CUSTOM','AFTERMARKET_VALID')
  and not exists (
    select 1
    from public.gal_equipment_compatibility_rules r
    where r.active
      and r.hard_rule
      and (r.effective_from is null or r.effective_from<=now())
      and (r.effective_to is null or r.effective_to>now())
      and (r.category is null or r.category=coalesce(direct_family.category,variant_family.category))
      and (r.applies_to_configuration_id is null or r.applies_to_configuration_id=c.id)
      and (r.subject_component_type is null or exists(
        select 1 from public.gal_equipment_configuration_components cc
        join public.gal_equipment_components comp on comp.id=cc.component_id
        where cc.configuration_id=c.id and comp.component_type=r.subject_component_type
      ))
      and (r.target_component_type is null or exists(
        select 1 from public.gal_equipment_configuration_components cc
        join public.gal_equipment_components comp on comp.id=cc.component_id
        where cc.configuration_id=c.id and comp.component_type=r.target_component_type
      ))
      and (r.applicability_setting_key is null or exists(
        select 1 from public.gal_equipment_configuration_settings s
        where s.configuration_id=c.id and s.setting_key=r.applicability_setting_key
      ))
      and not exists (
        select 1
        from public.gal_equipment_configuration_rule_evaluations e
        where e.configuration_id=c.id
          and e.compatibility_rule_id=r.id
          and e.result_state='PASS'
          and not exists(
            select 1 from public.gal_equipment_configuration_rule_evaluations n
            where n.supersedes_evaluation_id=e.id
          )
      )
  );

-- Recreate AI Fit after the eligibility view changes to preserve dependency semantics.
create or replace view public.gal_equipment_ai_fit_v with (security_invoker=true) as
select
  d.*,
  r.id as readiness_state_id,
  r.readiness_state,
  r.use_case,
  r.blocking_gap_count,
  c.id as configuration_id,
  c.equipment_configuration_id,
  c.configuration_key,
  c.display_name as configuration_name,
  c.support_state,
  (r.readiness_state='AI_FIT_LIMITED') as limited_evidence
from public.gal_equipment_detail_v d
join public.gal_equipment_configuration_eligible_v c
  on c.family_id=d.family_id
  or exists(select 1 from public.gal_equipment_variants v where v.id=c.variant_id and v.family_id=d.family_id)
join lateral (
  select rs.* from public.gal_equipment_readiness_state rs
  where rs.configuration_id=c.id and rs.use_case='AI_FIT'
    and rs.readiness_state in ('AI_FIT_LIMITED','AI_FIT_READY')
  order by rs.evaluated_at desc,rs.created_at desc limit 1
) r on true;

-- ---------------------------------------------------------------------------
-- 4. FK-backed test-derivation lineage + append-only approved derivations.
-- ---------------------------------------------------------------------------
alter table public.gal_equipment_derivations
  add column if not exists derivation_status text not null default 'DRAFT',
  add column if not exists supersedes_derivation_id uuid references public.gal_equipment_derivations(id) on delete restrict;

do $$ begin
  if not exists(select 1 from pg_constraint where conrelid='public.gal_equipment_derivations'::regclass and conname='gal_equipment_derivations_status_check') then
    alter table public.gal_equipment_derivations add constraint gal_equipment_derivations_status_check check (derivation_status in ('DRAFT','REVIEW_PENDING','APPROVED','PRODUCTION','RETIRED'));
  end if;
end $$;

create table if not exists public.gal_equipment_derivation_observations (
  derivation_id uuid not null references public.gal_equipment_derivations(id) on delete cascade,
  test_observation_id uuid not null references public.gal_equipment_test_observations(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key(derivation_id,test_observation_id)
);
alter table public.gal_equipment_derivation_observations enable row level security;
revoke all on public.gal_equipment_derivation_observations from anon,authenticated;
do $$ begin
  if not exists(select 1 from pg_policies where schemaname='public' and tablename='gal_equipment_derivation_observations' and policyname='gal_internal_no_client_access') then
    create policy gal_internal_no_client_access on public.gal_equipment_derivation_observations as restrictive for all to anon,authenticated using(false) with check(false);
  end if;
end $$;
create index if not exists gal_equipment_derivation_observation_test_idx
  on public.gal_equipment_derivation_observations(test_observation_id,derivation_id);
create index if not exists gal_equipment_derivation_supersedes_idx
  on public.gal_equipment_derivations(supersedes_derivation_id) where supersedes_derivation_id is not null;

create or replace function public.gal_validate_equipment_derivation()
returns trigger language plpgsql set search_path=public as $$
declare bad_observation uuid; prior record;
begin
  if tg_op in ('UPDATE','DELETE') and old.derivation_status in ('APPROVED','PRODUCTION','RETIRED') then
    raise exception 'governed equipment derivations are immutable; create a superseding derivation';
  end if;
  if tg_op='DELETE' then return old; end if;
  select u into bad_observation
  from unnest(coalesce(new.contributing_observation_ids,'{}'::uuid[])) u
  where not exists(select 1 from public.gal_equipment_test_observations o where o.id=u)
  limit 1;
  if bad_observation is not null then
    raise exception 'equipment derivation references nonexistent test observation %',bad_observation using errcode='23503';
  end if;
  if new.supersedes_derivation_id is not null then
    select * into prior from public.gal_equipment_derivations where id=new.supersedes_derivation_id;
    if not found then raise exception 'superseded derivation not found' using errcode='23503'; end if;
    if prior.attribute_definition_id<>new.attribute_definition_id
       or prior.family_id is distinct from new.family_id
       or prior.variant_id is distinct from new.variant_id
       or prior.configuration_id is distinct from new.configuration_id then
      raise exception 'superseding derivation must preserve subject and attribute';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists gal_equipment_derivation_governance on public.gal_equipment_derivations;
create trigger gal_equipment_derivation_governance
before insert or update or delete on public.gal_equipment_derivations
for each row execute function public.gal_validate_equipment_derivation();

create or replace function public.gal_sync_equipment_derivation_evidence()
returns trigger language plpgsql set search_path=public as $$
begin
  delete from public.gal_equipment_derivation_observations where derivation_id=new.id;
  insert into public.gal_equipment_derivation_observations(derivation_id,test_observation_id)
  select new.id,u from unnest(coalesce(new.contributing_observation_ids,'{}'::uuid[])) u;
  return new;
end $$;

drop trigger if exists gal_equipment_derivation_evidence_sync on public.gal_equipment_derivations;
create trigger gal_equipment_derivation_evidence_sync
after insert or update on public.gal_equipment_derivations
for each row execute function public.gal_sync_equipment_derivation_evidence();

insert into public.gal_equipment_derivation_observations(derivation_id,test_observation_id)
select d.id,u
from public.gal_equipment_derivations d
cross join lateral unnest(coalesce(d.contributing_observation_ids,'{}'::uuid[])) u
join public.gal_equipment_test_observations o on o.id=u
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 5. Remove direct browser access to privileged helper schema/functions.
-- Public read contracts remain narrow, fixed-search-path SECURITY DEFINER RPCs.
-- ---------------------------------------------------------------------------
revoke all on function gal_private.equipment_guide_reader() from anon,authenticated;
revoke all on function gal_private.equipment_ai_fit_reader() from anon,authenticated;
revoke usage on schema gal_private from anon,authenticated;

create or replace function public.gal_public_equipment_guide()
returns setof public.gal_equipment_guide_v
language sql stable security definer
set search_path=public,gal_private
as $$ select * from gal_private.equipment_guide_reader(); $$;

create or replace function public.gal_authenticated_equipment_ai_fit()
returns setof public.gal_equipment_ai_fit_v
language sql stable security definer
set search_path=public,gal_private
as $$ select * from gal_private.equipment_ai_fit_reader(); $$;

revoke all on function public.gal_public_equipment_guide() from public;
revoke all on function public.gal_authenticated_equipment_ai_fit() from public;
grant execute on function public.gal_public_equipment_guide() to anon,authenticated;
grant execute on function public.gal_authenticated_equipment_ai_fit() to authenticated;
revoke execute on function public.gal_authenticated_equipment_ai_fit() from anon;
