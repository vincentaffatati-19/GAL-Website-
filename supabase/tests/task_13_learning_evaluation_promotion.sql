begin;

insert into public.gal_learning_snapshots(
  cohort_key,status,outcome_type,dimensions,window_start,window_end,minimum_cohort_size,
  eligible_user_count,outcome_count,observed_count,assisted_count,direct_declared_count,
  average_attribution_confidence,aggregation_version,governance_version,published_at
) values(
  'task13-published','PUBLISHED','recommendation_opened','{}','2026-01-01','2026-08-01',10,
  100,150,40,90,20,0.72,'1','1',now()
);

select public.gal_create_learning_candidate(
  (select learning_snapshot_id from public.gal_learning_snapshots where cohort_key='task13-published'),
  'recommendation_engine','top_of_bag_ranker','v13-test','{"weight_delta":0.08}',100,0.01
);

-- A failing evaluation must never become approvable.
select public.gal_record_learning_candidate_evaluation(
  (select learning_candidate_id from public.gal_learning_candidates where candidate_version='v13-test'),
  'holdout-v1',50,-0.02,true,false,'{"auc":0.61}'
);

do $$
declare
  v_pass boolean;
  v_status text;
begin
  select evaluation_passed,status::text into v_pass,v_status
  from public.gal_learning_candidates where candidate_version='v13-test';
  if v_pass then raise exception 'failing evaluation incorrectly passed'; end if;
  if v_status <> 'EVALUATED' then raise exception 'unexpected failing evaluation status: %',v_status; end if;

  begin
    perform public.gal_govern_learning_candidate(
      (select learning_candidate_id from public.gal_learning_candidates where candidate_version='v13-test'),
      'APPROVE','task13-verifier','should fail'
    );
    raise exception 'approval unexpectedly succeeded for failing evaluation';
  exception when others then
    if sqlerrm = 'approval unexpectedly succeeded for failing evaluation' then raise; end if;
  end;
end;
$$;

-- A passing reevaluation clears all required offline gates.
select public.gal_record_learning_candidate_evaluation(
  (select learning_candidate_id from public.gal_learning_candidates where candidate_version='v13-test'),
  'holdout-v2',250,0.035,false,true,'{"auc":0.69,"calibration_delta":0.01}'
);

select public.gal_govern_learning_candidate(
  (select learning_candidate_id from public.gal_learning_candidates where candidate_version='v13-test'),
  'APPROVE','task13-verifier','offline gates passed'
);

select public.gal_govern_learning_candidate(
  (select learning_candidate_id from public.gal_learning_candidates where candidate_version='v13-test'),
  'PROMOTE','task13-verifier','explicit promotion'
);

do $$
declare
  v_status text;
  v_pass boolean;
  v_holdout integer;
  v_delta numeric;
  v_bias boolean;
  v_regression boolean;
begin
  select status::text,evaluation_passed,holdout_sample_size,primary_metric_delta,bias_check_passed,regression_detected
  into v_status,v_pass,v_holdout,v_delta,v_bias,v_regression
  from public.gal_learning_candidates where candidate_version='v13-test';

  if v_status <> 'PRODUCTION' then raise exception 'candidate did not reach PRODUCTION: %',v_status; end if;
  if not v_pass then raise exception 'production candidate does not have passing evaluation'; end if;
  if v_holdout <> 250 then raise exception 'holdout mismatch: %',v_holdout; end if;
  if v_delta <> 0.035 then raise exception 'primary metric delta mismatch: %',v_delta; end if;
  if not v_bias then raise exception 'bias check did not pass'; end if;
  if v_regression then raise exception 'regression flag unexpectedly true'; end if;
end;
$$;

select public.gal_govern_learning_candidate(
  (select learning_candidate_id from public.gal_learning_candidates where candidate_version='v13-test'),
  'ROLLBACK','task13-verifier','rollback verification'
);

do $$
declare
  v_status text;
  v_reason text;
begin
  select status::text,rollback_reason into v_status,v_reason
  from public.gal_learning_candidates where candidate_version='v13-test';
  if v_status <> 'ROLLED_BACK' then raise exception 'rollback failed: %',v_status; end if;
  if v_reason <> 'rollback verification' then raise exception 'rollback reason mismatch'; end if;
end;
$$;

rollback;
