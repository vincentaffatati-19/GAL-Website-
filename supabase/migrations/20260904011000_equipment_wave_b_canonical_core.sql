-- GAL Equipment Knowledge Wave B: canonical equipment identity core

create table if not exists public.gal_equipment_families (
  id uuid primary key default gen_random_uuid(),
  equipment_family_id text not null unique default gal_public_id('GAL-EQF'),
  canonical_brand_id text not null,
  canonical_product_id text unique,
  category text not null,
  family_name text not null,
  lifecycle_state text not null default 'CURRENT' check (lifecycle_state in ('ANNOUNCED','CURRENT','PRIOR_GENERATION','DISCONTINUED','HISTORICAL')),
  source_dataset text,
  source_dataset_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gal_equipment_variants (
  id uuid primary key default gen_random_uuid(),
  equipment_variant_id text not null unique default gal_public_id('GAL-EQV'),
  family_id uuid not null references public.gal_equipment_families(id) on delete cascade,
  variant_key text not null,
  display_name text not null,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (family_id,variant_key,effective_from)
);

create table if not exists public.gal_equipment_components (
  id uuid primary key default gen_random_uuid(),
  equipment_component_id text not null unique default gal_public_id('GAL-EQC'),
  component_type text not null,
  manufacturer_key text,
  display_name text not null,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gal_equipment_aliases (
  id uuid primary key default gen_random_uuid(),
  equipment_alias_id text not null unique default gal_public_id('GAL-EQA'),
  family_id uuid references public.gal_equipment_families(id) on delete cascade,
  variant_id uuid references public.gal_equipment_variants(id) on delete cascade,
  alias_key text not null,
  normalized_alias_key text not null,
  source text,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  check (((family_id is not null)::int + (variant_id is not null)::int)=1)
);

create table if not exists public.gal_equipment_lifecycle_events (
  id uuid primary key default gen_random_uuid(),
  equipment_lifecycle_event_id text not null unique default gal_public_id('GAL-EQL'),
  family_id uuid references public.gal_equipment_families(id) on delete cascade,
  variant_id uuid references public.gal_equipment_variants(id) on delete cascade,
  lifecycle_state text not null check (lifecycle_state in ('ANNOUNCED','CURRENT','PRIOR_GENERATION','DISCONTINUED','HISTORICAL')),
  effective_at timestamptz not null,
  source text,
  created_at timestamptz not null default now(),
  check (((family_id is not null)::int + (variant_id is not null)::int)=1)
);

create index if not exists gal_equipment_families_brand_category_idx on public.gal_equipment_families(canonical_brand_id,category);
create index if not exists gal_equipment_families_product_idx on public.gal_equipment_families(canonical_product_id);
create index if not exists gal_equipment_variants_family_idx on public.gal_equipment_variants(family_id);
create index if not exists gal_equipment_aliases_normalized_idx on public.gal_equipment_aliases(normalized_alias_key);
create index if not exists gal_equipment_lifecycle_entity_idx on public.gal_equipment_lifecycle_events(family_id,variant_id,effective_at desc);

alter table public.gal_equipment_families enable row level security;
alter table public.gal_equipment_variants enable row level security;
alter table public.gal_equipment_components enable row level security;
alter table public.gal_equipment_aliases enable row level security;
alter table public.gal_equipment_lifecycle_events enable row level security;

do $$ declare t text; begin
  foreach t in array array['gal_equipment_families','gal_equipment_variants','gal_equipment_components','gal_equipment_aliases','gal_equipment_lifecycle_events'] loop
    if not exists (select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)',t);
    end if;
  end loop;
end $$;

-- Conservative identity seeding: one family per existing canonical catalog product.
insert into public.gal_equipment_families (
  canonical_brand_id,canonical_product_id,category,family_name,lifecycle_state,source_dataset,source_dataset_version
)
select c.canonical_brand_id,c.canonical_product_id,c.category::text,
       coalesce(nullif(c.display_model,''),c.canonical_product_id),
       case when c.is_active then 'CURRENT' else 'HISTORICAL' end,
       c.source_dataset,c.source_dataset_version
from public.gal_catalog_products c
where not exists (
  select 1 from public.gal_equipment_families f where f.canonical_product_id=c.canonical_product_id
);
