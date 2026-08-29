-- GI-1.1 Jerry's Bag: additive bag metadata and immutable item lifecycle history.

alter table public.gal_bags
  add column bag_type text not null default 'PRIMARY'
    check (bag_type in ('PRIMARY','TRAVEL','SEASONAL','BACKUP','OTHER')),
  add column archived_at timestamptz;

alter table public.gal_bag_items
  add column identification_status text
    check (identification_status is null or identification_status in ('EXACT','PARTIAL','UNKNOWN')),
  add column identification_confidence numeric(4,3)
    check (identification_confidence is null or (identification_confidence >= 0 and identification_confidence <= 1)),
  add column effective_from timestamptz not null default now();

-- Backfill only what the canonical product ID proves. Do not guess partial/unknown identity.
update public.gal_bag_items
set identification_status = 'EXACT',
    identification_confidence = 1.000
where canonical_product_id is not null
  and identification_status is null;

create table public.gal_bag_item_history (
  id uuid primary key default gen_random_uuid(),
  history_id text unique not null default public.gal_public_id('GAL-BIH'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_id uuid not null,
  bag_item_id uuid not null,
  bag_item_public_id text not null,
  item_type public.gal_item_type not null,
  category public.gal_category not null,
  slot_code text,
  slot_label text,
  group_id text,
  canonical_product_id text,
  canonical_brand_id text,
  display_snapshot jsonb not null default '{}'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  bag_status public.gal_bag_status not null,
  counts_toward_14 boolean not null,
  club_count smallint check (club_count is null or (club_count >= 1 and club_count <= 14)),
  owned boolean not null,
  purchase_date date,
  purchase_price numeric(12,2) check (purchase_price is null or purchase_price >= 0),
  purchase_currency char(3),
  retailer_id text,
  decision_snapshot_id uuid,
  identification_status text
    check (identification_status is null or identification_status in ('EXACT','PARTIAL','UNKNOWN')),
  identification_confidence numeric(4,3)
    check (identification_confidence is null or (identification_confidence >= 0 and identification_confidence <= 1)),
  change_type text not null
    check (change_type in ('ADDED','REPLACED','RECONFIGURED','REMOVED','SOLD','LOST','RETIRED','UNKNOWN_DISPOSITION','UPDATED')),
  change_reason text,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz not null default now()
);

create index gal_bag_item_history_user_bag_time_idx
  on public.gal_bag_item_history(user_id, bag_id, created_at desc);
create index gal_bag_item_history_item_time_idx
  on public.gal_bag_item_history(bag_item_id, created_at desc);
create index gal_bag_item_history_product_idx
  on public.gal_bag_item_history(canonical_product_id)
  where canonical_product_id is not null;

alter table public.gal_bag_item_history enable row level security;

revoke all on table public.gal_bag_item_history from public, anon, authenticated;
grant select on table public.gal_bag_item_history to authenticated;
revoke all on table public.gal_bag_item_history from service_role;
grant select, insert on table public.gal_bag_item_history to service_role;

create policy gal_bag_item_history_self_select
on public.gal_bag_item_history
for select
to authenticated
using (user_id = public.gal_current_user_id());

create or replace function gal_private.capture_bag_item_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.gal_bag_items%rowtype;
  v_change_type text;
  v_effective_to timestamptz;
  v_reason text;
begin
  if tg_op = 'INSERT' then
    v_row := new;
    v_change_type := 'ADDED';
    v_effective_to := null;
  elsif tg_op = 'DELETE' then
    v_row := old;
    v_change_type := case
      when old.bag_status = 'RETIRED' then 'RETIRED'
      else 'REMOVED'
    end;
    v_effective_to := clock_timestamp();
  else
    v_row := old;
    v_effective_to := coalesce(new.effective_from, clock_timestamp());
    v_change_type := case
      when new.canonical_product_id is distinct from old.canonical_product_id
        or new.canonical_brand_id is distinct from old.canonical_brand_id
        or new.display_snapshot is distinct from old.display_snapshot
        then 'REPLACED'
      when new.configuration is distinct from old.configuration
        then 'RECONFIGURED'
      when new.bag_status = 'RETIRED' and new.bag_status is distinct from old.bag_status
        then 'RETIRED'
      else 'UPDATED'
    end;
  end if;

  v_reason := nullif(current_setting('gal.bag_change_reason', true), '');

  insert into public.gal_bag_item_history (
    user_id, bag_id, bag_item_id, bag_item_public_id,
    item_type, category, slot_code, slot_label, group_id,
    canonical_product_id, canonical_brand_id, display_snapshot, configuration,
    bag_status, counts_toward_14, club_count, owned,
    purchase_date, purchase_price, purchase_currency, retailer_id,
    decision_snapshot_id, identification_status, identification_confidence,
    change_type, change_reason, effective_from, effective_to
  ) values (
    v_row.user_id, v_row.bag_id, v_row.id, v_row.bag_item_id,
    v_row.item_type, v_row.category, v_row.slot_code, v_row.slot_label, v_row.group_id,
    v_row.canonical_product_id, v_row.canonical_brand_id, v_row.display_snapshot, v_row.configuration,
    v_row.bag_status, v_row.counts_toward_14, v_row.club_count, v_row.owned,
    v_row.purchase_date, v_row.purchase_price, v_row.purchase_currency, v_row.retailer_id,
    v_row.decision_snapshot_id, v_row.identification_status, v_row.identification_confidence,
    v_change_type, v_reason, v_row.effective_from, v_effective_to
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function gal_private.capture_bag_item_history() from public, anon, authenticated, service_role;

drop trigger if exists gal_bag_items_capture_history on public.gal_bag_items;
create trigger gal_bag_items_capture_history
after insert or update or delete on public.gal_bag_items
for each row execute function gal_private.capture_bag_item_history();

comment on table public.gal_bag_item_history is
  'Append-only Jerry''s Bag item lifecycle evidence. Current ownership remains in gal_bag_items.';
