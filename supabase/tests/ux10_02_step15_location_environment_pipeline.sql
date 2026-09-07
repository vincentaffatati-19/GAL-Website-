begin;

-- Self-contained authenticated golfer; the transaction is rolled back.
do $$
declare
  v_auth uuid := gen_random_uuid();
begin
  insert into auth.users(id) values(v_auth);
  insert into public.gal_users(auth_user_id,preferred_market_code)
  values(v_auth,'STEP15_TEST');
  perform set_config('request.jwt.claim.sub',v_auth::text,true);
end $$;

set local role authenticated;

do $$
declare
  v_json jsonb;
  v_city text;
  v_geonames bigint;
  v_elev numeric;
  v_temp numeric;
  v_wind numeric;
  v_humidity numeric;
  v_precip numeric;
  v_active_derived integer;
  v_retired integer;
  v_revision bigint;
  v_revision_rows integer;
  v_audit_rows integer;
  v_count integer;
begin
  -- Canonical search and region-aware resolution.
  select count(*) into v_count
    from public.gal_search_places('Rh','US',20)
   where city_name='Rhinelander' and geonames_id=5268720;
  if v_count<>1 then raise exception 'Rhinelander search failed'; end if;

  select count(*) into v_count
    from public.gal_resolve_place('IT','Puglia','Bari')
   where geonames_id=3182351;
  if v_count<>1 then raise exception 'Bari canonical resolution failed'; end if;

  -- Authenticated clients cannot mutate the governed place master directly.
  begin
    insert into public.gal_places(geonames_id,country_code,country_name,city_name)
    values(999999999,'US','United States','Illegal Auth Write');
    raise exception 'direct authenticated place write unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;

  -- Governed enrichment: Rhinelander, May-October.
  v_json := public.gal_profile_update_playing_location('US','WI','Rhinelander','may_oct');
  if coalesce((v_json->>'resolved')::boolean,false) is not true
     or coalesce((v_json->>'climateAvailable')::boolean,false) is not true then
    raise exception 'Rhinelander enrichment did not resolve: %',v_json;
  end if;

  select fact_value#>>'{}' into v_city
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='city';
  select (fact_value#>>'{}')::bigint into v_geonames
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='geonamesId';
  select (fact_value#>>'{}')::numeric into v_elev
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='elevationFt';
  select (fact_value#>>'{}')::numeric into v_temp
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalTemperatureF';
  select (fact_value#>>'{}')::numeric into v_wind
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalWindMph';
  select (fact_value#>>'{}')::numeric into v_humidity
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalHumidityPct';
  select (fact_value#>>'{}')::numeric into v_precip
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalPrecipitationInPerDay';

  if v_city<>'Rhinelander' or v_geonames<>5268720 or v_elev<>1549
     or v_temp<>58.0 or v_wind<>9.2 or v_humidity<>78.2 or v_precip<>0.124 then
    raise exception 'Rhinelander active facts mismatch city %, geonames %, elev %, temp %, wind %, humidity %, precip %',
      v_city,v_geonames,v_elev,v_temp,v_wind,v_humidity,v_precip;
  end if;

  -- Changing canonical city retires the old derived environment and appends Bari.
  v_json := public.gal_profile_update_playing_location('IT','Puglia','Bari','year_round');
  if coalesce((v_json->>'resolved')::boolean,false) is not true
     or coalesce((v_json->>'climateAvailable')::boolean,false) is not true then
    raise exception 'Bari enrichment did not resolve: %',v_json;
  end if;

  select fact_value#>>'{}' into v_city
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='city';
  select (fact_value#>>'{}')::bigint into v_geonames
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='geonamesId';
  select (fact_value#>>'{}')::numeric into v_temp
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalTemperatureF';
  select (fact_value#>>'{}')::numeric into v_precip
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='typicalPrecipitationInPerDay';

  if v_city<>'Bari' or v_geonames<>3182351 or v_temp<>62.6 or v_precip<>0.067 then
    raise exception 'Bari active facts mismatch city %, geonames %, temp %, precip %',v_city,v_geonames,v_temp,v_precip;
  end if;

  select count(*) into v_retired
    from public.gal_profile_facts
   where user_id=public.gal_current_user_id()
     and area='play'
     and retired_reason='primary_location_changed'
     and source_type in ('DERIVED_GEOSPATIAL','DERIVED_CLIMATE');
  if v_retired<9 then raise exception 'expected Rhinelander derived facts retired; got %',v_retired; end if;

  -- An unindexed city must save as self-reported location but inherit no old derived facts.
  v_json := public.gal_profile_update_playing_location('US','WI','Unindexed Test City','year_round');
  if coalesce((v_json->>'resolved')::boolean,true) is not false
     or coalesce((v_json->>'climateAvailable')::boolean,true) is not false then
    raise exception 'unindexed city should remain unresolved: %',v_json;
  end if;

  select fact_value#>>'{}' into v_city
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id() and fact_key='city';
  if v_city<>'Unindexed Test City' then raise exception 'unindexed city was not saved: %',v_city; end if;

  select count(*) into v_active_derived
    from public.gal_profile_active_facts_v
   where user_id=public.gal_current_user_id()
     and fact_key in (
       'placeId','geonamesId','latitude','longitude','elevationFt',
       'typicalTemperatureF','typicalWindMph','typicalHumidityPct','typicalPrecipitationInPerDay','seasonality'
     );
  if v_active_derived<>0 then
    raise exception 'stale derived environment leaked into unindexed city: % active rows',v_active_derived;
  end if;

  -- Three calls produce 3 + 3 + 1 governed revisions.
  select profile_revision into v_revision from public.gal_users where id=public.gal_current_user_id();
  select count(*) into v_revision_rows from public.gal_profile_revisions where user_id=public.gal_current_user_id();
  select count(*) into v_audit_rows from public.gal_profile_audit_events where user_id=public.gal_current_user_id();
  if v_revision<>7 or v_revision_rows<>7 or v_audit_rows<>7 then
    raise exception 'revision/audit mismatch revision %, revision_rows %, audit_rows %',v_revision,v_revision_rows,v_audit_rows;
  end if;
end $$;

rollback;
