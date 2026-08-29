-- GI-1.1 Longitudinal Intelligence Task 3: governed buyer-event invalidation.
-- Buyer events are append-only evidence. The only permitted mutation is adding
-- invalidation metadata; original event semantics remain immutable.

create or replace function gal_private.gal_guard_buyer_event_invalidation_only()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_catalog
as $$
begin
  if row(
    new.id,
    new.event_id,
    new.user_id,
    new.bag_id,
    new.decision_snapshot_id,
    new.event_type,
    new.category,
    new.canonical_product_id,
    new.canonical_brand_id,
    new.product_name,
    new.reason,
    new.metadata,
    new.source_tool,
    new.source_tool_version,
    new.occurred_at,
    new.created_at,
    new.event_version,
    new.session_id,
    new.journey_id,
    new.recommendation_run_id,
    new.signal_class
  ) is distinct from row(
    old.id,
    old.event_id,
    old.user_id,
    old.bag_id,
    old.decision_snapshot_id,
    old.event_type,
    old.category,
    old.canonical_product_id,
    old.canonical_brand_id,
    old.product_name,
    old.reason,
    old.metadata,
    old.source_tool,
    old.source_tool_version,
    old.occurred_at,
    old.created_at,
    old.event_version,
    old.session_id,
    old.journey_id,
    old.recommendation_run_id,
    old.signal_class
  ) then
    raise exception using errcode = '55000', message = 'buyer event semantics are immutable';
  end if;

  if old.invalidated_at is not null and (
    new.invalidated_at is distinct from old.invalidated_at
    or new.invalidation_reason is distinct from old.invalidation_reason
  ) then
    raise exception using errcode = '55000', message = 'buyer event invalidation is immutable once recorded';
  end if;

  if new.invalidated_at is null and new.invalidation_reason is not null then
    raise exception using errcode = '23514', message = 'invalidation reason requires invalidated_at';
  end if;

  if new.invalidated_at is not null and nullif(btrim(new.invalidation_reason), '') is null then
    raise exception using errcode = '23514', message = 'invalidated event requires a reason';
  end if;

  return new;
end;
$$;

revoke execute on function gal_private.gal_guard_buyer_event_invalidation_only() from public, anon, authenticated, service_role;

drop trigger if exists gal_buyer_events_guard_invalidation_only on public.gal_buyer_events;
create trigger gal_buyer_events_guard_invalidation_only
before update on public.gal_buyer_events
for each row execute function gal_private.gal_guard_buyer_event_invalidation_only();

create or replace function public.gal_invalidate_buyer_event(
  p_event_id text,
  p_reason text
)
returns void
language plpgsql
security invoker
set search_path = public, pg_catalog
as $$
declare
  v_rows integer;
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception using errcode = '22023', message = 'invalidation reason is required';
  end if;

  update public.gal_buyer_events
     set invalidated_at = now(),
         invalidation_reason = btrim(p_reason)
   where event_id = p_event_id
     and invalidated_at is null;

  get diagnostics v_rows = row_count;

  if v_rows = 0 then
    if not exists(select 1 from public.gal_buyer_events where event_id = p_event_id) then
      raise exception using errcode = 'P0002', message = 'buyer event not found';
    end if;

    raise exception using errcode = '55000', message = 'buyer event is already invalidated';
  end if;
end;
$$;

revoke execute on function public.gal_invalidate_buyer_event(text,text) from public, anon, authenticated;
grant execute on function public.gal_invalidate_buyer_event(text,text) to service_role;

comment on function public.gal_invalidate_buyer_event(text,text) is
  'Trusted-server path for marking buyer-event telemetry invalid without rewriting original event semantics.';
comment on trigger gal_buyer_events_guard_invalidation_only on public.gal_buyer_events is
  'Enforces append-only buyer-event semantics; only first-write invalidation metadata may change.';
