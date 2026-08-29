-- GI-1.1 Recommendation Auditability Task 7
-- Purpose: link immutable legacy decision snapshots to the normalized recommendation audit chain.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_recommendation_audit_links

alter table public.gal_decision_snapshots
  add column recommendation_run_id uuid,
  add column recommendation_item_id uuid,
  add column profile_snapshot_id uuid,
  add column bag_snapshot_id uuid;

alter table public.gal_decision_snapshots
  add constraint gal_decision_snapshots_recommendation_run_fk
    foreign key (recommendation_run_id) references public.gal_recommendation_runs(id) on delete restrict,
  add constraint gal_decision_snapshots_recommendation_item_fk
    foreign key (recommendation_item_id) references public.gal_recommendation_items(id) on delete restrict,
  add constraint gal_decision_snapshots_profile_snapshot_fk
    foreign key (profile_snapshot_id) references public.gal_profile_snapshots(id) on delete restrict,
  add constraint gal_decision_snapshots_bag_snapshot_fk
    foreign key (bag_snapshot_id) references public.gal_bag_snapshots(id) on delete restrict;

create index gal_decision_snapshots_run_idx
  on public.gal_decision_snapshots(recommendation_run_id)
  where recommendation_run_id is not null;
create index gal_decision_snapshots_item_idx
  on public.gal_decision_snapshots(recommendation_item_id)
  where recommendation_item_id is not null;
create index gal_decision_snapshots_profile_idx
  on public.gal_decision_snapshots(profile_snapshot_id)
  where profile_snapshot_id is not null;
create index gal_decision_snapshots_bag_idx
  on public.gal_decision_snapshots(bag_snapshot_id)
  where bag_snapshot_id is not null;

-- Decision snapshots are immutable evidence: golfer read-only, trusted system insert-only.
revoke all on table public.gal_decision_snapshots from public, anon, authenticated;
grant select on table public.gal_decision_snapshots to authenticated;
revoke all on table public.gal_decision_snapshots from service_role;
grant select, insert on table public.gal_decision_snapshots to service_role;

create or replace function gal_private.gal_validate_decision_audit_links()
returns trigger
language plpgsql
security invoker
set search_path = public, gal_private
as $$
declare
  v_run_user_id uuid;
  v_run_profile_snapshot_id uuid;
  v_run_bag_snapshot_id uuid;
  v_item_user_id uuid;
  v_item_run_id uuid;
  v_item_product_id text;
  v_profile_user_id uuid;
  v_bag_user_id uuid;
  v_link_count integer;
begin
  v_link_count :=
    (case when new.recommendation_run_id is null then 0 else 1 end) +
    (case when new.recommendation_item_id is null then 0 else 1 end) +
    (case when new.profile_snapshot_id is null then 0 else 1 end) +
    (case when new.bag_snapshot_id is null then 0 else 1 end);

  -- Historical legacy rows remain valid with no normalized audit links.
  if v_link_count = 0 then
    return new;
  end if;

  -- New normalized evidence must be complete, not a partially linked chain.
  if v_link_count <> 4 then
    raise exception 'DECISION_AUDIT_LINKS_INCOMPLETE' using errcode = '23514';
  end if;

  select user_id, profile_snapshot_id, bag_snapshot_id
    into v_run_user_id, v_run_profile_snapshot_id, v_run_bag_snapshot_id
  from public.gal_recommendation_runs
  where id = new.recommendation_run_id;

  select user_id, recommendation_run_id, canonical_product_id
    into v_item_user_id, v_item_run_id, v_item_product_id
  from public.gal_recommendation_items
  where id = new.recommendation_item_id;

  select user_id into v_profile_user_id
  from public.gal_profile_snapshots
  where id = new.profile_snapshot_id;

  select user_id into v_bag_user_id
  from public.gal_bag_snapshots
  where id = new.bag_snapshot_id;

  if v_run_user_id is null
     or v_item_user_id is null
     or v_profile_user_id is null
     or v_bag_user_id is null then
    raise exception 'DECISION_AUDIT_LINK_NOT_FOUND' using errcode = '23514';
  end if;

  if new.user_id <> v_run_user_id
     or new.user_id <> v_item_user_id
     or new.user_id <> v_profile_user_id
     or new.user_id <> v_bag_user_id then
    raise exception 'DECISION_AUDIT_OWNERSHIP_MISMATCH' using errcode = '23514';
  end if;

  if v_item_run_id <> new.recommendation_run_id then
    raise exception 'DECISION_AUDIT_ITEM_RUN_MISMATCH' using errcode = '23514';
  end if;

  if v_run_profile_snapshot_id <> new.profile_snapshot_id
     or v_run_bag_snapshot_id <> new.bag_snapshot_id then
    raise exception 'DECISION_AUDIT_FROZEN_SNAPSHOT_MISMATCH' using errcode = '23514';
  end if;

  if new.canonical_product_id is not null
     and v_item_product_id is not null
     and new.canonical_product_id <> v_item_product_id then
    raise exception 'DECISION_AUDIT_PRODUCT_MISMATCH' using errcode = '23514';
  end if;

  return new;
end;
$$;
revoke execute on function gal_private.gal_validate_decision_audit_links() from public, anon, authenticated, service_role;

drop trigger if exists gal_decision_snapshots_validate_audit_links on public.gal_decision_snapshots;
create trigger gal_decision_snapshots_validate_audit_links
before insert or update on public.gal_decision_snapshots
for each row execute function gal_private.gal_validate_decision_audit_links();

comment on column public.gal_decision_snapshots.recommendation_run_id is
  'Optional normalized GI-1.1 audit link. Null preserves pre-GI legacy decision evidence.';
comment on table public.gal_decision_snapshots is
  'Immutable decision evidence. GI-1.1 adds optional links to recommendation item/run and frozen profile/bag snapshots without rewriting legacy rows.';
