begin;

with u as (select id from public.gal_users limit 1)
insert into public.gal_insights(user_id,insight_domain,insight_code,subject_type,subject_key,scope_key,status,severity,confidence,materiality_score,headline,golfer_message,governance_version)
select id,'bag_composition','task11_verify','bag_zone','top_of_bag','active_bag','ACKNOWLEDGED','HIGH',0.9,0.9,'Test','Test','task11-test' from u;

insert into public.gal_insight_delivery_state(insight_id,user_id,status,presentation_count,last_presented_at,last_surface)
select id,user_id,'ACTED',1,'2026-08-29T17:55:00-06','portal'
from public.gal_insights where insight_code='task11_verify';

insert into public.gal_insight_exposures(insight_id,user_id,surface,status,presentation_count,last_presented_at)
select id,user_id,'portal','ACTED',1,'2026-08-29T17:55:00-06'
from public.gal_insights where insight_code='task11_verify';

insert into public.gal_insight_responses(insight_id,exposure_id,user_id,response_type,surface,source_system,source_event_key,occurred_at)
select i.id,e.id,i.user_id,'ACTED','portal','portal_ui','t11-response','2026-08-29T18:00:00-06'
from public.gal_insights i
join public.gal_insight_exposures e on e.insight_id=i.id and e.surface='portal'
where i.insight_code='task11_verify';

select public.gal_record_insight_outcome(
  (select id from public.gal_users limit 1),
  (select insight_id from public.gal_insights where insight_code='task11_verify'),
  'recommendation_opened','ASSISTED',0.75,'task11-v1','outcome_engine','t11-outcome-1',
  '2026-08-29T18:10:00-06',
  (select response_id from public.gal_insight_responses where source_event_key='t11-response'),
  null,'{"basis":"acted response followed by downstream event"}'
);

select public.gal_record_insight_outcome(
  (select id from public.gal_users limit 1),
  (select insight_id from public.gal_insights where insight_code='task11_verify'),
  'recommendation_opened','ASSISTED',0.75,'task11-v1','outcome_engine','t11-outcome-1',
  '2026-08-29T18:10:00-06',
  (select response_id from public.gal_insight_responses where source_event_key='t11-response'),
  null,'{}'
);

do $$
declare
  v_count integer;
  v_attr text;
  v_conf numeric;
begin
  select count(*),max(attribution::text),max(attribution_confidence)
  into v_count,v_attr,v_conf
  from public.gal_insight_outcomes o
  join public.gal_insights i on i.id=o.insight_id
  where i.insight_code='task11_verify';

  if v_count <> 1 then raise exception 'expected one idempotent outcome, got %',v_count; end if;
  if v_attr <> 'ASSISTED' then raise exception 'attribution mismatch: %',v_attr; end if;
  if v_conf <> 0.75 then raise exception 'confidence mismatch: %',v_conf; end if;
end;
$$;

rollback;
