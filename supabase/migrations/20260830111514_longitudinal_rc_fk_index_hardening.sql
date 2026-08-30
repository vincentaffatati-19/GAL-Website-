create index if not exists gal_insight_exposure_events_exposure_idx
  on public.gal_insight_exposure_events(exposure_id)
  where exposure_id is not null;

create index if not exists gal_insight_outcomes_buyer_event_idx
  on public.gal_insight_outcomes(buyer_event_id)
  where buyer_event_id is not null;

create index if not exists gal_insight_outcomes_response_idx
  on public.gal_insight_outcomes(response_id)
  where response_id is not null;

create index if not exists gal_insight_responses_buyer_event_idx
  on public.gal_insight_responses(buyer_event_id)
  where buyer_event_id is not null;

create index if not exists gal_insight_responses_exposure_idx
  on public.gal_insight_responses(exposure_id);

create index if not exists gal_learning_candidates_snapshot_idx
  on public.gal_learning_candidates(learning_snapshot_id);
