-- RC14 account-deletion FK-order hotfix.
-- Applied to canonical staging on 2026-10-02 and verified by the
-- active-bag full-erasure regression in tests/e2e.
--
-- Root cause:
-- gal_finalize_account_deletion() deleted public.gal_users first. Cascading
-- gal_bag_items deletion fired gal_private.capture_bag_history_event(), whose
-- BAG_ITEM_REMOVED insert referenced the already-deleted GAL user and violated
-- gal_bag_history_events_user_id_fkey.
--
-- Minimal fix:
-- delete the user's bag items while the GAL user still exists, then continue
-- the existing GAL-user deletion and full-erasure cascades unchanged.

create or replace function public.gal_finalize_account_deletion(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request_id text;
  v_contract text;
  v_counts jsonb;
  v_analytics_status public.gal_consent_status;
  v_analytics_policy text;
  v_commercial_status public.gal_consent_status;
  v_commercial_policy text;
begin
  select r.request_id, r.policy_version
    into v_request_id, v_contract
    from public.gal_account_deletion_requests r
   where r.user_id=p_user_id
     and r.status in ('REQUESTED','PROCESSING')
   order by r.requested_at desc
   limit 1
   for update;

  if v_request_id is null then
    raise exception 'DELETION_REQUEST_REQUIRED';
  end if;

  update public.gal_account_deletion_requests
     set status='PROCESSING', updated_at=now()
   where user_id=p_user_id and request_id=v_request_id;

  select status,policy_version into v_analytics_status,v_analytics_policy
    from public.gal_consent_records
   where user_id=p_user_id and consent_type='ANALYTICS_OPTIONAL'
   order by recorded_at desc,id desc limit 1;

  if v_analytics_status='ACCEPTED' then
    insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source)
    values(p_user_id,'ANALYTICS_OPTIONAL','WITHDRAWN',v_analytics_policy,'account_deletion');
    v_analytics_status:='WITHDRAWN';
  end if;

  if v_analytics_status is not null then
    perform public.gal_reconcile_learning_after_consent_withdrawal(
      p_user_id,
      'account_deletion',
      v_request_id,
      now()
    );
  end if;

  select status,policy_version into v_commercial_status,v_commercial_policy
    from public.gal_consent_records
   where user_id=p_user_id and consent_type='COMMERCIAL_AGGREGATE'
   order by recorded_at desc,id desc limit 1;

  if v_commercial_status='ACCEPTED' then
    insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source)
    values(p_user_id,'COMMERCIAL_AGGREGATE','WITHDRAWN',v_commercial_policy,'account_deletion');
  end if;

  select jsonb_build_object(
    'profileFacts',(select count(*) from public.gal_profile_facts where user_id=p_user_id),
    'bags',(select count(*) from public.gal_bags where user_id=p_user_id),
    'bagItems',(select count(*) from public.gal_bag_items where user_id=p_user_id),
    'buyerEvents',(select count(*) from public.gal_buyer_events where user_id=p_user_id),
    'decisionSnapshots',(select count(*) from public.gal_decision_snapshots where user_id=p_user_id),
    'insights',(select count(*) from public.gal_insights where user_id=p_user_id),
    'consentRecords',(select count(*) from public.gal_consent_records where user_id=p_user_id)
  ) into v_counts;

  insert into public.gal_deletion_completion_audit(request_id,contract_version,completion_mode,metadata)
  values(v_request_id,coalesce(v_contract,'RC14-DELETION-CONTRACT-1.0'),'FULL_ERASURE',jsonb_build_object('preDeleteCounts',v_counts));

  delete from public.gal_bag_items where user_id=p_user_id;

  delete from public.gal_users where id=p_user_id;
  if not found then raise exception 'GAL_USER_NOT_FOUND'; end if;

  return jsonb_build_object('ok',true,'requestId',v_request_id,'mode','FULL_ERASURE');
end;
$function$;
