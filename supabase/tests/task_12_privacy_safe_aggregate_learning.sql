begin;

-- Use one existing golfer, grant transaction-only optional analytics consent,
-- and create many outcomes to prove event volume cannot satisfy the privacy threshold.
insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source,recorded_at)
select id,'ANALYTICS_OPTIONAL','ACCEPTED','task12-test','test','2026-08-29T18:20:00-06'
from public.gal_users
limit 1;

with u as (select id from public.gal_users limit 1)
insert into public.gal_insights(user_id,insight_domain,insight_code,subject_type,subject_key,scope_key,status,severity,confidence,materiality_score,headline,golfer_message,governance_version)
select id,'bag_composition','task12_gap','bag_zone','top_of_bag','active_bag','ACKNOWLEDGED','MATERIAL',.9,.8,'Test','Test','task12-test'
from u;

insert into public.gal_insight_outcomes(
  insight_id,user_id,outcome_type,attribution,attribution_confidence,attribution_model_version,
  source_system,source_event_key,occurred_at
)
select i.id,i.user_id,'recommendation_opened','ASSISTED',.75,'task12-v1','test','evt-'||g,'2026-08-29T18:30:00-06'
from public.gal_insights i
cross join generate_series(1,20) g
where i.insight_code='task12_gap';

select public.gal_build_learning_snapshot(
  'recommendation_opened','2026-08-01','2026-09-01',
  'bag_composition','task12_gap','bag_zone','top_of_bag','active_bag',
  10,'task12-v1','task12-gov'
);

do $$
declare
  v_users integer;
  v_outcomes integer;
  v_status text;
  v_has_user_id boolean;
begin
  select eligible_user_count,outcome_count,status::text,(dimensions ? 'user_id')
  into v_users,v_outcomes,v_status,v_has_user_id
  from public.gal_learning_snapshots
  limit 1;

  if v_users <> 1 then raise exception 'expected 1 distinct eligible golfer, got %',v_users; end if;
  if v_outcomes <> 20 then raise exception 'expected 20 outcome events, got %',v_outcomes; end if;
  if v_status <> 'WITHHELD' then raise exception 'expected WITHHELD, got %',v_status; end if;
  if v_has_user_id then raise exception 'aggregate dimensions must not contain user_id'; end if;

  begin
    perform public.gal_publish_learning_snapshot((select learning_snapshot_id from public.gal_learning_snapshots limit 1));
    raise exception 'publication should have failed';
  exception when others then
    if sqlerrm='publication should have failed' then raise; end if;
  end;
end;
$$;

rollback;
