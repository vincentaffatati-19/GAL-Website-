begin;

insert into public.gal_insights(
  user_id,insight_domain,insight_code,subject_type,subject_key,scope_key,
  status,severity,confidence,materiality_score,headline,golfer_message,governance_version
)
select id,'bag_composition','task9_verify_gap','bag_zone','top_of_bag','active_bag',
       'ACTIVE','HIGH',0.9,0.9,'Test gap','Test governed message','task9-test'
from public.gal_users
limit 1;

select public.gal_record_insight_presentation(
  (select id from public.gal_users limit 1),
  (select insight_id from public.gal_insights where insight_code='task9_verify_gap'),
  'portal','portal_renderer','t9-001','2026-08-29T18:00:00-06',168,168,'{}'
);

select public.gal_record_insight_presentation(
  (select id from public.gal_users limit 1),
  (select insight_id from public.gal_insights where insight_code='task9_verify_gap'),
  'email','email_engine','t9-002','2026-08-29T18:05:00-06',168,168,'{}'
);

select public.gal_record_insight_presentation(
  (select id from public.gal_users limit 1),
  (select insight_id from public.gal_insights where insight_code='task9_verify_gap'),
  'portal','portal_renderer','t9-001','2026-08-29T18:06:00-06',168,168,'{}'
);

select public.gal_record_insight_presentation(
  (select id from public.gal_users limit 1),
  (select insight_id from public.gal_insights where insight_code='task9_verify_gap'),
  'email','email_engine','t9-003','2026-09-06T18:01:00-06',168,168,'{}'
);

do $$
declare
  v_delivery_rows integer;
  v_surface_rows integer;
  v_presented integer;
  v_blocked integer;
  v_global_presentations integer;
begin
  select count(*) into v_delivery_rows
  from public.gal_insight_delivery_state d
  join public.gal_insights i on i.id=d.insight_id
  where i.insight_code='task9_verify_gap';

  select count(*) into v_surface_rows
  from public.gal_insight_exposures e
  join public.gal_insights i on i.id=e.insight_id
  where i.insight_code='task9_verify_gap';

  select count(*) filter(where e.event_type='PRESENTED'),
         count(*) filter(where e.event_type='BLOCKED_COOLDOWN')
  into v_presented,v_blocked
  from public.gal_insight_exposure_events e
  join public.gal_insights i on i.id=e.insight_id
  where i.insight_code='task9_verify_gap';

  select d.presentation_count into v_global_presentations
  from public.gal_insight_delivery_state d
  join public.gal_insights i on i.id=d.insight_id
  where i.insight_code='task9_verify_gap';

  if v_delivery_rows <> 1 then raise exception 'expected 1 delivery row, got %',v_delivery_rows; end if;
  if v_surface_rows <> 2 then raise exception 'expected 2 surface rows, got %',v_surface_rows; end if;
  if v_presented <> 2 then raise exception 'expected 2 presented events, got %',v_presented; end if;
  if v_blocked <> 1 then raise exception 'expected 1 blocked cooldown event, got %',v_blocked; end if;
  if v_global_presentations <> 2 then raise exception 'expected 2 global presentations, got %',v_global_presentations; end if;
end;
$$;

rollback;
