-- STEP 16 hardening: isolate PostgreSQL HTTP extension in a dedicated non-exposed schema.
create schema if not exists gal_http_private;
revoke all on schema gal_http_private from public, anon, authenticated;

drop extension if exists http;
create extension http with schema gal_http_private;

create or replace function gal_private.gal_refresh_nasa_power_place(p_place_id text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_place public.gal_places%rowtype;
  v_source public.gal_location_sources%rowtype;
  v_url text;
  v_status integer;
  v_content text;
  v_payload jsonb;
  v_season text;
  v_vals record;
  v_env_id text;
  v_count integer := 0;
  v_api_version text;
  v_range text;
  v_ref text;
begin
  select * into v_place from public.gal_places
   where place_id=p_place_id and active and canonical_status='APPROVED';
  if v_place.id is null then raise exception 'approved place not found: %',p_place_id; end if;

  select * into v_source from public.gal_location_sources
   where source_key='NASA_POWER_CLIMATOLOGY_2001_2020' and status='ACTIVE';
  if v_source.id is null then raise exception 'NASA POWER source unavailable'; end if;

  v_url := format(
    'https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=T2M%%2CRH2M%%2CWS10M%%2CPRECTOTCORR&community=AG&longitude=%s&latitude=%s&format=JSON',
    v_place.longitude,v_place.latitude
  );

  select h.status,h.content into v_status,v_content
  from gal_http_private.http_get(v_url::varchar) h;

  if v_status<>200 then raise exception 'NASA POWER HTTP % for %',v_status,p_place_id; end if;
  v_payload := v_content::jsonb;
  if v_payload->'properties'->'parameter'->'T2M' is null then
    raise exception 'NASA POWER payload missing T2M for %',p_place_id;
  end if;

  v_api_version := coalesce(v_payload->'header'->'api'->>'version',v_source.version_label);
  v_range := coalesce(v_payload->'header'->>'range',v_source.temporal_coverage);
  v_ref := v_url;

  foreach v_season in array array['year_round','jan_apr','mar_may','may_oct','jun_aug','sep_nov','nov_apr'] loop
    select * into v_vals from gal_private.gal_power_season_values(v_payload,v_season);
    v_env_id := gal_private.gal_promote_environment_normal(
      v_place.place_id,v_season,'NASA_POWER_CLIMATOLOGY_2001_2020',
      v_vals.typical_temperature_f,v_vals.typical_wind_mph,v_vals.typical_humidity_pct,
      v_vals.typical_precipitation_in_per_day,
      '2001-01-01'::date,'2020-12-31'::date,
      'POWER Climatology API ' || coalesce(v_api_version,'unknown'),
      v_ref,0.88,
      jsonb_build_object(
        'api','POWER Climatology API','apiVersion',v_api_version,'range',v_range,
        'sources',coalesce(v_payload->'header'->'sources','[]'::jsonb),
        'sourceCoordinates',jsonb_build_array(v_place.longitude,v_place.latitude),
        'derivation',v_vals.derivation,'qualityClass','INFERRED_ESTIMATED'
      )
    );
    v_count := v_count+1;
  end loop;

  insert into gal_private.gal_location_ingestion_runs(
    source_id,run_kind,source_version,request_reference,status,started_at,completed_at,
    records_received,records_accepted,records_rejected,notes,metadata
  ) values (
    v_source.id,'CLIMATE_REFRESH','POWER Climatology API ' || coalesce(v_api_version,'unknown'),
    v_ref,'SUCCEEDED',now(),now(),7,7,0,
    'STEP16 scheduled NASA POWER enrichment/refresh',
    jsonb_build_object('placeId',v_place.place_id,'city',v_place.city_name,'derivationMethod','GAL-ENV-DERIVE-1.1')
  );

  return jsonb_build_object('placeId',v_place.place_id,'city',v_place.city_name,'environmentRows',v_count,'apiVersion',v_api_version);
end;
$$;

revoke all on function gal_private.gal_refresh_nasa_power_place(text) from public,anon,authenticated;
grant execute on function gal_private.gal_refresh_nasa_power_place(text) to service_role;
