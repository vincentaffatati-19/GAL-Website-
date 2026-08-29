-- GI-1.1 Jerry's Bag Task 3
-- Purpose: golfer-owned what-if bag scenarios that remain isolated from the live bag
-- until an explicit trusted adoption transaction applies them and freezes the result.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_bag_scenarios

create table public.gal_bag_scenarios (
  id uuid primary key default gen_random_uuid(),
  scenario_id text unique not null default ('GAL-SCN-' || gen_random_uuid()::text),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  bag_id uuid not null references public.gal_bags(id) on delete cascade,
  profile_snapshot_id uuid references public.gal_profile_snapshots(id) on delete set null,
  base_bag_snapshot_id uuid references public.gal_bag_snapshots(id) on delete restrict deferrable initially deferred,
  name text not null,
  status text not null default 'OPEN' check (status in ('OPEN','ADOPTED','DISCARDED','EXPIRED')),
  category public.gal_category,
  context jsonb not null default '{}'::jsonb,
  fit_model_version text not null,
  bag_optimization_version text not null,
  equipment_data_version text not null,
  market_code text,
  currency char(3),
  adopted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gal_bag_scenarios_id_user_unique unique (id, user_id)
);

create index gal_bag_scenarios_user_status_idx
  on public.gal_bag_scenarios(user_id, status, updated_at desc);
create index gal_bag_scenarios_bag_idx
  on public.gal_bag_scenarios(bag_id, created_at desc);

create table public.gal_bag_scenario_items (
  id uuid primary key default gen_random_uuid(),
  scenario_item_id text unique not null default ('GAL-SCI-' || gen_random_uuid()::text),
  scenario_id uuid not null,
  user_id uuid not null,
  action_type text not null check (action_type in ('ADD','REMOVE','REPLACE','RECONFIGURE')),
  target_bag_item_id uuid references public.gal_bag_items(id) on delete restrict,
  item_type public.gal_item_type,
  category public.gal_category,
  slot_code text,
  slot_label text,
  canonical_product_id text references public.gal_catalog_products(canonical_product_id) on delete restrict,
  canonical_brand_id text,
  display_snapshot jsonb not null default '{}'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  identification_status text check (identification_status is null or identification_status in ('EXACT','PARTIAL','UNKNOWN')),
  identification_confidence numeric(4,3) check (identification_confidence is null or (identification_confidence >= 0 and identification_confidence <= 1)),
  counts_toward_14 boolean,
  club_count smallint check (club_count is null or (club_count >= 1 and club_count <= 14)),
  owned boolean,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gal_bag_scenario_items_owner_fk
    foreign key (scenario_id, user_id)
    references public.gal_bag_scenarios(id, user_id)
    on delete cascade,
  constraint gal_bag_scenario_items_target_check
    check (
      (action_type = 'ADD' and target_bag_item_id is null)
      or (action_type in ('REMOVE','REPLACE','RECONFIGURE') and target_bag_item_id is not null)
    )
);

create index gal_bag_scenario_items_scenario_idx
  on public.gal_bag_scenario_items(scenario_id, created_at);
create index gal_bag_scenario_items_user_idx
  on public.gal_bag_scenario_items(user_id, scenario_id);

alter table public.gal_bag_scenarios enable row level security;
alter table public.gal_bag_scenario_items enable row level security;

revoke all on public.gal_bag_scenarios from public, anon, authenticated;
revoke all on public.gal_bag_scenario_items from public, anon, authenticated;
grant select, insert, update, delete on public.gal_bag_scenarios to authenticated;
grant select, insert, update, delete on public.gal_bag_scenario_items to authenticated;
grant select, insert, update, delete on public.gal_bag_scenarios to service_role;
grant select, insert, update, delete on public.gal_bag_scenario_items to service_role;

create policy gal_bag_scenarios_self_all
  on public.gal_bag_scenarios
  for all
  to authenticated
  using (user_id = public.gal_current_user_id())
  with check (user_id = public.gal_current_user_id());

create policy gal_bag_scenario_items_self_all
  on public.gal_bag_scenario_items
  for all
  to authenticated
  using (user_id = public.gal_current_user_id())
  with check (user_id = public.gal_current_user_id());

create or replace function gal_private.gal_guard_bag_scenario_state()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
begin
  if current_user = 'authenticated' then
    if tg_op = 'UPDATE' then
      if old.status <> 'OPEN' then
        raise exception 'SCENARIO_CLOSED' using errcode = '42501';
      end if;
      if new.status not in ('OPEN','DISCARDED') then
        raise exception 'TRUSTED_ADOPTION_REQUIRED' using errcode = '42501';
      end if;
    elsif tg_op = 'DELETE' and old.status <> 'OPEN' then
      raise exception 'SCENARIO_CLOSED' using errcode = '42501';
    end if;
  end if;
  if tg_op = 'UPDATE' then
    new.updated_at := now();
  end if;
  return coalesce(new, old);
end;
$$;
revoke execute on function gal_private.gal_guard_bag_scenario_state() from public, anon, authenticated, service_role;

drop trigger if exists gal_bag_scenarios_guard_state on public.gal_bag_scenarios;
create trigger gal_bag_scenarios_guard_state
before update or delete on public.gal_bag_scenarios
for each row execute function gal_private.gal_guard_bag_scenario_state();

create or replace function gal_private.gal_adopt_bag_scenario(
  p_scenario_id uuid,
  p_bag_version text
)
returns uuid
language plpgsql
security invoker
set search_path = public, gal_private
as $$
declare
  v_scenario public.gal_bag_scenarios%rowtype;
  v_item public.gal_bag_scenario_items%rowtype;
  v_snapshot_id uuid;
  v_items jsonb;
  v_club_count integer;
begin
  select * into v_scenario
  from public.gal_bag_scenarios
  where id = p_scenario_id
  for update;

  if not found then
    raise exception 'SCENARIO_NOT_FOUND';
  end if;
  if v_scenario.status <> 'OPEN' then
    raise exception 'SCENARIO_NOT_OPEN';
  end if;

  perform 1
  from public.gal_bags b
  where b.id = v_scenario.bag_id
    and b.user_id = v_scenario.user_id
  for update;
  if not found then
    raise exception 'SCENARIO_BAG_OWNERSHIP_MISMATCH';
  end if;

  for v_item in
    select *
    from public.gal_bag_scenario_items
    where scenario_id = p_scenario_id
      and user_id = v_scenario.user_id
    order by created_at, id
  loop
    if v_item.action_type = 'RECONFIGURE' then
      update public.gal_bag_items
      set configuration = v_item.configuration,
          identification_status = coalesce(v_item.identification_status, identification_status),
          identification_confidence = coalesce(v_item.identification_confidence, identification_confidence),
          effective_from = now(),
          updated_at = now()
      where id = v_item.target_bag_item_id
        and user_id = v_scenario.user_id
        and bag_id = v_scenario.bag_id;
      if not found then raise exception 'TARGET_BAG_ITEM_NOT_FOUND'; end if;

    elsif v_item.action_type = 'REPLACE' then
      update public.gal_bag_items
      set canonical_product_id = v_item.canonical_product_id,
          canonical_brand_id = v_item.canonical_brand_id,
          display_snapshot = v_item.display_snapshot,
          configuration = v_item.configuration,
          identification_status = coalesce(v_item.identification_status, identification_status),
          identification_confidence = coalesce(v_item.identification_confidence, identification_confidence),
          item_type = coalesce(v_item.item_type, item_type),
          category = coalesce(v_item.category, category),
          slot_code = coalesce(v_item.slot_code, slot_code),
          slot_label = coalesce(v_item.slot_label, slot_label),
          counts_toward_14 = coalesce(v_item.counts_toward_14, counts_toward_14),
          club_count = coalesce(v_item.club_count, club_count),
          owned = coalesce(v_item.owned, owned),
          bag_status = 'IN_BAG',
          effective_from = now(),
          updated_at = now()
      where id = v_item.target_bag_item_id
        and user_id = v_scenario.user_id
        and bag_id = v_scenario.bag_id;
      if not found then raise exception 'TARGET_BAG_ITEM_NOT_FOUND'; end if;

    elsif v_item.action_type = 'REMOVE' then
      update public.gal_bag_items
      set bag_status = 'RETIRED',
          effective_from = now(),
          updated_at = now()
      where id = v_item.target_bag_item_id
        and user_id = v_scenario.user_id
        and bag_id = v_scenario.bag_id;
      if not found then raise exception 'TARGET_BAG_ITEM_NOT_FOUND'; end if;

    elsif v_item.action_type = 'ADD' then
      insert into public.gal_bag_items (
        bag_id, user_id, item_type, category, slot_code, slot_label,
        canonical_product_id, canonical_brand_id, display_snapshot, configuration,
        bag_status, counts_toward_14, club_count, owned,
        identification_status, identification_confidence, effective_from
      ) values (
        v_scenario.bag_id,
        v_scenario.user_id,
        coalesce(v_item.item_type, 'CLUB'::public.gal_item_type),
        v_item.category,
        v_item.slot_code,
        v_item.slot_label,
        v_item.canonical_product_id,
        v_item.canonical_brand_id,
        v_item.display_snapshot,
        v_item.configuration,
        'IN_BAG',
        coalesce(v_item.counts_toward_14, false),
        v_item.club_count,
        coalesce(v_item.owned, true),
        coalesce(v_item.identification_status, case when v_item.canonical_product_id is null then 'PARTIAL' else 'EXACT' end),
        v_item.identification_confidence,
        now()
      );
    end if;
  end loop;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'bag_item_id', i.bag_item_id,
      'item_type', i.item_type,
      'category', i.category,
      'slot_code', i.slot_code,
      'slot_label', i.slot_label,
      'canonical_product_id', i.canonical_product_id,
      'canonical_brand_id', i.canonical_brand_id,
      'display_snapshot', i.display_snapshot,
      'configuration', i.configuration,
      'identification_status', i.identification_status,
      'identification_confidence', i.identification_confidence,
      'counts_toward_14', i.counts_toward_14,
      'club_count', i.club_count,
      'owned', i.owned
    ) order by i.slot_code nulls last, i.bag_item_id
  ), '[]'::jsonb),
  coalesce(sum(case
    when i.bag_status = 'IN_BAG' and i.item_type = 'CLUB' and i.counts_toward_14
      then coalesce(i.club_count, 1)
    else 0 end), 0)::integer
  into v_items, v_club_count
  from public.gal_bag_items i
  where i.bag_id = v_scenario.bag_id
    and i.user_id = v_scenario.user_id
    and i.bag_status = 'IN_BAG';

  insert into public.gal_bag_snapshots (
    user_id, bag_id, snapshot_type, bag_version, items_snapshot,
    club_count, market_code, currency, captured_at
  ) values (
    v_scenario.user_id,
    v_scenario.bag_id,
    'SCENARIO_ADOPTION',
    p_bag_version,
    v_items,
    v_club_count,
    v_scenario.market_code,
    v_scenario.currency,
    now()
  ) returning id into v_snapshot_id;

  update public.gal_bag_scenarios
  set status = 'ADOPTED',
      adopted_at = now(),
      updated_at = now()
  where id = p_scenario_id;

  return v_snapshot_id;
end;
$$;

revoke execute on function gal_private.gal_adopt_bag_scenario(uuid,text) from public, anon, authenticated;
grant execute on function gal_private.gal_adopt_bag_scenario(uuid,text) to service_role;

comment on table public.gal_bag_scenarios is
  'Golfer-owned what-if bag scenarios. OPEN scenarios never mutate the current bag; explicit trusted adoption applies them atomically.';
comment on function gal_private.gal_adopt_bag_scenario(uuid,text) is
  'Trusted SECURITY INVOKER adoption transaction. Applies scenario actions, lets existing bag-history triggers preserve prior state, freezes the resulting bag, then marks the scenario ADOPTED.';
