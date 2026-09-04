-- GAL Equipment media rights/provenance registry

create table if not exists public.gal_equipment_media_assets (
  id uuid primary key default gen_random_uuid(),
  equipment_media_asset_id text not null unique default gal_public_id('GAL-EMA'),
  family_id uuid references public.gal_equipment_families(id),
  variant_id uuid references public.gal_equipment_variants(id),
  component_id uuid references public.gal_equipment_components(id),
  configuration_id uuid references public.gal_equipment_configurations(id),
  sample_id uuid references public.gal_equipment_samples(id),
  media_role text not null,
  asset_reference text not null,
  source_provider text,
  rights_state text not null check (rights_state in ('GAL_OWNED','MANUFACTURER_AUTHORIZED','PARTNER_LICENSED','PUBLIC_REFERENCE_ONLY','UNVERIFIED_RIGHTS')),
  approved_surfaces text[] not null default '{}'::text[],
  attribution_required boolean not null default false,
  attribution_text text,
  crop_allowed boolean,
  transform_allowed boolean,
  territory_restrictions text[] not null default '{}'::text[],
  channel_restrictions text[] not null default '{}'::text[],
  effective_from timestamptz,
  expires_at timestamptz,
  approval_state text not null default 'PENDING' check (approval_state in ('PENDING','APPROVED','REJECTED','EXPIRED')),
  supersedes_media_asset_id uuid references public.gal_equipment_media_assets(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((((family_id is not null)::int)+((variant_id is not null)::int)+((component_id is not null)::int)+((configuration_id is not null)::int)+((sample_id is not null)::int))=1)
);

create index if not exists gal_equipment_media_entity_idx on public.gal_equipment_media_assets(family_id,variant_id,component_id,configuration_id,sample_id,approval_state);
create index if not exists gal_equipment_media_rights_idx on public.gal_equipment_media_assets(rights_state,approval_state,expires_at);

create or replace view public.gal_equipment_media_production_v as
select *
from public.gal_equipment_media_assets
where approval_state='APPROVED'
  and rights_state in ('GAL_OWNED','MANUFACTURER_AUTHORIZED','PARTNER_LICENSED')
  and (effective_from is null or effective_from <= now())
  and (expires_at is null or expires_at > now());

alter table public.gal_equipment_media_assets enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_equipment_media_assets' and policyname='gal_internal_no_client_access') then
    create policy gal_internal_no_client_access on public.gal_equipment_media_assets as restrictive for all to anon, authenticated using (false) with check (false);
  end if;
end $$;
