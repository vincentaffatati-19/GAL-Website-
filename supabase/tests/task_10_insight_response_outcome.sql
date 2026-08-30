begin;

-- Create four governed insights and prior portal exposures to exercise each response path.
with u as (select id from public.gal_users limit 1)
insert into public.gal_insights(user_id,insight_domain,insight_code,subject_type,subject_key,scope_key,status,severity,confidence,materiality_score,headline,golfer_message,governance_version)
select id,'bag_composition','task10_snooze','bag_zone','top_of_bag','active_bag','ACTIVE','HIGH',0.9,0.9,'Snooze test','Test','task10-test' from u
union all
select id,'bag_composition','task10_dismiss','bag_zone','wedge_gap','active_bag','ACTIVE','MATERIAL',0.9,0.8,'Dismiss test','Test','task10-test' from u
union all
select id,'bag_composition','task10_ack','bag_zone','mid_bag','active_bag','ACTIVE','MATERIAL',0.9,0.8,'Ack test','Test','task10-test' from u
union all
select id,'bag_composition','task10_acted','bag_zone','putter','active_bag','ACTIVE','MATERIAL',0.9,0.8,'Acted test','Test','task10-test' from u;

insert into public.gal_insight_delivery_state(insight_id,user_id,status,presentation_count,last_presented_at,next_global_eligible_at,last_surface)
select id,user_id,'COOLDOWN',1,'2026-08-29T18:00:00-06','2026-09-05T18:00:00-06','portal'
from public.gal_insights where insight_code like 'task10_%';

insert into public.gal_insight_exposures(insight_id,user_id,surface,status,presentation_count,last_presented_at,next_surface_eligible_at)
select id,user_id,'portal','COOLDOWN',1,'2026-08-29T18:00:00-06','2026-09-05T18:00:00-06'
from public.gal_insights where insight_code like 'task10_%';

select public.gal_record_insight_response(
  (select id from public.gal_users limit 1),(select insight_id from public.gal_insights where insight_code='task10_snooze'),
  'portal','SNOOZED','portal_ui','t10-snooze-1','2026-08-29T18:02:00-06','2026-09-15T09:00:00-06',null,'{}');
select public.gal_record_insight_response(
  (select id from public.gal_users limit 1),(select insight_id from public.gal_insights where insight_code='task10_snooze'),
  'portal','SNOOZED','portal_ui','t10-snooze-1','2026-08-29T18:03:00-06','2026-09-15T09:00:00-06',null,'{}');

select public.gal_record_insight_response(
  (select id from public.gal_users limit 1),(select insight_id from public.gal_insights where insight_code='task10_dismiss'),
  'portal','NOT_RELEVANT','portal_ui','t10-dismiss-1','2026-08-29T18:04:00-06',null,null,'{"reason":"not useful"}');

select public.gal_record_insight_response(
  (select id from public.gal_users limit 1),(select insight_id from public.gal_insights where insight_code='task10_ack'),
  'portal','ACKNOWLEDGED','portal_ui','t10-ack-1','2026-08-29T18:05:00-06',null,null,'{}');

select public.gal_record_insight_response(
  (select id from public.gal_users limit 1),(select insight_id from public.gal_insights where insight_code='task10_acted'),
  'portal','ACTED','portal_ui','t10-acted-1','2026-08-29T18:06:00-06',null,null,'{"action":"opened_recommendation"}');

do $$
declare
  v_count integer;
  v_status text;
  v_ts timestamptz;
begin
  select count(*) into v_count from public.gal_insight_responses r join public.gal_insights i on i.id=r.insight_id where i.insight_code='task10_snooze';
  if v_count <> 1 then raise exception 'snooze replay was not idempotent: %',v_count; end if;

  select d.status::text,d.snoozed_until into v_status,v_ts from public.gal_insight_delivery_state d join public.gal_insights i on i.id=d.insight_id where i.insight_code='task10_snooze';
  if v_status <> 'COOLDOWN' or v_ts <> '2026-09-15T09:00:00-06'::timestamptz then raise exception 'snooze state mismatch'; end if;

  select d.status::text into v_status from public.gal_insight_delivery_state d join public.gal_insights i on i.id=d.insight_id where i.insight_code='task10_dismiss';
  if v_status <> 'DISMISSED' then raise exception 'dismiss state mismatch: %',v_status; end if;

  select status::text into v_status from public.gal_insights where insight_code='task10_ack';
  if v_status <> 'ACKNOWLEDGED' then raise exception 'ack insight state mismatch: %',v_status; end if;

  select d.status::text into v_status from public.gal_insight_delivery_state d join public.gal_insights i on i.id=d.insight_id where i.insight_code='task10_acted';
  if v_status <> 'ACTED' then raise exception 'acted delivery state mismatch: %',v_status; end if;
  select status::text into v_status from public.gal_insights where insight_code='task10_acted';
  if v_status <> 'ACKNOWLEDGED' then raise exception 'acted insight state mismatch: %',v_status; end if;
end;
$$;

rollback;
