-- GAL GI-1.1 sanitized current-shape test baseline
-- Purpose: reproduce the production core shape in isolated local/CI Supabase only.
-- IMPORTANT: this is NOT a production migration and contains no production user data or historical import secrets.

create extension if not exists pgcrypto;

create type public.gal_account_status as enum ('ACTIVE','LOCKED','DELETION_PENDING','DELETED');
create type public.gal_bag_status as enum ('IN_BAG','CONSIDERING','RECOMMENDED','RETIRED');
create type public.gal_item_type as enum ('CLUB','GOLF_BALL');
create type public.gal_category as enum ('DRIVER','FAIRWAY_WOOD','HYBRID','IRON','WEDGE','PUTTER','GOLF_BALL');
create type public.gal_metric_status as enum ('KNOWN','UNKNOWN','NOT_APPLICABLE');
create type public.gal_valuation_status as enum ('KNOWN','UNKNOWN','NOT_APPLICABLE');
create type public.gal_valuation_type as enum ('NEW_RETAIL','PRIVATE_USED','TRADE_IN','PURCHASE_PRICE');
create type public.gal_confidence as enum ('HIGH','MEDIUM','LOW','UNKNOWN');
create type public.gal_consent_type as enum ('TERMS','PRIVACY','MARKETING_EMAIL','ANALYTICS_OPTIONAL');
create type public.gal_consent_status as enum ('ACCEPTED','DECLINED','WITHDRAWN');

create or replace function public.gal_public_id(prefix text)
returns text
language sql
volatile
set search_path = public, pg_temp
as $$
  select prefix || '-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,16));
$$;

revoke execute on function public.gal_public_id(text) from public, anon, authenticated;

create table public.gal_users (
  id uuid primary key default gen_random_uuid(),
  gal_user_id text unique not null default public.gal_public_id('GAL-USR'),
  auth_user_id uuid unique not null references auth.users(id) on delete cascade,
  account_status public.gal_account_status not null default 'ACTIVE',
  preferred_market_code text,
  preferred_units text check (preferred_units is null or preferred_units in ('IMPERIAL','METRIC')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.gal_consent_records (
  id uuid primary key default gen_random_uuid(),
  consent_id text unique not null default public.gal_public_id('GAL-CNS'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  consent_type public.gal_consent_type not null,
  status public.gal_consent_status not null,
  policy_version text not null,
  source text not null,
  recorded_at timestamptz not null default now()
);
create index gal_consent_user_type_idx on public.gal_consent_records(user_id, consent_type, recorded_at desc);

create table public.gal_catalog_products (
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
create index gal_catalog_brand_idx on public.gal_catalog_products(canonical_brand_id);
create index gal_catalog_category_idx on public.gal_catalog_products(category, is_active);

create table public.gal_bags (
  id uuid primary key default gen_random_uuid(),
  bag_id text unique not null default public.gal_public_id('GAL-BAG'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  name text not null default 'My Bag',
  is_active boolean not null default true,
  market_code text,
  currency char(3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index gal_one_active_bag_idx on public.gal_bags(user_id) where is_active;

create table public.gal_decision_snapshots (
  id uuid primary key default gen_random_uuid(),
  decision_snapshot_id text unique not null default public.gal_public_id('GAL-DS'),
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

create table public.gal_bag_items (
  id uuid primary key default gen_random_uuid(),
  bag_item_id text unique not null default public.gal_public_id('GAL-BI'),
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
  club_count smallint check (club_count is null or (club_count >= 1 and club_count <= 14)),
  owned boolean not null default false,
  purchase_date date,
  purchase_price numeric(12,2) check (purchase_price is null or purchase_price >= 0),
  purchase_currency char(3),
  retailer_id text,
  decision_snapshot_id uuid references public.gal_decision_snapshots(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((item_type='GOLF_BALL' and counts_toward_14=false) or item_type='CLUB'),
  check ((item_type='CLUB' and slot_code is not null) or item_type='GOLF_BALL')
);
create index gal_bag_items_user_idx on public.gal_bag_items(user_id, bag_id, bag_status);
create index gal_bag_items_product_idx on public.gal_bag_items(canonical_product_id);
create index gal_bag_items_decision_idx on public.gal_bag_items(decision_snapshot_id);

create table public.gal_valuation_snapshots (
  id uuid primary key default gen_random_uuid(),
  valuation_snapshot_id text unique not null default public.gal_public_id('GAL-VS'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_item_id uuid not null references public.gal_bag_items(id) on delete cascade,
  valuation_type public.gal_valuation_type not null,
  status public.gal_valuation_status not null,
  amount numeric(12,2) check (amount is null or amount >= 0),
  currency char(3) not null,
  market_code text,
  condition_grade text,
  source_id text,
  source_url text,
  observed_at timestamptz not null,
  confidence public.gal_confidence not null,
  method_note text,
  created_at timestamptz not null default now(),
  check ((status='KNOWN' and amount is not null) or (status<>'KNOWN' and amount is null))
);

create table public.gal_guest_migrations (
  id uuid primary key default gen_random_uuid(),
  migration_id text unique not null default public.gal_public_id('GAL-GM'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  guest_id_hash text not null,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create table public.gal_profile_facts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  fact_key text not null,
  fact_value jsonb,
  source text not null,
  source_category text,
  confidence numeric(4,3) not null default 1.000 check (confidence >= 0 and confidence <= 1),
  user_confirmed boolean not null default false,
  scope text not null default 'global',
  stale_after_days integer check (stale_after_days is null or stale_after_days >= 0),
  observed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint gal_profile_facts_user_fact_scope_key unique (user_id, fact_key, scope)
);
create index gal_profile_facts_user_idx on public.gal_profile_facts(user_id);
create index gal_profile_facts_user_key_idx on public.gal_profile_facts(user_id, fact_key);

create table public.gal_buyer_events (
  id uuid primary key default gen_random_uuid(),
  event_id text not null unique,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_id uuid references public.gal_bags(id) on delete set null,
  decision_snapshot_id uuid references public.gal_decision_snapshots(id) on delete set null,
  event_type text not null,
  category text not null,
  canonical_product_id text,
  canonical_brand_id text,
  product_name text,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  source_tool text not null,
  source_tool_version text not null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index gal_buyer_events_user_time_idx on public.gal_buyer_events(user_id, occurred_at desc);
create index gal_buyer_events_user_category_time_idx on public.gal_buyer_events(user_id, category, occurred_at desc);
create index gal_buyer_events_type_idx on public.gal_buyer_events(event_type);
create index gal_buyer_events_product_idx on public.gal_buyer_events(canonical_product_id) where canonical_product_id is not null;
create index gal_buyer_events_bag_idx on public.gal_buyer_events(bag_id) where bag_id is not null;
create index gal_buyer_events_decision_idx on public.gal_buyer_events(decision_snapshot_id) where decision_snapshot_id is not null;

create table public.gal_intelligence_state (
  user_id uuid primary key references public.gal_users(id) on delete cascade,
  engine_version text not null,
  state jsonb not null default '{}'::jsonb,
  event_count bigint not null default 0,
  latest_event_at timestamptz,
  computed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.gal_current_user_id()
returns uuid
language sql
stable
security invoker
set search_path = public
as $$
  select id from public.gal_users where auth_user_id = auth.uid() and account_status='ACTIVE' limit 1;
$$;
revoke execute on function public.gal_current_user_id() from public, anon;
grant execute on function public.gal_current_user_id() to authenticated;

alter table public.gal_users enable row level security;
alter table public.gal_consent_records enable row level security;
alter table public.gal_catalog_products enable row level security;
alter table public.gal_bags enable row level security;
alter table public.gal_decision_snapshots enable row level security;
alter table public.gal_bag_items enable row level security;
alter table public.gal_valuation_snapshots enable row level security;
alter table public.gal_guest_migrations enable row level security;
alter table public.gal_profile_facts enable row level security;
alter table public.gal_buyer_events enable row level security;
alter table public.gal_intelligence_state enable row level security;

create policy gal_catalog_read_authenticated on public.gal_catalog_products for select to authenticated using (true);
create policy gal_users_self_select on public.gal_users for select to authenticated using (auth_user_id = (select auth.uid()));
create policy gal_users_self_update on public.gal_users for update to authenticated using (auth_user_id = (select auth.uid())) with check (auth_user_id = (select auth.uid()));
create policy gal_consent_self_all on public.gal_consent_records for all to authenticated using (user_id = public.gal_current_user_id()) with check (user_id = public.gal_current_user_id());
create policy gal_bags_self_all on public.gal_bags for all to authenticated using (user_id = public.gal_current_user_id()) with check (user_id = public.gal_current_user_id());
create policy gal_decisions_self_select on public.gal_decision_snapshots for select to authenticated using (user_id = public.gal_current_user_id());
create policy gal_items_self_all on public.gal_bag_items for all to authenticated using (user_id = public.gal_current_user_id()) with check (user_id = public.gal_current_user_id());
create policy gal_valuations_self_select on public.gal_valuation_snapshots for select to authenticated using (user_id = public.gal_current_user_id());
create policy gal_guest_migrations_self_select on public.gal_guest_migrations for select to authenticated using (user_id = public.gal_current_user_id());
create policy gal_profile_facts_self_select on public.gal_profile_facts for select to authenticated using (user_id = public.gal_current_user_id());
create policy gal_profile_facts_self_insert on public.gal_profile_facts for insert to authenticated with check (user_id = public.gal_current_user_id());
create policy gal_profile_facts_self_update on public.gal_profile_facts for update to authenticated using (user_id = public.gal_current_user_id()) with check (user_id = public.gal_current_user_id());
create policy gal_profile_facts_self_delete on public.gal_profile_facts for delete to authenticated using (user_id = public.gal_current_user_id());
create policy gal_buyer_events_self_select on public.gal_buyer_events for select to authenticated using (user_id = public.gal_current_user_id());
create policy gal_buyer_events_self_insert on public.gal_buyer_events for insert to authenticated with check (user_id = public.gal_current_user_id());
create policy gal_intelligence_state_self_select on public.gal_intelligence_state for select to authenticated using (user_id = public.gal_current_user_id());

grant select, insert, update, delete on public.gal_profile_facts to authenticated;
grant select, insert on public.gal_buyer_events to authenticated;
grant select on public.gal_intelligence_state to authenticated;

create or replace function public.gal_parse_set_club_count(p_set text)
returns smallint
language plpgsql
immutable
as $$
declare
  s text := upper(trim(coalesce(p_set,'')));
  start_n int;
  end_n int;
begin
  if s = '' then return null; end if;
  s := replace(s,'–','-'); s := replace(s,'—','-'); s := replace(s,' ','');
  if s ~ '^[2-9]-PW$' then start_n := split_part(s,'-',1)::int; return (11-start_n)::smallint;
  elsif s ~ '^[2-9]-(GW|AW)$' then start_n := split_part(s,'-',1)::int; return (12-start_n)::smallint;
  elsif s ~ '^[2-9]-SW$' then start_n := split_part(s,'-',1)::int; return (13-start_n)::smallint;
  elsif s ~ '^[2-9]-[2-9]$' then start_n := split_part(s,'-',1)::int; end_n := split_part(s,'-',2)::int; if end_n < start_n then return null; end if; return (end_n-start_n+1)::smallint;
  elsif s ~ '^[2-9](,[2-9])*(,PW)?(,GW|,AW|,SW)?$' then return array_length(string_to_array(s,','),1)::smallint;
  end if;
  return null;
end;
$$;

create or replace view public.gal_my_bag_validation
with (security_invoker = true)
as
select
  b.id as bag_id,
  b.user_id,
  coalesce(sum(case when i.bag_status='IN_BAG' and i.item_type='CLUB' and i.counts_toward_14 then coalesce(i.club_count,1) else 0 end),0)::int as club_count,
  count(*) filter (where i.bag_status='IN_BAG' and i.item_type='CLUB' and i.counts_toward_14 and i.club_count is null)::int as unknown_count_items,
  (coalesce(sum(case when i.bag_status='IN_BAG' and i.item_type='CLUB' and i.counts_toward_14 then coalesce(i.club_count,1) else 0 end),0) > 14) as over_14,
  '[]'::jsonb as warnings
from public.gal_bags b
left join public.gal_bag_items i on i.bag_id=b.id
group by b.id,b.user_id;
grant select on public.gal_my_bag_validation to authenticated;

-- Current production-shaped security posture intentionally retained here so readiness tests start RED.
create or replace function public.gal_add_to_my_bag(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.gal_current_user_id();
  if v_user_id is null then raise exception 'AUTH_REQUIRED'; end if;
  return jsonb_build_object('ok',true);
end;
$$;
revoke execute on function public.gal_add_to_my_bag(jsonb) from public, anon;
grant execute on function public.gal_add_to_my_bag(jsonb) to authenticated;

create or replace function public.gal_record_signup_consents(p_policy_version text, p_marketing boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare v_user_id uuid;
begin
  v_user_id := public.gal_current_user_id();
  if v_user_id is null then raise exception 'AUTH_REQUIRED'; end if;
  insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source)
  values
    (v_user_id,'TERMS','ACCEPTED',p_policy_version,'signup'),
    (v_user_id,'PRIVACY','ACCEPTED',p_policy_version,'signup'),
    (v_user_id,'MARKETING_EMAIL',case when p_marketing then 'ACCEPTED'::public.gal_consent_status else 'DECLINED'::public.gal_consent_status end,p_policy_version,'signup');
  return jsonb_build_object('ok',true);
end;
$$;
revoke execute on function public.gal_record_signup_consents(text,boolean) from public, anon;
grant execute on function public.gal_record_signup_consents(text,boolean) to authenticated;
