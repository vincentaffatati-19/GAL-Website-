-- GI-1.1 Longitudinal Intelligence Task 2
-- Extend the existing canonical gal_buyer_events stream. Do not create a parallel behavior table.

alter table public.gal_buyer_events
  add column event_version text,
  add column session_id text,
  add column journey_id text,
  add column recommendation_run_id uuid,
  add column signal_class text,
  add column invalidated_at timestamptz,
  add column invalidation_reason text;

-- Backfill only events that can be mapped unambiguously to the governed EVENT-1.0 catalog.
update public.gal_buyer_events e
set event_version = c.event_version,
    signal_class = c.signal_class
from public.gal_event_catalog c
where c.event_key = e.event_type
  and c.event_version = 'EVENT-1.0'
  and c.status = 'ACTIVE'
  and c.is_active = true;

-- Fail closed if any legacy row cannot be reconciled to the canonical event vocabulary.
do $$
begin
  if exists (
    select 1
    from public.gal_buyer_events
    where event_version is null or signal_class is null
  ) then
    raise exception 'GI-1.1 buyer-event migration blocked: one or more existing events are not compatible with EVENT-1.0';
  end if;
end;
$$;

alter table public.gal_buyer_events
  alter column event_version set not null,
  alter column signal_class set not null,
  add constraint gal_buyer_events_event_catalog_fk
    foreign key (event_type, event_version)
    references public.gal_event_catalog(event_key, event_version),
  add constraint gal_buyer_events_recommendation_run_fk
    foreign key (recommendation_run_id)
    references public.gal_recommendation_runs(id) on delete set null,
  add constraint gal_buyer_events_signal_class_check
    check (signal_class in ('NAVIGATION','ENGAGEMENT','INTENT','COMMITMENT','OUTCOME')),
  add constraint gal_buyer_events_invalidation_pair_check
    check ((invalidated_at is null and invalidation_reason is null)
        or (invalidated_at is not null and nullif(btrim(invalidation_reason),'') is not null));

create index gal_buyer_events_user_session_time_idx
  on public.gal_buyer_events(user_id, session_id, occurred_at)
  where session_id is not null;

create index gal_buyer_events_user_journey_time_idx
  on public.gal_buyer_events(user_id, journey_id, occurred_at)
  where journey_id is not null;

create index gal_buyer_events_recommendation_run_idx
  on public.gal_buyer_events(recommendation_run_id)
  where recommendation_run_id is not null;

-- Browser behavior history is append-only. Preserve self SELECT/INSERT policies, but
-- explicitly remove mutation privileges even if inherited/default grants change.
revoke update, delete on table public.gal_buyer_events from authenticated;
grant select, insert on table public.gal_buyer_events to authenticated;

comment on table public.gal_buyer_events is
  'Canonical append-only golfer behavior stream. Behavior is evidence, not automatically profile truth.';
comment on column public.gal_buyer_events.event_version is
  'Version of the governed gal_event_catalog definition used for this event.';
comment on column public.gal_buyer_events.signal_class is
  'Governed evidence-strength class copied from the event catalog at event creation.';
comment on column public.gal_buyer_events.invalidated_at is
  'Trusted invalidation timestamp; semantic event fields remain historical evidence.';
