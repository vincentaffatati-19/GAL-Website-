begin;

do $$
declare
  missing_count integer;
begin
  select count(*) into missing_count
  from (values
    ('gal_insight_exposure_events_exposure_idx'),
    ('gal_insight_outcomes_buyer_event_idx'),
    ('gal_insight_outcomes_response_idx'),
    ('gal_insight_responses_buyer_event_idx'),
    ('gal_insight_responses_exposure_idx'),
    ('gal_learning_candidates_snapshot_idx')
  ) expected(index_name)
  where not exists (
    select 1 from pg_indexes i
    where i.schemaname='public' and i.indexname=expected.index_name
  );

  if missing_count <> 0 then
    raise exception 'missing % longitudinal RC FK indexes', missing_count;
  end if;
end;
$$;

rollback;
