-- Enforce the locked rule: unknown compatibility is not compatible.

create table if not exists public.gal_equipment_configuration_rule_evaluations (
  id uuid primary key default gen_random_uuid(),
  equipment_configuration_rule_evaluation_id text not null unique default gal_public_id('GAL-CRE'),
  configuration_id uuid not null references public.gal_equipment_configurations(id) on delete cascade,
  compatibility_rule_id uuid not null references public.gal_equipment_compatibility_rules(id) on delete cascade,
  result_state text not null check (result_state in ('PASS','FAIL')),
  evaluator_version text not null,
  evidence_reference text,
  evaluated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(configuration_id,compatibility_rule_id)
);

create index if not exists gal_equipment_rule_eval_rule_idx
  on public.gal_equipment_configuration_rule_evaluations(compatibility_rule_id,configuration_id,result_state);

create index if not exists gal_equipment_rule_eval_config_idx
  on public.gal_equipment_configuration_rule_evaluations(configuration_id,result_state);

alter table public.gal_equipment_configuration_rule_evaluations enable row level security;
revoke all on public.gal_equipment_configuration_rule_evaluations from anon,authenticated;
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
      and tablename='gal_equipment_configuration_rule_evaluations'
      and policyname='gal_internal_no_client_access'
  ) then
    create policy gal_internal_no_client_access
      on public.gal_equipment_configuration_rule_evaluations
      as restrictive for all to anon, authenticated
      using (false) with check (false);
  end if;
end $$;

create or replace view public.gal_equipment_configuration_eligible_v
with (security_invoker=true) as
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
      and (r.effective_from is null or r.effective_from <= now())
      and (r.effective_to is null or r.effective_to > now())
      and (r.category is null or r.category = coalesce(direct_family.category,variant_family.category))
      and not exists (
        select 1
        from public.gal_equipment_configuration_rule_evaluations e
        where e.configuration_id=c.id
          and e.compatibility_rule_id=r.id
          and e.result_state='PASS'
      )
  );

revoke all on public.gal_equipment_configuration_eligible_v from anon,authenticated;
