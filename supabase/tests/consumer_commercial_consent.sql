begin;

do $$
declare
  v_user1 uuid;
  v_user2 uuid;
begin
  if not exists (
    select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid
    where t.typname='gal_consent_type' and e.enumlabel='COMMERCIAL_AGGREGATE'
  ) then raise exception 'COMMERCIAL_AGGREGATE consent type missing'; end if;

  if has_table_privilege('authenticated','public.gal_commercial_aggregate_eligible_users_v','SELECT') then
    raise exception 'authenticated must not read commercial eligibility view';
  end if;
  if has_table_privilege('anon','public.gal_commercial_aggregate_eligible_users_v','SELECT') then
    raise exception 'anon must not read commercial eligibility view';
  end if;
  if has_table_privilege('authenticated','public.gal_consent_records','UPDATE')
     or has_table_privilege('authenticated','public.gal_consent_records','DELETE') then
    raise exception 'consent history must remain append-only for authenticated users';
  end if;

  select id into v_user1 from public.gal_users order by created_at, id limit 1;
  select id into v_user2 from public.gal_users where id<>v_user1 order by created_at, id limit 1;
  if v_user1 is null or v_user2 is null then raise exception 'two staging users required'; end if;

  insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source,recorded_at) values
    (v_user1,'ANALYTICS_OPTIONAL','ACCEPTED','wave2-test','acceptance',clock_timestamp()+interval '1 minute'),
    (v_user1,'COMMERCIAL_AGGREGATE','ACCEPTED','wave2-test','acceptance',clock_timestamp()+interval '2 minutes'),
    (v_user2,'ANALYTICS_OPTIONAL','ACCEPTED','wave2-test','acceptance',clock_timestamp()+interval '1 minute');

  if not exists (select 1 from public.gal_commercial_aggregate_eligible_users_v where user_id=v_user1) then
    raise exception 'dual opt-in user should be commercially eligible';
  end if;
  if exists (select 1 from public.gal_commercial_aggregate_eligible_users_v where user_id=v_user2) then
    raise exception 'analytics-only user must not be commercially eligible';
  end if;

  insert into public.gal_consent_records(user_id,consent_type,status,policy_version,source,recorded_at)
  values (v_user1,'COMMERCIAL_AGGREGATE','WITHDRAWN','wave2-test','acceptance',clock_timestamp()+interval '3 minutes');

  if exists (select 1 from public.gal_commercial_aggregate_eligible_users_v where user_id=v_user1) then
    raise exception 'latest withdrawal must remove commercial eligibility';
  end if;
end $$;

rollback;
