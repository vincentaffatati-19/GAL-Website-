begin;

do $$
declare
  v_count integer;
  v_json jsonb;
  v_queued integer;
  v_http_schema_anon boolean;
  v_http_schema_auth boolean;
  v_worker_anon boolean;
begin
  select count(*) into v_count
  from public.gal_places
  where active and canonical_status='APPROVED';
  if v_count <> 34 then
    raise exception 'expected 34 approved STEP16 places, got %', v_count;
  end if;

  select count(distinct country_code) into v_count
  from public.gal_places
  where active and canonical_status='APPROVED';
  if v_count <> 10 then
    raise exception 'expected 10 countries, got %', v_count;
  end if;

  select count(*) into v_count
  from public.gal_place_environment_normals
  where is_current and approval_status='APPROVED';
  if v_count <> 238 then
    raise exception 'expected 238 current approved environment rows, got %', v_count;
  end if;

  select count(*) into v_count from public.gal_location_countries();
  if v_count <> 10 then
    raise exception 'gal_location_countries expected 10, got %', v_count;
  end if;

  select count(*) into v_count from public.gal_location_regions('US');
  if v_count <> 8 then
    raise exception 'US region list expected 8, got %', v_count;
  end if;

  select public.gal_location_preview('US','WI','Madison','may_oct') into v_json;
  if coalesce((v_json->>'resolved')::boolean,false) is not true
     or coalesce((v_json->>'climateAvailable')::boolean,false) is not true then
    raise exception 'Madison preview failed: %', v_json;
  end if;
  if (v_json->'place'->>'geonamesId')::bigint <> 5261457
     or (v_json->'environment'->>'temperatureF')::numeric <> 63.4
     or (v_json->'environment'->>'windMph')::numeric <> 9.4
     or (v_json->'environment'->>'humidityPct')::numeric <> 76.3
     or (v_json->'environment'->>'precipitationInPerDay')::numeric <> 0.134 then
    raise exception 'Madison preview values mismatch: %', v_json;
  end if;

  select count(*) into v_count
  from cron.job
  where jobname in ('gal-location-queue-due-refreshes','gal-location-nasa-power-worker');
  if v_count <> 2 then
    raise exception 'expected 2 governed location cron jobs, got %', v_count;
  end if;

  select has_schema_privilege('anon','gal_http_private','USAGE') into v_http_schema_anon;
  select has_schema_privilege('authenticated','gal_http_private','USAGE') into v_http_schema_auth;
  if v_http_schema_anon or v_http_schema_auth then
    raise exception 'client role unexpectedly has usage on gal_http_private';
  end if;

  select has_function_privilege('anon','gal_private.gal_refresh_nasa_power_batch(integer)','EXECUTE') into v_worker_anon;
  if v_worker_anon then
    raise exception 'anon unexpectedly has private refresh-worker execute privilege';
  end if;

  update public.gal_place_environment_normals e
     set retrieved_at = now() - interval '181 days'
    from public.gal_places p
   where e.place_id=p.id
     and p.city_name='Madison'
     and p.country_code='US'
     and e.is_current
     and e.approval_status='APPROVED';

  select gal_private.gal_queue_due_environment_refreshes(interval '180 days') into v_queued;
  if v_queued <> 1 then
    raise exception 'expected exactly one stale-place refresh job, got %', v_queued;
  end if;

  select count(*) into v_count
  from gal_private.gal_location_refresh_jobs j
  join public.gal_places p on p.id=j.place_id
  where p.city_name='Madison' and p.country_code='US'
    and j.status='PENDING';
  if v_count <> 1 then
    raise exception 'expected one pending Madison refresh in transaction, got %', v_count;
  end if;
end $$;

rollback;
