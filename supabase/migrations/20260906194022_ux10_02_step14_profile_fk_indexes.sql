-- GAL UX10.02 STEP 14 — performance hardening for supersession FKs
create index if not exists gal_profile_facts_supersedes_idx
  on public.gal_profile_facts(supersedes_fact_id)
  where supersedes_fact_id is not null;

create index if not exists gal_profile_facts_superseded_by_idx
  on public.gal_profile_facts(superseded_by_fact_id)
  where superseded_by_fact_id is not null;
