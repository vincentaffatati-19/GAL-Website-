-- GI-1.1
-- Purpose: extend current golfer facts additively with explicit value/provenance metadata.
-- Spec: docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md

-- Refuse the governance FK if an environment has acquired uncataloged fact keys.
do $$
begin
  if exists (
    select 1
    from public.gal_profile_facts pf
    left join public.gal_fact_catalog fc on fc.fact_key = pf.fact_key
    where fc.fact_key is null
  ) then
    raise exception 'GI11_UNCATALOGED_PROFILE_FACT_PRECONDITION';
  end if;
end
$$;

alter table public.gal_profile_facts
  add column value_state text not null default 'KNOWN',
  add column unit text,
  add column source_type text,
  add column source_detail jsonb not null default '{}'::jsonb,
  add column fact_catalog_version text not null default 'FACT-1.0',
  add column effective_at timestamptz,
  add column last_confirmed_at timestamptz,
  add column model_version text,
  add column question_version text,
  add column privacy_class text,
  add column commercial_class text,
  add column data_source_id uuid;

alter table public.gal_profile_facts
  add constraint gal_profile_facts_value_state_check
    check (value_state in ('KNOWN','UNKNOWN','NOT_ANSWERED','NOT_APPLICABLE','INFERRED_ONLY')),
  add constraint gal_profile_facts_source_type_check
    check (source_type is null or source_type in ('DECLARED','MEASURED','OBSERVED','INFERRED','IMPORTED','SYSTEM')),
  add constraint gal_profile_facts_fact_key_fk
    foreign key (fact_key)
    references public.gal_fact_catalog(fact_key),
  add constraint gal_profile_facts_data_source_fk
    foreign key (data_source_id)
    references public.gal_external_source_catalog(id)
    on delete set null;

create index gal_profile_facts_data_source_idx
  on public.gal_profile_facts(data_source_id)
  where data_source_id is not null;
