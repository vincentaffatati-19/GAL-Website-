-- GAL Equipment Knowledge Wave A: codify the existing legacy/reference baseline.
-- Additive and idempotent. No production rows are copied into staging.

-- Required enum types. Create only when absent.
do $$ begin
  if not exists (select 1 from pg_type where typname='gal_category') then
    create type public.gal_category as enum ('DRIVER','FAIRWAY_WOOD','HYBRID','IRON','WEDGE','PUTTER','GOLF_BALL');
  end if;
  if not exists (select 1 from pg_type where typname='gal_item_type') then
    create type public.gal_item_type as enum ('CLUB','GOLF_BALL');
  end if;
  if not exists (select 1 from pg_type where typname='gal_bag_status') then
    create type public.gal_bag_status as enum ('IN_BAG','CONSIDERING','RECOMMENDED','RETIRED');
  end if;
  if not exists (select 1 from pg_type where typname='gal_valuation_type') then
    create type public.gal_valuation_type as enum ('NEW_RETAIL','PRIVATE_USED','TRADE_IN','PURCHASE_PRICE');
  end if;
  if not exists (select 1 from pg_type where typname='gal_valuation_status') then
    create type public.gal_valuation_status as enum ('KNOWN','UNKNOWN','NOT_APPLICABLE');
  end if;
  if not exists (select 1 from pg_type where typname='gal_confidence') then
    create type public.gal_confidence as enum ('HIGH','MEDIUM','LOW','UNKNOWN');
  end if;
end $$;

create table if not exists public.gal_catalog_products (
  canonical_product_id text primary key,
  canonical_brand_id text not null,
  category public.gal_category not null,
  display_brand text,
  display_model text,
  source_dataset text not null,
  source_dataset_version text not null,
  is_active boolean not null default true,
  synced_at timestamptz not null default now()
);

create table if not exists public.gal_bags (
  id uuid primary key default gen_random_uuid(),
  bag_id text not null unique default gal_public_id('GAL-BAG'::text),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  name text not null default 'My Bag'::text,
  is_active boolean not null default true,
  market_code text,
  currency char(3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gal_decision_snapshots (
  id uuid primary key default gen_random_uuid(),
  decision_snapshot_id text not null unique default gal_public_id('GAL-DS'::text),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  canonical_product_id text references public.gal_catalog_products(canonical_product_id),
  canonical_brand_id text,
  captured_at timestamptz not null default now(),
  source_tool text not null,
  source_tool_version text not null,
  recommendation_rank integer check (recommendation_rank is null or recommendation_rank >= 1),
  user_inputs jsonb not null default '{}'::jsonb,
  metrics jsonb not null default '[]'::jsonb,
  reason_summary text,
  market_code text,
  immutable boolean not null default true check (immutable = true),
  created_at timestamptz not null default now()
);

create table if not exists public.gal_bag_items (
  id uuid primary key default gen_random_uuid(),
  bag_item_id text not null unique default gal_public_id('GAL-BI'::text),
  bag_id uuid not null references public.gal_bags(id) on delete cascade,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  item_type public.gal_item_type not null,
  category public.gal_category not null,
  slot_code text,
  slot_label text,
  group_id text,
  canonical_product_id text references public.gal_catalog_products(canonical_product_id),
  canonical_brand_id text,
  display_snapshot jsonb not null default '{}'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  bag_status public.gal_bag_status not null,
  counts_toward_14 boolean not null default false,
  owned boolean not null default false,
  purchase_date date,
  purchase_price numeric check (purchase_price is null or purchase_price >= 0),
  purchase_currency char(3),
  retailer_id text,
  decision_snapshot_id uuid references public.gal_decision_snapshots(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  club_count smallint check (club_count is null or (club_count between 1 and 14)),
  check (((item_type='GOLF_BALL'::public.gal_item_type) and counts_toward_14=false) or item_type='CLUB'::public.gal_item_type),
  check (((item_type='CLUB'::public.gal_item_type) and slot_code is not null) or item_type='GOLF_BALL'::public.gal_item_type)
);

create table if not exists public.gal_profile_facts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  fact_key text not null,
  fact_value jsonb,
  source text not null,
  source_category text,
  confidence numeric not null default 1.000 check (confidence >= 0 and confidence <= 1),
  user_confirmed boolean not null default false,
  scope text not null default 'global'::text,
  stale_after_days integer check (stale_after_days is null or stale_after_days >= 0),
  observed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, fact_key, scope)
);

create table if not exists public.gal_valuation_snapshots (
  id uuid primary key default gen_random_uuid(),
  valuation_snapshot_id text not null unique default gal_public_id('GAL-VS'::text),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_item_id uuid not null references public.gal_bag_items(id) on delete cascade,
  valuation_type public.gal_valuation_type not null,
  status public.gal_valuation_status not null,
  amount numeric check (amount is null or amount >= 0),
  currency char(3) not null,
  market_code text,
  condition_grade text,
  source_id text,
  source_url text,
  observed_at timestamptz not null,
  confidence public.gal_confidence not null,
  method_note text,
  created_at timestamptz not null default now(),
  check (((status='KNOWN'::public.gal_valuation_status) and amount is not null) or ((status<>'KNOWN'::public.gal_valuation_status) and amount is null))
);

create table if not exists public.gal_release_registry (
  release_version text primary key,
  release_name text not null,
  status text not null,
  sha256 text,
  manifest jsonb not null,
  drive_release_file_id text,
  drive_current_file_id text,
  synced_at timestamptz not null default now()
);

create table if not exists public.gal_release_artifacts (
  release_version text not null,
  artifact_path text not null,
  sha256 text not null,
  size_bytes bigint not null,
  drive_file_id text,
  synced_at timestamptz not null default now(),
  primary key (release_version, artifact_path)
);

create table if not exists public.gal_driver_registry (
  canonical_product_id text primary key,
  is_active boolean not null,
  brand_id text not null,
  brand_name text not null,
  model_name text not null,
  release_version text not null,
  payload jsonb not null,
  synced_at timestamptz not null default now()
);

create table if not exists public.gal_driver_master_registry (
  canonical_product_id text primary key,
  canonical_brand_id text not null,
  display_brand text,
  display_model text,
  source_version text not null,
  active boolean not null default true,
  payload jsonb not null,
  synced_at timestamptz not null default now()
);

create table if not exists public.gal_driver_sources (
  source_id text primary key,
  market_code text,
  release_version text not null,
  payload jsonb not null,
  synced_at timestamptz not null default now()
);

-- Baseline indexes.
create index if not exists gal_catalog_brand_idx on public.gal_catalog_products(canonical_brand_id);
create index if not exists gal_catalog_category_idx on public.gal_catalog_products(category, is_active);
create index if not exists gal_bags_user_active_idx on public.gal_bags(user_id, is_active);
create unique index if not exists gal_one_active_bag_idx on public.gal_bags(user_id) where is_active;
create index if not exists gal_decision_product_idx on public.gal_decision_snapshots(canonical_product_id);
create index if not exists gal_decisions_user_time_idx on public.gal_decision_snapshots(user_id, captured_at desc);
create index if not exists gal_bag_items_decision_idx on public.gal_bag_items(decision_snapshot_id);
create index if not exists gal_bag_items_product_idx on public.gal_bag_items(canonical_product_id);
create index if not exists gal_bag_items_user_idx on public.gal_bag_items(user_id, bag_id, bag_status);
create index if not exists gal_active_slot_idx on public.gal_bag_items(bag_id, slot_code) where item_type='CLUB'::public.gal_item_type and bag_status='IN_BAG'::public.gal_bag_status;
create index if not exists gal_profile_facts_user_idx on public.gal_profile_facts(user_id);
create index if not exists gal_profile_facts_user_key_idx on public.gal_profile_facts(user_id, fact_key);
create index if not exists gal_valuation_item_idx on public.gal_valuation_snapshots(bag_item_id, valuation_type, observed_at desc);
create index if not exists gal_valuation_user_idx on public.gal_valuation_snapshots(user_id);

-- RLS baseline. Policies are added only when absent.
alter table public.gal_catalog_products enable row level security;
alter table public.gal_bags enable row level security;
alter table public.gal_bag_items enable row level security;
alter table public.gal_profile_facts enable row level security;
alter table public.gal_decision_snapshots enable row level security;
alter table public.gal_valuation_snapshots enable row level security;
alter table public.gal_release_registry enable row level security;
alter table public.gal_release_artifacts enable row level security;
alter table public.gal_driver_registry enable row level security;
alter table public.gal_driver_master_registry enable row level security;
alter table public.gal_driver_sources enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_catalog_products' and policyname='gal_catalog_read_authenticated') then
    create policy gal_catalog_read_authenticated on public.gal_catalog_products for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_bags' and policyname='gal_bags_self_all') then
    create policy gal_bags_self_all on public.gal_bags for all to authenticated using (user_id=gal_current_user_id()) with check (user_id=gal_current_user_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_bag_items' and policyname='gal_items_self_all') then
    create policy gal_items_self_all on public.gal_bag_items for all to authenticated using (user_id=gal_current_user_id()) with check (user_id=gal_current_user_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_decision_snapshots' and policyname='gal_decisions_self_select') then
    create policy gal_decisions_self_select on public.gal_decision_snapshots for select to authenticated using (user_id=gal_current_user_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_valuation_snapshots' and policyname='gal_valuations_self_select') then
    create policy gal_valuations_self_select on public.gal_valuation_snapshots for select to authenticated using (user_id=gal_current_user_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gal_profile_facts' and policyname='gal_profile_facts_self_select') then
    create policy gal_profile_facts_self_select on public.gal_profile_facts for select to authenticated using (user_id=gal_current_user_id());
    create policy gal_profile_facts_self_insert on public.gal_profile_facts for insert to authenticated with check (user_id=gal_current_user_id());
    create policy gal_profile_facts_self_update on public.gal_profile_facts for update to authenticated using (user_id=gal_current_user_id()) with check (user_id=gal_current_user_id());
    create policy gal_profile_facts_self_delete on public.gal_profile_facts for delete to authenticated using (user_id=gal_current_user_id());
  end if;
end $$;

-- Internal tables get explicit browser deny policies where no such policy exists.
do $$
declare t text;
begin
  foreach t in array array['gal_release_registry','gal_release_artifacts','gal_driver_registry','gal_driver_master_registry','gal_driver_sources'] loop
    if not exists (select 1 from pg_policies where schemaname='public' and tablename=t and policyname='gal_internal_no_client_access') then
      execute format('create policy gal_internal_no_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)', t);
    end if;
  end loop;
end $$;
