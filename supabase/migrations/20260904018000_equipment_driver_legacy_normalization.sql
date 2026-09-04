-- GAL Equipment Knowledge Wave D: conservative legacy driver normalization

create table if not exists public.gal_equipment_legacy_reconciliation (
  id uuid primary key default gen_random_uuid(),
  legacy_table text not null,
  legacy_key text not null,
  canonical_product_id text,
  family_id uuid references public.gal_equipment_families(id),
  normalization_status text not null check (normalization_status in ('NORMALIZED','UNRESOLVED')),
  reason text,
  source_version text,
  created_at timestamptz not null default now(),
  unique(legacy_table,legacy_key)
);

create index if not exists gal_equipment_legacy_recon_product_idx on public.gal_equipment_legacy_reconciliation(canonical_product_id,normalization_status);

-- Deterministic identity reconciliation by canonical IDs only. No marketing-text inference.
insert into public.gal_equipment_legacy_reconciliation (legacy_table,legacy_key,canonical_product_id,family_id,normalization_status,reason,source_version)
select 'gal_driver_master_registry',d.canonical_product_id,d.canonical_product_id,f.id,
       case when f.id is not null then 'NORMALIZED' else 'UNRESOLVED' end,
       case when f.id is null then 'No canonical family mapping for legacy canonical_product_id' end,
       d.source_version
from public.gal_driver_master_registry d
left join public.gal_equipment_families f on f.canonical_product_id=d.canonical_product_id
on conflict (legacy_table,legacy_key) do nothing;

-- Preserve each legacy row as a source record. Payload stays raw lineage; no unsupported analytical characteristic is promoted.
insert into public.gal_equipment_sources (source_type,provider_name,source_reference,raw_source_reference,source_version)
select 'LEGACY_DATASET','GAL legacy driver master registry',
       'gal_driver_master_registry:'||d.canonical_product_id,
       d.payload::text,
       d.source_version
from public.gal_driver_master_registry d
where not exists (
  select 1 from public.gal_equipment_sources s
  where s.source_reference='gal_driver_master_registry:'||d.canonical_product_id
);

alter table public.gal_equipment_legacy_reconciliation enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_equipment_legacy_reconciliation' and policyname='gal_internal_no_client_access') then
    create policy gal_internal_no_client_access on public.gal_equipment_legacy_reconciliation as restrictive for all to anon, authenticated using (false) with check (false);
  end if;
end $$;
