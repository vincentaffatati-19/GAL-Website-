begin;

-- Self-contained test identity; rolled back at the end.
do $$
declare
  v_auth uuid := gen_random_uuid();
begin
  insert into auth.users(id) values(v_auth);
  insert into public.gal_users(auth_user_id,preferred_market_code)
  values(v_auth,'STEP14_TEST');
  perform set_config('request.jwt.claim.sub',v_auth::text,true);
end $$;

set local role authenticated;

-- Direct profile mutation is prohibited; authenticated clients must use the governed service contract.
do $$
begin
  begin
    insert into public.gal_profile_facts(user_id,fact_key,fact_value,source)
    values(public.gal_current_user_id(),'illegalDirectWrite','1'::jsonb,'test');
    raise exception 'direct authenticated profile write unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
  end;
end $$;

-- 92 self-report -> 97 measured -> 101 later self-report.
select public.gal_profile_apply_patch(
  'measurements','{"driverClubSpeedMph":92}'::jsonb,'{}'::text[],
  'SELF_REPORTED','profile_form','My Golfer Profile',0.75,'global',
  '{"driverClubSpeedMph":"mph"}'::jsonb,clock_timestamp(),'{}'::jsonb,'measurements_updated'
);
select public.gal_profile_apply_patch(
  'measurements','{"driverClubSpeedMph":97}'::jsonb,'{}'::text[],
  'MEASURED','launch_monitor_csv','Approved launch monitor import',1,'global',
  '{"driverClubSpeedMph":"mph"}'::jsonb,clock_timestamp(),
  '{"reference":"step14-test-import"}'::jsonb,'governed_facts_imported'
);
select public.gal_profile_apply_patch(
  'measurements','{"driverClubSpeedMph":101}'::jsonb,'{}'::text[],
  'SELF_REPORTED','profile_form','My Golfer Profile',0.75,'global',
  '{"driverClubSpeedMph":"mph"}'::jsonb,clock_timestamp(),'{}'::jsonb,'measurements_updated'
);

-- Rhinelander derived environment -> golfer override -> switch to Bari.
select public.gal_profile_apply_patch(
  'play','{"city":"Rhinelander"}'::jsonb,'{}'::text[],
  'SELF_REPORTED','profile_form','My Golfer Profile',1,'global','{}'::jsonb,
  clock_timestamp(),'{}'::jsonb,'playing_location_updated'
);
select public.gal_profile_apply_patch(
  'play','{"typicalWindMph":11}'::jsonb,'{}'::text[],
  'INFERRED_ESTIMATED','DERIVED_CLIMATE','Historical climate enrichment',0.82,'global',
  '{"typicalWindMph":"mph"}'::jsonb,clock_timestamp(),'{}'::jsonb,
  'playing_environment_climate_derived'
);
select public.gal_profile_apply_patch(
  'play','{"typicalWindMph":15}'::jsonb,'{}'::text[],
  'SELF_REPORTED','USER_OVERRIDE','Golfer environment override',1,'global',
  '{"typicalWindMph":"mph"}'::jsonb,clock_timestamp(),'{}'::jsonb,
  'playing_environment_user_override'
);
select public.gal_profile_apply_patch(
  'play','{"city":"Bari"}'::jsonb,'{}'::text[],
  'SELF_REPORTED','profile_form','My Golfer Profile',1,'global','{}'::jsonb,
  clock_timestamp(),'{}'::jsonb,'playing_location_updated'
);

do $$
declare
  v_speed numeric;
  v_quality text;
  v_city text;
  v_wind_count integer;
  v_retired_environment integer;
  v_history jsonb;
  v_revision bigint;
  v_revision_rows integer;
  v_audit_rows integer;
  v_snapshot jsonb;
begin
  select (fact_value#>>'{}')::numeric,quality_class::text
    into v_speed,v_quality
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='driverClubSpeedMph';
  if v_speed<>97 or v_quality<>'MEASURED' then
    raise exception 'measured speed must remain active; got % / %',v_speed,v_quality;
  end if;

  select jsonb_agg(jsonb_build_object(
    'value',fact_value,'quality',quality_class,'status',fact_status
  ) order by revision)
    into v_history
    from public.gal_profile_facts
   where user_id=public.gal_current_user_id() and fact_key='driverClubSpeedMph';
  if jsonb_array_length(v_history)<>3 then
    raise exception 'expected three speed history records, got %',v_history;
  end if;
  if (v_history->0->>'status')<>'SUPERSEDED'
     or (v_history->1->>'status')<>'ACTIVE'
     or (v_history->2->>'status')<>'RECORDED_ONLY' then
    raise exception 'unexpected speed lifecycle %',v_history;
  end if;

  select fact_value#>>'{}' into v_city
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='city';
  if v_city<>'Bari' then raise exception 'new same-quality city did not win: %',v_city; end if;

  select count(*) into v_wind_count
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalWindMph';
  if v_wind_count<>0 then
    raise exception 'old location environment leaked into Bari';
  end if;

  select count(*) into v_retired_environment
    from public.gal_profile_facts
   where user_id=public.gal_current_user_id()
     and fact_key='typicalWindMph'
     and fact_status='RETIRED'
     and retired_reason='primary_location_changed';
  if v_retired_environment<>2 then
    raise exception 'expected derived + override wind facts retired, got %',v_retired_environment;
  end if;

  select profile_revision into v_revision
    from public.gal_users where id=public.gal_current_user_id();
  select count(*) into v_revision_rows
    from public.gal_profile_revisions where user_id=public.gal_current_user_id();
  select count(*) into v_audit_rows
    from public.gal_profile_audit_events where user_id=public.gal_current_user_id();
  if v_revision<>7 or v_revision_rows<>7 or v_audit_rows<>7 then
    raise exception 'revision/audit mismatch: revision %, revisions %, audit %',v_revision,v_revision_rows,v_audit_rows;
  end if;

  v_snapshot:=public.gal_profile_snapshot();
  if (v_snapshot->>'revision')::bigint<>7 then
    raise exception 'snapshot revision mismatch: %',v_snapshot;
  end if;
  if not exists (
    select 1 from jsonb_array_elements(v_snapshot->'facts') f
    where f->>'key'='driverClubSpeedMph'
      and (f->'value')::numeric=97
      and f->>'quality'='MEASURED'
  ) then
    raise exception 'snapshot missing authoritative measured speed: %',v_snapshot;
  end if;
end $$;

rollback;
