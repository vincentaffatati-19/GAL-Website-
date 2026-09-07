-- GAL UX10.02 STEP 16 — Location Coverage Expansion & Governed Refresh Pipeline
-- Staging review candidate only. Builds on STEP 15.

create extension if not exists http with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

-- Direct HTTP use is internal-only. The refresh worker below runs as its privileged owner.
do $$
begin
  revoke execute on function extensions.http_get(character varying) from public, anon, authenticated;
exception when undefined_function then null;
end $$;
do $$
begin
  revoke execute on function extensions.http_get(character varying, jsonb) from public, anon, authenticated;
exception when undefined_function then null;
end $$;

create table if not exists gal_private.gal_location_refresh_jobs (
  id uuid primary key default gen_random_uuid(),
  job_id text not null unique default public.gal_public_id('GAL-LRJ'),
  place_id uuid not null references public.gal_places(id) on delete cascade,
  source_id uuid not null references public.gal_location_sources(id),
  job_kind text not null default 'CLIMATE_REFRESH'
    check (job_kind in ('CLIMATE_SEED','CLIMATE_REFRESH')),
  reason text not null,
  status text not null default 'PENDING'
    check (status in ('PENDING','RUNNING','SUCCEEDED','FAILED','CANCELLED')),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  scheduled_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  last_error text,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists gal_location_refresh_jobs_place_idx
  on gal_private.gal_location_refresh_jobs(place_id);
create index if not exists gal_location_refresh_jobs_source_idx
  on gal_private.gal_location_refresh_jobs(source_id);
create index if not exists gal_location_refresh_jobs_pending_idx
  on gal_private.gal_location_refresh_jobs(status,scheduled_at,created_at)
  where status='PENDING';
create unique index if not exists gal_location_refresh_jobs_one_open_idx
  on gal_private.gal_location_refresh_jobs(place_id,source_id)
  where status in ('PENDING','RUNNING');

revoke all on table gal_private.gal_location_refresh_jobs from public, anon, authenticated;
grant select,insert,update,delete on table gal_private.gal_location_refresh_jobs to service_role;

create table if not exists gal_private.gal_location_sync_state (
  source_id uuid primary key references public.gal_location_sources(id) on delete cascade,
  dataset_marker text,
  last_checked_at timestamptz,
  last_success_at timestamptz,
  last_full_import_at timestamptz,
  full_import_record_count integer,
  last_delta_date date,
  status text not null default 'READY' check (status in ('READY','RUNNING','DEGRADED','FAILED')),
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

revoke all on table gal_private.gal_location_sync_state from public, anon, authenticated;
grant select,insert,update,delete on table gal_private.gal_location_sync_state to service_role;

insert into gal_private.gal_location_sync_state(source_id,dataset_marker,last_checked_at,status,metadata)
select id,'GeoNames cities5000 directory snapshot 2026-09-06',now(),'READY',
       '{"targetDataset":"cities5000","estimatedCoverage":"~50,000 populated places","bulkImportStatus":"READY_FOR_OPERATOR_LOAD"}'::jsonb
from public.gal_location_sources
where source_key='GEONAMES_PLACE_MASTER'
on conflict (source_id) do update set
  dataset_marker=excluded.dataset_marker,
  last_checked_at=excluded.last_checked_at,
  status=excluded.status,
  metadata=gal_private.gal_location_sync_state.metadata || excluded.metadata,
  updated_at=now();

-- Expand the live staging master to every location already approved in UX10.02 STEP 13.1.
-- Existing STEP 15 source-verified seed rows are preserved unchanged.
with src as (
  select id from public.gal_location_sources where source_key='GEONAMES_PLACE_MASTER'
), seed(geonames_id,country_code,country_name,region_code,region_name,city_name,latitude,longitude,elevation_m,fixture_seasonality) as (
  values
    (5268720,'US','United States','WI','Wisconsin','Rhinelander',45.6366,-89.4121,472,'Cool-climate / shorter primary golf season'),
    (5261457,'US','United States','WI','Wisconsin','Madison',43.0731,-89.4012,266,'Four-season / warm-humid summer golf'),
    (5263045,'US','United States','WI','Wisconsin','Milwaukee',43.0389,-87.9065,188,'Great Lakes / four-season golf'),
    (4887398,'US','United States','IL','Illinois','Chicago',41.8781,-87.6298,181,'Four-season / lake-influenced conditions'),
    (5308655,'US','United States','AZ','Arizona','Phoenix',33.4484,-112.074,331,'Desert / winter-peak golf season'),
    (5313457,'US','United States','AZ','Arizona','Scottsdale',33.4942,-111.9261,383,'Desert / winter-peak golf season'),
    (5364079,'US','United States','CA','California','La Quinta',33.6634,-116.31,17,'Low-desert / winter-peak golf season'),
    (5380668,'US','United States','CA','California','Palm Springs',33.8303,-116.5453,146,'Low-desert / winter-peak golf season'),
    (5391811,'US','United States','CA','California','San Diego',32.7157,-117.1611,19,'Mild coastal / year-round golf'),
    (5374361,'US','United States','CA','California','Monterey',36.6002,-121.8947,8,'Cool coastal / marine influence'),
    (5419384,'US','United States','CO','Colorado','Denver',39.7392,-104.9903,1609,'High elevation / dry four-season climate'),
    (4167147,'US','United States','FL','Florida','Orlando',28.5383,-81.3792,25,'Warm-humid / year-round golf'),
    (4167519,'US','United States','FL','Florida','Palm Beach Gardens',26.8234,-80.1387,5,'Subtropical / year-round golf'),
    (5231851,'US','United States','SD','South Dakota','Sioux Falls',43.5446,-96.7311,449,'Continental / windy shoulder seasons'),
    (5233053,'US','United States','SD','South Dakota','Yankton',42.8711,-97.3973,367,'Continental / prairie wind influence'),
    (5074472,'US','United States','NE','Nebraska','Omaha',41.2565,-95.9345,332,'Continental / warm summer, windy shoulder seasons'),
    (6167865,'CA','Canada','ON','Ontario','Toronto',43.6532,-79.3832,76,'Great Lakes / four-season golf'),
    (6173331,'CA','Canada','BC','British Columbia','Vancouver',49.2827,-123.1207,70,'Marine / mild wet winters'),
    (3169070,'IT','Italy','Lazio','Lazio','Rome',41.9028,12.4964,21,'Mediterranean / long playing season'),
    (3182351,'IT','Italy','Puglia','Puglia','Bari',41.1171,16.8719,5,'Mediterranean coastal / breezy'),
    (3176959,'IT','Italy','Tuscany','Tuscany','Florence',43.7696,11.2558,50,'Mediterranean-continental transition'),
    (264371,'GR','Greece','Attica','Attica','Athens',37.9838,23.7275,70,'Mediterranean / hot dry summer'),
    (261745,'GR','Greece','Crete','Crete','Heraklion',35.3387,25.1442,39,'Mediterranean island / wind-exposed'),
    (3117735,'ES','Spain','Madrid','Community of Madrid','Madrid',40.4168,-3.7038,667,'High plateau / dry with large seasonal swing'),
    (3128760,'ES','Spain','Catalonia','Catalonia','Barcelona',41.3874,2.1686,12,'Mediterranean coastal / long season'),
    (2514256,'ES','Spain','Andalusia','Andalusia','Málaga',36.7213,-4.4214,11,'Mediterranean / mild winter golf'),
    (2267057,'PT','Portugal','Lisbon','Lisbon','Lisbon',38.7223,-9.1393,2,'Atlantic-Mediterranean / breezy year-round'),
    (2268337,'PT','Portugal','Algarve','Algarve','Faro',37.0194,-7.9304,6,'Atlantic-Mediterranean / mild winter golf'),
    (2638864,'GB','United Kingdom','Scotland','Scotland','St Andrews',56.3398,-2.7967,12,'Cool maritime / wind-exposed links environment'),
    (2643743,'GB','United Kingdom','England','England','London',51.5074,-0.1278,11,'Temperate maritime / year-round variability'),
    (2964574,'IE','Ireland','Leinster','Leinster','Dublin',53.3498,-6.2603,20,'Cool maritime / wind and moisture influence'),
    (2158177,'AU','Australia','VIC','Victoria','Melbourne',-37.8136,144.9631,31,'Temperate / changeable coastal influence'),
    (2147714,'AU','Australia','NSW','New South Wales','Sydney',-33.8688,151.2093,58,'Warm coastal / year-round golf'),
    (2193733,'NZ','New Zealand','Auckland','Auckland Region','Auckland',-36.8485,174.7633,79,'Marine / mild, humid and changeable')
)
insert into public.gal_places(
  geonames_id,country_code,country_name,region_code,region_name,city_name,
  latitude,longitude,elevation_m,elevation_source,source_name,source_reference,
  source_checked_at,active,source_id,source_version,feature_class,canonical_status,provenance
)
select s.geonames_id,s.country_code,s.country_name,s.region_code,s.region_name,s.city_name,
       s.latitude,s.longitude,s.elevation_m,'GeoNames / UX13.1 staged elevation','GeoNames',
       'https://www.geonames.org/' || s.geonames_id::text || '/',
       now(),true,src.id,'UX10.02 STEP13.1 approved location index; bulk-dump reconciliation pending',
       'P','APPROVED',
       jsonb_build_object(
         'promotionScope','STAGING_ONLY',
         'seedOrigin','UX10.02 STEP13.1 approved location index',
         'fixtureSeasonality',s.fixture_seasonality,
         'bulkDumpReconciliationRequired',true,
         'coordinateSystem','WGS84',
         'license','CC BY 4.0'
       )
from seed s cross join src
on conflict (geonames_id) do nothing;

-- Public lookup helpers for the live Country -> Region -> City control.
create or replace function public.gal_location_countries()
returns table(country_code text,country_name text,place_count bigint)
language sql
stable
security invoker
set search_path=''
as $$
  select p.country_code,max(p.country_name),count(*)
  from public.gal_places p
  where p.active and p.canonical_status='APPROVED'
  group by p.country_code
  order by max(p.country_name);
$$;

create or replace function public.gal_location_regions(p_country_code text)
returns table(region_code text,region_name text,place_count bigint)
language sql
stable
security invoker
set search_path=''
as $$
  select coalesce(p.region_code,p.region_name),max(coalesce(p.region_name,p.region_code)),count(*)
  from public.gal_places p
  where p.active and p.canonical_status='APPROVED'
    and upper(p.country_code)=upper(trim(p_country_code))
  group by coalesce(p.region_code,p.region_name)
  order by max(coalesce(p.region_name,p.region_code));
$$;

create or replace function public.gal_location_preview(
  p_country_code text,
  p_region text,
  p_city text,
  p_season_code text default 'year_round'
)
returns jsonb
language plpgsql
stable
security invoker
set search_path=''
as $$
declare
  v_place record;
  v_env record;
begin
  select * into v_place from public.gal_resolve_place(p_country_code,p_region,p_city);
  if v_place.place_id is null then
    return jsonb_build_object('resolved',false,'climateAvailable',false,'reason','PLACE_NOT_FOUND');
  end if;
  select * into v_env from public.gal_location_environment(v_place.place_id,p_season_code);
  return jsonb_build_object(
    'resolved',true,
    'place',jsonb_build_object(
      'placeId',v_place.place_id,'geonamesId',v_place.geonames_id,
      'countryCode',v_place.country_code,'countryName',v_place.country_name,
      'regionCode',v_place.region_code,'regionName',v_place.region_name,
      'cityName',v_place.city_name,'latitude',v_place.latitude,'longitude',v_place.longitude,
      'elevationM',v_place.elevation_m,'elevationFt',case when v_place.elevation_m is null then null else round(v_place.elevation_m*3.280839895,0) end,
      'sourceName',v_place.source_name,'sourceReference',v_place.source_reference,
      'sourceVersion',v_place.source_version,'provenance',v_place.provenance
    ),
    'seasonCode',p_season_code,
    'climateAvailable',(v_env.environment_id is not null),
    'environment',case when v_env.environment_id is null then null else jsonb_build_object(
      'environmentId',v_env.environment_id,
      'temperatureF',v_env.typical_temperature_f,
      'windMph',v_env.typical_wind_mph,
      'humidityPct',v_env.typical_humidity_pct,
      'precipitationInPerDay',v_env.typical_precipitation_in,
      'seasonality',v_env.seasonality,
      'sourceName',v_env.source_name,'sourceReference',v_env.source_reference,
      'sourceCheckedAt',v_env.source_checked_at,'confidence',v_env.confidence,'provenance',v_env.provenance
    ) end
  );
end;
$$;

revoke all on function public.gal_location_countries() from public;
revoke all on function public.gal_location_regions(text) from public;
revoke all on function public.gal_location_preview(text,text,text,text) from public;
grant execute on function public.gal_location_countries() to anon,authenticated;
grant execute on function public.gal_location_regions(text) to anon,authenticated;
grant execute on function public.gal_location_preview(text,text,text,text) to anon,authenticated;

-- NASA POWER seasonal derivation helper.
create or replace function gal_private.gal_power_season_values(
  p_payload jsonb,
  p_season_code text
)
returns table(
  typical_temperature_f numeric,
  typical_wind_mph numeric,
  typical_humidity_pct numeric,
  typical_precipitation_in_per_day numeric,
  derivation jsonb
)
language plpgsql
immutable
security invoker
set search_path=''
as $$
declare
  v_months text[];
  v_days integer[];
  v_i integer;
  v_total_days numeric := 0;
  v_t numeric := 0;
  v_w numeric := 0;
  v_h numeric := 0;
  v_p numeric := 0;
  v_ann_t numeric;
  v_ann_w numeric;
  v_ann_h numeric;
  v_ann_p numeric;
begin
  if p_season_code='year_round' then
    v_ann_t := (p_payload->'properties'->'parameter'->'T2M'->>'ANN')::numeric;
    v_ann_w := (p_payload->'properties'->'parameter'->'WS10M'->>'ANN')::numeric;
    v_ann_h := (p_payload->'properties'->'parameter'->'RH2M'->>'ANN')::numeric;
    v_ann_p := (p_payload->'properties'->'parameter'->'PRECTOTCORR'->>'ANN')::numeric;
    return query select
      round((v_ann_t*9/5+32)::numeric,1),
      round((v_ann_w*2.236936292)::numeric,1),
      round(v_ann_h,1),
      round((v_ann_p/25.4)::numeric,3),
      jsonb_build_object('method','NASA POWER ANN climatology','methodVersion','GAL-ENV-DERIVE-1.1');
    return;
  end if;

  case p_season_code
    when 'jan_apr' then v_months:=array['JAN','FEB','MAR','APR']; v_days:=array[31,28,31,30];
    when 'mar_may' then v_months:=array['MAR','APR','MAY']; v_days:=array[31,30,31];
    when 'may_oct' then v_months:=array['MAY','JUN','JUL','AUG','SEP','OCT']; v_days:=array[31,30,31,31,30,31];
    when 'jun_aug' then v_months:=array['JUN','JUL','AUG']; v_days:=array[30,31,31];
    when 'sep_nov' then v_months:=array['SEP','OCT','NOV']; v_days:=array[30,31,30];
    when 'nov_apr' then v_months:=array['NOV','DEC','JAN','FEB','MAR','APR']; v_days:=array[30,31,31,28,31,30];
    else raise exception 'unsupported season code: %',p_season_code using errcode='22023';
  end case;

  for v_i in 1..array_length(v_months,1) loop
    v_total_days := v_total_days + v_days[v_i];
    v_t := v_t + (p_payload->'properties'->'parameter'->'T2M'->>v_months[v_i])::numeric * v_days[v_i];
    v_w := v_w + (p_payload->'properties'->'parameter'->'WS10M'->>v_months[v_i])::numeric * v_days[v_i];
    v_h := v_h + (p_payload->'properties'->'parameter'->'RH2M'->>v_months[v_i])::numeric * v_days[v_i];
    v_p := v_p + (p_payload->'properties'->'parameter'->'PRECTOTCORR'->>v_months[v_i])::numeric * v_days[v_i];
  end loop;

  return query select
    round(((v_t/v_total_days)*9/5+32)::numeric,1),
    round(((v_w/v_total_days)*2.236936292)::numeric,1),
    round((v_h/v_total_days)::numeric,1),
    round(((v_p/v_total_days)/25.4)::numeric,3),
    jsonb_build_object(
      'method','day-weighted mean of NASA POWER monthly climatology',
      'methodVersion','GAL-ENV-DERIVE-1.1',
      'months',to_jsonb(v_months),
      'weightDays',to_jsonb(v_days)
    );
end;
$$;

create or replace function gal_private.gal_queue_due_environment_refreshes(
  p_stale_after interval default interval '180 days'
)
returns integer
language plpgsql
security definer
set search_path=''
as $$
declare
  v_source uuid;
  v_count integer := 0;
begin
  select id into v_source from public.gal_location_sources
   where source_key='NASA_POWER_CLIMATOLOGY_2001_2020' and status='ACTIVE';
  if v_source is null then raise exception 'NASA POWER source unavailable'; end if;

  insert into gal_private.gal_location_refresh_jobs(place_id,source_id,job_kind,reason)
  select p.id,v_source,
         case when not exists (
           select 1 from public.gal_place_environment_normals e
           where e.place_id=p.id and e.is_current and e.approval_status='APPROVED'
         ) then 'CLIMATE_SEED' else 'CLIMATE_REFRESH' end,
         case when not exists (
           select 1 from public.gal_place_environment_normals e
           where e.place_id=p.id and e.is_current and e.approval_status='APPROVED'
         ) then 'missing_environment' else 'stale_environment' end
  from public.gal_places p
  where p.active and p.canonical_status='APPROVED'
    and (
      not exists (
        select 1 from public.gal_place_environment_normals e
        where e.place_id=p.id and e.is_current and e.approval_status='APPROVED'
      )
      or coalesce((
        select max(e.retrieved_at) from public.gal_place_environment_normals e
        where e.place_id=p.id and e.is_current and e.approval_status='APPROVED'
      ),'-infinity'::timestamptz) < now()-p_stale_after
    )
    and not exists (
      select 1 from gal_private.gal_location_refresh_jobs j
      where j.place_id=p.id and j.source_id=v_source and j.status in ('PENDING','RUNNING')
    );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

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
  from extensions.http_get(v_url::varchar) h;

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

create or replace function gal_private.gal_refresh_nasa_power_batch(p_limit integer default 5)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_job record;
  v_ok integer := 0;
  v_failed integer := 0;
  v_result jsonb;
begin
  for v_job in
    select j.id,j.job_id,p.place_id
    from gal_private.gal_location_refresh_jobs j
    join public.gal_places p on p.id=j.place_id
    where j.status='PENDING' and j.scheduled_at<=now()
    order by j.created_at
    for update of j skip locked
    limit greatest(1,least(coalesce(p_limit,5),10))
  loop
    update gal_private.gal_location_refresh_jobs
       set status='RUNNING',attempt_count=attempt_count+1,started_at=now(),updated_at=now(),last_error=null
     where id=v_job.id;
    begin
      v_result := gal_private.gal_refresh_nasa_power_place(v_job.place_id);
      update gal_private.gal_location_refresh_jobs
         set status='SUCCEEDED',completed_at=now(),updated_at=now(),result=v_result
       where id=v_job.id;
      v_ok := v_ok+1;
    exception when others then
      update gal_private.gal_location_refresh_jobs
         set status=case when attempt_count>=3 then 'FAILED' else 'PENDING' end,
             scheduled_at=case when attempt_count>=3 then scheduled_at else now()+interval '30 minutes' end,
             last_error=left(sqlerrm,2000),updated_at=now(),
             completed_at=case when attempt_count>=3 then now() else null end
       where id=v_job.id;
      v_failed := v_failed+1;
    end;
  end loop;
  return jsonb_build_object('succeeded',v_ok,'failed',v_failed);
end;
$$;

revoke all on function gal_private.gal_power_season_values(jsonb,text) from public,anon,authenticated;
revoke all on function gal_private.gal_queue_due_environment_refreshes(interval) from public,anon,authenticated;
revoke all on function gal_private.gal_refresh_nasa_power_place(text) from public,anon,authenticated;
revoke all on function gal_private.gal_refresh_nasa_power_batch(integer) from public,anon,authenticated;
grant execute on function gal_private.gal_queue_due_environment_refreshes(interval) to service_role;
grant execute on function gal_private.gal_refresh_nasa_power_place(text) to service_role;
grant execute on function gal_private.gal_refresh_nasa_power_batch(integer) to service_role;

-- Queue any currently missing environments immediately.
select gal_private.gal_queue_due_environment_refreshes(interval '180 days');

-- Governed refresh schedules. Worker is bounded to five places/run.
do $$
declare v_jobid bigint;
begin
  select jobid into v_jobid from cron.job where jobname='gal-location-queue-due-refreshes' limit 1;
  if v_jobid is not null then perform cron.unschedule(v_jobid); end if;
  perform cron.schedule(
    'gal-location-queue-due-refreshes',
    '5 3 * * *',
    'select gal_private.gal_queue_due_environment_refreshes(interval ''180 days'');'
  );

  select jobid into v_jobid from cron.job where jobname='gal-location-nasa-power-worker' limit 1;
  if v_jobid is not null then perform cron.unschedule(v_jobid); end if;
  perform cron.schedule(
    'gal-location-nasa-power-worker',
    '17 * * * *',
    'select gal_private.gal_refresh_nasa_power_batch(5);'
  );
end $$;

comment on table gal_private.gal_location_refresh_jobs is
  'Internal governed queue for provider enrichment/refresh. No client role access.';
comment on function public.gal_location_preview(text,text,text,text) is
  'Anonymous-safe preview of an approved place and approved current environment normal for the Where You Play UI.';
comment on function gal_private.gal_refresh_nasa_power_batch(integer) is
  'Bounded internal worker for NASA POWER climatology refresh with retries and ingestion provenance.';
