-- GI-1.1 Recommendation Auditability Task 6
-- Purpose: immutable recommendation shortlist evidence plus deterministic Fit Score components.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_recommendation_items

create table public.gal_recommendation_items (
  id uuid primary key default gen_random_uuid(),
  recommendation_item_id text unique not null default ('GAL-RI-' || gen_random_uuid()::text),
  recommendation_run_id uuid not null references public.gal_recommendation_runs(id) on delete restrict,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  result_type text not null check (result_type in ('PRODUCT_OPTION','KEEP_CURRENT','RECONFIGURE_CURRENT','NO_RECOMMENDATION')),
  canonical_product_id text references public.gal_catalog_products(canonical_product_id) on delete restrict,
  configuration jsonb not null default '{}'::jsonb,
  eligibility_status text not null check (eligibility_status in ('ELIGIBLE','EXCLUDED')),
  exclusion_reason text,
  fit_score numeric(5,2) check (fit_score is null or (fit_score >= 0 and fit_score <= 100)),
  recommendation_rank integer check (recommendation_rank is null or recommendation_rank >= 1),
  confidence numeric(4,3) check (confidence is null or (confidence >= 0 and confidence <= 1)),
  strengths jsonb not null default '[]'::jsonb,
  tradeoffs jsonb not null default '[]'::jsonb,
  current_equipment_delta numeric(7,2),
  price_evidence jsonb not null default '{}'::jsonb,
  availability_evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint gal_recommendation_items_product_option_product check (
    result_type <> 'PRODUCT_OPTION' or canonical_product_id is not null
  ),
  constraint gal_recommendation_items_eligible_score check (
    eligibility_status <> 'ELIGIBLE' or fit_score is not null
  ),
  constraint gal_recommendation_items_eligible_confidence check (
    eligibility_status <> 'ELIGIBLE' or confidence is not null
  )
);

create unique index gal_recommendation_items_run_rank_uidx
  on public.gal_recommendation_items(recommendation_run_id, recommendation_rank)
  where recommendation_rank is not null;
create index gal_recommendation_items_run_idx
  on public.gal_recommendation_items(recommendation_run_id, created_at);
create index gal_recommendation_items_user_run_idx
  on public.gal_recommendation_items(user_id, recommendation_run_id);
create index gal_recommendation_items_product_idx
  on public.gal_recommendation_items(canonical_product_id)
  where canonical_product_id is not null;

create table public.gal_fit_score_components (
  id uuid primary key default gen_random_uuid(),
  recommendation_item_id uuid not null references public.gal_recommendation_items(id) on delete restrict,
  user_id uuid not null references public.gal_users(id) on delete cascade,
  component_key text not null check (btrim(component_key) <> ''),
  raw_score numeric,
  normalized_score numeric(7,3) not null check (normalized_score >= 0 and normalized_score <= 100),
  weight numeric(7,6) not null check (weight >= 0 and weight <= 1),
  weighted_score numeric(8,3) not null,
  evidence jsonb not null default '{}'::jsonb,
  model_version text not null check (btrim(model_version) <> ''),
  created_at timestamptz not null default now(),
  constraint gal_fit_score_components_item_key_key unique (recommendation_item_id, component_key)
);

create index gal_fit_score_components_item_idx
  on public.gal_fit_score_components(recommendation_item_id);
create index gal_fit_score_components_user_item_idx
  on public.gal_fit_score_components(user_id, recommendation_item_id);

alter table public.gal_recommendation_items enable row level security;
alter table public.gal_fit_score_components enable row level security;

revoke all on table public.gal_recommendation_items from public, anon, authenticated;
grant select on table public.gal_recommendation_items to authenticated;
revoke all on table public.gal_recommendation_items from service_role;
grant select, insert on table public.gal_recommendation_items to service_role;

revoke all on table public.gal_fit_score_components from public, anon, authenticated;
grant select on table public.gal_fit_score_components to authenticated;
revoke all on table public.gal_fit_score_components from service_role;
grant select, insert on table public.gal_fit_score_components to service_role;

create policy gal_recommendation_items_self_select
  on public.gal_recommendation_items
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

create policy gal_fit_score_components_self_select
  on public.gal_fit_score_components
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

create or replace function gal_private.gal_validate_recommendation_item_ownership()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
declare
  v_run_user_id uuid;
  v_run_category public.gal_category;
  v_product_category public.gal_category;
begin
  select user_id, category
    into v_run_user_id, v_run_category
  from public.gal_recommendation_runs
  where id = new.recommendation_run_id;

  if v_run_user_id is null or v_run_user_id <> new.user_id then
    raise exception 'RECOMMENDATION_ITEM_RUN_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if new.canonical_product_id is not null and v_run_category is not null then
    select category into v_product_category
    from public.gal_catalog_products
    where canonical_product_id = new.canonical_product_id;

    if v_product_category is distinct from v_run_category then
      raise exception 'RECOMMENDATION_ITEM_CATEGORY_MISMATCH' using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;
revoke execute on function gal_private.gal_validate_recommendation_item_ownership() from public, anon, authenticated, service_role;

drop trigger if exists gal_recommendation_items_validate_ownership on public.gal_recommendation_items;
create trigger gal_recommendation_items_validate_ownership
before insert on public.gal_recommendation_items
for each row execute function gal_private.gal_validate_recommendation_item_ownership();

create or replace function gal_private.gal_validate_fit_component_ownership()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
declare
  v_item_user_id uuid;
begin
  select user_id into v_item_user_id
  from public.gal_recommendation_items
  where id = new.recommendation_item_id;

  if v_item_user_id is null or v_item_user_id <> new.user_id then
    raise exception 'FIT_COMPONENT_ITEM_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  return new;
end;
$$;
revoke execute on function gal_private.gal_validate_fit_component_ownership() from public, anon, authenticated, service_role;

drop trigger if exists gal_fit_score_components_validate_ownership on public.gal_fit_score_components;
create trigger gal_fit_score_components_validate_ownership
before insert on public.gal_fit_score_components
for each row execute function gal_private.gal_validate_fit_component_ownership();

create or replace function gal_private.gal_validate_fit_component_reconciliation()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
declare
  v_item_id uuid;
  v_weight_sum numeric;
  v_weighted_sum numeric;
  v_fit_score numeric;
begin
  v_item_id := coalesce(new.recommendation_item_id, old.recommendation_item_id);

  select coalesce(sum(weight),0), coalesce(sum(weighted_score),0)
    into v_weight_sum, v_weighted_sum
  from public.gal_fit_score_components
  where recommendation_item_id = v_item_id;

  if v_weight_sum > 1.000001 then
    raise exception 'FIT_COMPONENT_WEIGHT_SUM_EXCEEDS_ONE' using errcode = '23514';
  end if;

  if abs(v_weight_sum - 1.0) <= 0.000001 then
    select fit_score into v_fit_score
    from public.gal_recommendation_items
    where id = v_item_id;

    if v_fit_score is not null and abs(v_weighted_sum - v_fit_score) > 0.01 then
      raise exception 'FIT_COMPONENTS_DO_NOT_RECONCILE' using errcode = '23514';
    end if;
  end if;

  return null;
end;
$$;
revoke execute on function gal_private.gal_validate_fit_component_reconciliation() from public, anon, authenticated, service_role;

drop trigger if exists gal_fit_score_components_reconcile on public.gal_fit_score_components;
create trigger gal_fit_score_components_reconcile
after insert or update or delete on public.gal_fit_score_components
for each row execute function gal_private.gal_validate_fit_component_reconciliation();

comment on table public.gal_recommendation_items is
  'Immutable recommendation candidate/finalist evidence. Fit ranking is deterministic and contains no commerce payout inputs.';
comment on table public.gal_fit_score_components is
  'Immutable deterministic Fit Score component evidence for a recommendation item. Confidence remains separate from Fit Score.';
