begin;

do $$
declare
  i integer;
  v_auth uuid;
  v_user uuid;
  v_insight uuid;
  v_insight_public text;
  v_first_user uuid;
  v_first_auth uuid;
  v_second_auth uuid;
  v_verified_outcome text;
  v_snapshot_id text;
  v_reviewer text;
  v_release text;
  v_policy text;
  v_candidate text;
  v_json jsonb;
  v_status text;
  v_candidate_status text;
  v_count integer;
begin
  for i in 1..10 loop
    v_auth:=gen_random_uuid();
    insert into auth.users(id) values(v_auth);
    insert into public.gal_users(auth_user_id,preferred_market_code) values(v_auth,'REMEDIATION_TEST') returning id into v_user;
    if i=1 then v_first_user:=v_user; v_first_auth:=v_auth; end if;
    if i=2 then v_second_auth:=v_auth; end if;

    insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source,recorded_at)
    values(v_user,'ANALYTICS_OPTIONAL','ACCEPTED','remediation-v1','test',now());

    insert into public.gal_insights(
      user_id,insight_domain,insight_code,subject_type,subject_key,scope_key,status,severity,confidence,materiality_score,
      headline,golfer_message,governance_version,signal_count,source_system_count
    ) values(
      v_user,'bag','top_of_bag_gap','bag','active','global','ACKNOWLEDGED','MATERIAL',0.9,0.9,
      'Top-of-bag gap','A verified gap exists at the top of the bag.','remediation-v1',1,1
    ) returning id,insight_id into v_insight,v_insight_public;

    insert into public.gal_insight_outcomes(
      insight_id,user_id,outcome_type,attribution,attribution_confidence,attribution_model_version,
      source_system,source_event_key,occurred_at,evidence
    ) values(
      v_insight,v_user,'recommendation_opened','ASSISTED',0.75,'remediation-v1','remediation_test','opened-'||i,now(),'{}'
    );
  end loop;

  -- Resolution requires qualifying evidence; ordinary engagement cannot resolve the insight.
  select insight_id into v_insight_public from public.gal_insights where user_id=v_first_user;
  begin
    perform public.gal_apply_insight_resolution(
      v_first_user,v_insight_public,'RESOLVED','remediation_test','bad-resolve',
      (select outcome_id from public.gal_insight_outcomes where user_id=v_first_user and outcome_type='recommendation_opened'),
      'bag_gap_closed_verified','1',0.9,'{}',now()
    );
    raise exception 'nonqualifying engagement incorrectly resolved insight';
  exception when others then
    if sqlerrm='nonqualifying engagement incorrectly resolved insight' then raise; end if;
  end;

  select (public.gal_record_insight_outcome(
    v_first_user,v_insight_public,'bag_gap_closed_verified','OBSERVED',0.92,'bag-validator-v1',
    'remediation_test','verified-gap-close',now(),null,null,'{"verified":true}'
  )->>'outcome_id') into v_verified_outcome;

  perform public.gal_apply_insight_resolution(
    v_first_user,v_insight_public,'RESOLVED','remediation_test','resolve-good',v_verified_outcome,
    'bag_gap_closed_verified','1',0.95,'{}',now()
  );
  select status::text into v_status from public.gal_insights where insight_id=v_insight_public;
  if v_status<>'RESOLVED' then raise exception 'qualifying outcome did not resolve insight'; end if;

  perform public.gal_apply_insight_resolution(v_first_user,v_insight_public,'REGRESSED','remediation_test','regress-good',null,null,null,0.9,'{"gap_returned":true}',now());
  select status::text into v_status from public.gal_insights where insight_id=v_insight_public;
  if v_status<>'ACTIVE' then raise exception 'regression did not reopen insight'; end if;

  -- Build a privacy-safe aggregate from ten distinct consenting golfers.
  v_json:=public.gal_build_learning_snapshot(
    'recommendation_opened',now()-interval '1 day',now()+interval '1 day','bag','top_of_bag_gap','bag','active','global',10,'remediation-v1','remediation-v1'
  );
  if (v_json->>'eligible_user_count')::int<>10 or v_json->>'status'<>'DRAFT' then raise exception 'expected 10-user DRAFT snapshot'; end if;
  v_snapshot_id:=v_json->>'learning_snapshot_id';
  perform public.gal_publish_learning_snapshot(v_snapshot_id);

  -- Registered actors and governed evaluation policy are mandatory for learning promotion.
  insert into public.gal_governance_actors(auth_user_id,actor_role,display_name) values(v_first_auth,'REVIEWER','Remediation Reviewer') returning governance_actor_id into v_reviewer;
  insert into public.gal_governance_actors(auth_user_id,actor_role,display_name) values(v_second_auth,'RELEASE_MANAGER','Remediation Release Manager') returning governance_actor_id into v_release;
  select evaluation_policy_id into v_policy from public.gal_learning_evaluation_policies where target_system='recommendation_engine' and target_key='top_of_bag_ranker' and active;

  v_json:=public.gal_create_learning_candidate_v2(v_snapshot_id,'recommendation_engine','top_of_bag_ranker','remediation-test','{"weight_delta":0.02}',v_policy);
  v_candidate:=v_json->>'learning_candidate_id';
  v_json:=public.gal_record_learning_candidate_evaluation_v2(
    v_candidate,v_reviewer,'holdout-remediation-v1',250,'resolution_rate',0.025,
    '{"passed":true,"segments":["handicap_band","swing_speed_band"]}',
    '{"passed":true,"checks":["segment_parity","calibration"]}',
    '{"resolution_rate":0.61}'
  );
  if coalesce((v_json->>'evaluation_passed')::boolean,false) is not true then raise exception 'governed evaluation should pass'; end if;

  begin
    perform public.gal_govern_learning_candidate_v2(v_candidate,'APPROVE',v_reviewer,'must fail');
    raise exception 'reviewer incorrectly approved candidate';
  exception when others then
    if sqlerrm='reviewer incorrectly approved candidate' then raise; end if;
  end;

  perform public.gal_govern_learning_candidate_v2(v_candidate,'APPROVE',v_release,'approved after governed evaluation');
  perform public.gal_govern_learning_candidate_v2(v_candidate,'PROMOTE',v_release,'explicit release promotion');

  -- Withdrawal invalidates the published aggregate and any production candidate derived from it.
  insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source,recorded_at)
  values(v_first_user,'ANALYTICS_OPTIONAL','WITHDRAWN','remediation-v2','test',now()+interval '1 second');
  v_json:=public.gal_reconcile_learning_after_consent_withdrawal(v_first_user,'consent_service','withdraw-remediation-1',now()+interval '2 seconds');
  if (v_json->>'impacted_snapshot_count')::int<>1 then raise exception 'expected one impacted snapshot'; end if;

  select status::text,eligible_user_count into v_status,v_count from public.gal_learning_snapshots where learning_snapshot_id=v_snapshot_id;
  if v_status<>'WITHHELD' or v_count<>9 then raise exception 'snapshot should be WITHHELD at 9 users, got % %',v_status,v_count; end if;
  select status::text into v_candidate_status from public.gal_learning_candidates where learning_candidate_id=v_candidate;
  if v_candidate_status<>'ROLLED_BACK' then raise exception 'derived production candidate was not rolled back'; end if;
  select count(*) into v_count from public.gal_learning_snapshot_contributors where learning_snapshot_id=(select id from public.gal_learning_snapshots where learning_snapshot_id=v_snapshot_id);
  if v_count<>9 then raise exception 'contributor ledger should contain 9 users'; end if;

  v_json:=public.gal_reconcile_learning_after_consent_withdrawal(v_first_user,'consent_service','withdraw-remediation-1',now()+interval '3 seconds');
  if coalesce((v_json->>'idempotent_replay')::boolean,false) is not true then raise exception 'withdrawal replay was not idempotent'; end if;
end $$;

rollback;
