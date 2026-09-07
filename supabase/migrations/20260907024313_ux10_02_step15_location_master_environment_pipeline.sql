-- GAL UX10.02 STEP 15 — Governed Location Master & Environment Enrichment Pipeline
-- Staging only. Builds on STEP 14 profile service contracts.

create schema if not exists gal_private;

do $$ begin
  create type public.gal_location_source_status as enum ('ACTIVE','REVIEW_ONLY','RETIRED');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.gal_environment_approval_status as enum ('CANDIDATE','APPROVED','WITHHELD','RETIRED');
exception when duplicate_object then null;
end $$;

create table if not exists public.gal_location_sources (
  id uuid primary key default gen_random_uuid(),
  source_id text not null unique default public.gal_public_id('GAL-SRC'),
  source_key text not null unique,
  provider_name text not null,
  dataset_name text not null,
  source_kind text not null check (source_kind in ('PLACE_MASTER','CLIMATE_NORMALS','VALIDATION_REFERENCE')),
  canonical_url text not null,
  license_name text,
  license_url text,
  attribution_text text,
  reference_guidance text,
  coverage_scope text,
  version_label text,
  temporal_coverage text,
  status public.gal_location_source_status not null default 'ACTIVE',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.gal_location_sources enable row level security;
drop policy if exists gal_location_sources_public_select on public.gal_location_sources;
create policy gal_location_sources_public_select on public.gal_location_sources
  for select to anon, authenticated
  using (status='ACTIVE');

revoke all on table public.gal_location_sources from anon, authenticated;
grant select on table public.gal_location_sources to anon, authenticated;

alter table public.gal_places
  add column if not exists source_id uuid references public.gal_location_sources(id),
  add column if not exists source_version text,
  add column if not exists feature_class text,
  add column if not exists feature_code text,
  add column if not exists canonical_status text not null default 'APPROVED',
  add column if not exists provenance jsonb not null default '{}'::jsonb;

alter table public.gal_places
  drop constraint if exists gal_places_canonical_status_check;
alter table public.gal_places
  add constraint gal_places_canonical_status_check
  check (canonical_status in ('CANDIDATE','APPROVED','WITHHELD','RETIRED'));

create index if not exists gal_places_source_idx on public.gal_places(source_id);

drop policy if exists gal_places_public_select on public.gal_places;
create policy gal_places_public_select on public.gal_places
  for select to anon, authenticated
  using (active and canonical_status='APPROVED');

revoke insert,update,delete,truncate,references,trigger on table public.gal_places from anon, authenticated;
grant select on table public.gal_places to anon, authenticated;

alter table public.gal_place_environment_normals
  add column if not exists source_id uuid references public.gal_location_sources(id),
  add column if not exists source_version text,
  add column if not exists approval_status public.gal_environment_approval_status not null default 'CANDIDATE',
  add column if not exists derivation_method text,
  add column if not exists method_version text,
  add column if not exists raw_parameter_units jsonb not null default '{}'::jsonb,
  add column if not exists source_payload_hash text,
  add column if not exists retrieved_at timestamptz not null default now();

create index if not exists gal_place_environment_source_idx on public.gal_place_environment_normals(source_id);
create index if not exists gal_place_environment_place_idx on public.gal_place_environment_normals(place_id);

drop policy if exists gal_environment_public_select on public.gal_place_environment_normals;
create policy gal_environment_public_select on public.gal_place_environment_normals
  for select to anon, authenticated
  using (is_current and approval_status='APPROVED');

revoke insert,update,delete,truncate,references,trigger on table public.gal_place_environment_normals from anon, authenticated;
grant select on table public.gal_place_environment_normals to anon, authenticated;

create table if not exists gal_private.gal_location_ingestion_runs (
  id uuid primary key default gen_random_uuid(),
  ingestion_id text not null unique default public.gal_public_id('GAL-ING'),
  source_id uuid not null references public.gal_location_sources(id),
  run_kind text not null check (run_kind in ('PLACE_SEED','PLACE_REFRESH','CLIMATE_SEED','CLIMATE_REFRESH','VALIDATION')),
  source_version text,
  request_reference text,
  status text not null check (status in ('STARTED','SUCCEEDED','FAILED','PARTIAL')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  records_received integer not null default 0 check (records_received >= 0),
  records_accepted integer not null default 0 check (records_accepted >= 0),
  records_rejected integer not null default 0 check (records_rejected >= 0),
  source_payload_hash text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

revoke all on table gal_private.gal_location_ingestion_runs from public, anon, authenticated;
grant select,insert,update,delete on table gal_private.gal_location_ingestion_runs to service_role;

insert into public.gal_location_sources(
  source_key,provider_name,dataset_name,source_kind,canonical_url,license_name,license_url,
  attribution_text,reference_guidance,coverage_scope,version_label,temporal_coverage,status,metadata
) values
(
  'GEONAMES_PLACE_MASTER','GeoNames','GeoNames Geographical Database','PLACE_MASTER',
  'https://www.geonames.org/','Creative Commons Attribution 4.0','https://creativecommons.org/licenses/by/4.0/',
  'Contains GeoNames data, licensed under CC BY 4.0.',
  'Credit GeoNames when location data is displayed or redistributed.',
  'Global populated places','Daily database / web reference','Current geographic reference','ACTIVE',
  '{"coordinateSystem":"WGS84","role":"canonical_place_identity"}'::jsonb
),
(
  'NASA_POWER_CLIMATOLOGY_2001_2020','NASA POWER','POWER Climatology API','CLIMATE_NORMALS',
  'https://power.larc.nasa.gov/','NASA POWER referencing guidance','https://power.larc.nasa.gov/docs/referencing/',
  'Data obtained from NASA Langley Research Center POWER project.',
  'Include POWER service name, version and access date when publishing POWER-derived data.',
  'Global meteorological grid','POWER Climatology API v2.9.7','January 2001 - December 2020','ACTIVE',
  '{"api":"POWER Climatology API","apiVersion":"v2.9.7","sources":["MERRA2","POWER"],"timeStandard":"LST","meteorologyResolution":"0.5 degree latitude x 0.625 degree longitude"}'::jsonb
)
on conflict (source_key) do update set
  provider_name=excluded.provider_name,
  dataset_name=excluded.dataset_name,
  source_kind=excluded.source_kind,
  canonical_url=excluded.canonical_url,
  license_name=excluded.license_name,
  license_url=excluded.license_url,
  attribution_text=excluded.attribution_text,
  reference_guidance=excluded.reference_guidance,
  coverage_scope=excluded.coverage_scope,
  version_label=excluded.version_label,
  temporal_coverage=excluded.temporal_coverage,
  status=excluded.status,
  metadata=excluded.metadata,
  updated_at=now();

with src as (
  select id from public.gal_location_sources where source_key='GEONAMES_PLACE_MASTER'
), seed(geonames_id,country_code,country_name,region_code,region_name,city_name,latitude,longitude,timezone,population,elevation_m,feature_class,feature_code,source_reference,source_region_name) as (
  values
    (5268720::bigint,'US','United States','WI','Wisconsin','Rhinelander',45.6366228::numeric,-89.4120753::numeric,'America/Chicago',7526::bigint,472::numeric,'P','PPLA2','https://www.geonames.org/5268720/rhinelander.html','Wisconsin'),
    (4887398,'US','United States','IL','Illinois','Chicago',41.85003,-87.65005,'America/Chicago',2664452,179,'P','PPLA2','https://www.geonames.org/4887398/chicago.html','Illinois'),
    (5233053,'US','United States','SD','South Dakota','Yankton',42.8711088,-97.3972813,'America/Chicago',14557,368,'P','PPLA2','https://www.geonames.org/5233053/yankton.html','South Dakota'),
    (3169070,'IT','Italy','07','Lazio','Rome',41.8919341,12.5113261,'Europe/Rome',2318895,20,'P','PPLC','https://www.geonames.org/3169070/rome.html','Lazio'),
    (3182351,'IT','Italy','13','Puglia','Bari',41.12066,16.86982,'Europe/Rome',316491,5,'P','PPLA','https://www.geonames.org/3182351/bari.html','Apulia'),
    (264371,'GR','Greece','ESYE31','Attica','Athens',37.98376,23.72784,'Europe/Athens',664046,70,'P','PPLC','https://www.geonames.org/264371/athens.html','Attica')
)
insert into public.gal_places(
  geonames_id,country_code,country_name,region_code,region_name,city_name,latitude,longitude,timezone,population,
  elevation_m,elevation_source,source_name,source_reference,source_checked_at,active,source_id,source_version,
  feature_class,feature_code,canonical_status,provenance
)
select s.geonames_id,s.country_code,s.country_name,s.region_code,s.region_name,s.city_name,s.latitude,s.longitude,s.timezone,s.population,
       s.elevation_m,'GeoNames populated-place elevation','GeoNames',s.source_reference,now(),true,src.id,'GeoNames web reference checked 2026-09-06',
       s.feature_class,s.feature_code,'APPROVED',
       jsonb_build_object('sourceRegionName',s.source_region_name,'license','CC BY 4.0','coordinateSystem','WGS84','verifiedForStep','UX10.02 STEP15')
from seed s cross join src
on conflict (geonames_id) do update set
  country_code=excluded.country_code,country_name=excluded.country_name,region_code=excluded.region_code,region_name=excluded.region_name,
  city_name=excluded.city_name,latitude=excluded.latitude,longitude=excluded.longitude,timezone=excluded.timezone,population=excluded.population,
  elevation_m=excluded.elevation_m,elevation_source=excluded.elevation_source,source_name=excluded.source_name,
  source_reference=excluded.source_reference,source_checked_at=excluded.source_checked_at,active=true,source_id=excluded.source_id,
  source_version=excluded.source_version,feature_class=excluded.feature_class,feature_code=excluded.feature_code,
  canonical_status='APPROVED',provenance=excluded.provenance,updated_at=now();

-- Seed provider-derived climate normals. Values are deterministic conversions from NASA POWER
-- Climatology API v2.9.7 (2001-2020) retrieved during STEP 15 staging validation.
-- Temperature C -> F; wind m/s -> mph; precipitation mm/day -> in/day.
-- Multi-month seasons use day-weighted means of monthly climatology; year_round uses ANN.
with src as (
  select id from public.gal_location_sources where source_key='NASA_POWER_CLIMATOLOGY_2001_2020'
), climate(city_name,season_code,temp_f,wind_mph,humidity_pct,precip_in_day) as (
  values
  ('Athens','year_round',64.1,10.0,68.5,0.054),('Athens','jan_apr',52.4,10.2,77.7,0.068),('Athens','mar_may',59.9,9.1,70.3,0.044),('Athens','may_oct',74.8,9.6,59.0,0.030),('Athens','jun_aug',79.9,9.9,53.3,0.017),('Athens','sep_nov',66.6,9.8,69.8,0.064),('Athens','nov_apr',53.3,10.3,78.2,0.079),
  ('Bari','year_round',62.6,10.0,71.9,0.067),('Bari','jan_apr',51.6,11.1,78.3,0.071),('Bari','mar_may',58.5,10.2,74.0,0.063),('Bari','may_oct',72.7,9.0,64.6,0.055),('Bari','jun_aug',78.0,8.8,58.9,0.039),('Bari','sep_nov',64.6,9.6,74.3,0.089),('Bari','nov_apr',52.2,11.1,79.2,0.079),
  ('Chicago','year_round',49.7,12.6,80.8,0.106),('Chicago','jan_apr',33.9,14.2,83.2,0.084),('Chicago','mar_may',44.4,12.5,81.6,0.117),('Chicago','may_oct',63.9,10.8,78.6,0.129),('Chicago','jun_aug',70.0,9.4,78.6,0.130),('Chicago','sep_nov',54.5,13.4,77.6,0.106),('Chicago','nov_apr',35.2,14.5,83.0,0.082),
  ('Rhinelander','year_round',40.7,10.1,83.0,0.093),('Rhinelander','jan_apr',22.5,11.3,87.3,0.062),('Rhinelander','mar_may',39.4,10.8,79.0,0.096),('Rhinelander','may_oct',58.0,9.2,78.2,0.124),('Rhinelander','jun_aug',65.0,8.6,77.8,0.130),('Rhinelander','sep_nov',43.9,10.0,81.8,0.099),('Rhinelander','nov_apr',23.0,11.0,87.9,0.062),
  ('Rome','year_round',60.7,7.4,70.3,0.083),('Rome','jan_apr',49.5,7.9,77.1,0.090),('Rome','mar_may',57.3,7.7,72.3,0.078),('Rome','may_oct',71.4,7.0,62.6,0.063),('Rome','jun_aug',77.0,6.9,57.0,0.037),('Rome','sep_nov',62.6,7.3,72.0,0.115),('Rome','nov_apr',49.8,7.9,78.2,0.104),
  ('Yankton','year_round',49.2,11.5,68.5,0.072),('Yankton','jan_apr',32.4,12.4,72.7,0.047),('Yankton','mar_may',48.4,12.5,66.4,0.086),('Yankton','may_oct',66.5,10.8,63.3,0.102),('Yankton','jun_aug',74.5,9.9,62.7,0.110),('Yankton','sep_nov',50.6,11.5,66.1,0.066),('Yankton','nov_apr',31.7,12.1,73.8,0.042)
), labels(season_code,label) as (
  values ('year_round','Year-round'),('jan_apr','January-April'),('mar_may','March-May'),('may_oct','May-October'),('jun_aug','June-August'),('sep_nov','September-November'),('nov_apr','November-April')
)
insert into public.gal_place_environment_normals(
  place_id,season_code,typical_temperature_f,typical_wind_mph,typical_humidity_pct,typical_precipitation_in,
  seasonality,period_start,period_end,source_name,source_reference,source_checked_at,confidence,provenance,is_current,
  source_id,source_version,approval_status,derivation_method,method_version,raw_parameter_units,retrieved_at
)
select p.id,c.season_code,c.temp_f,c.wind_mph,c.humidity_pct,c.precip_in_day,
       l.label || ' NASA POWER climatology','2001-01-01'::date,'2020-12-31'::date,'NASA POWER',
       format('https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=T2M%%2CRH2M%%2CWS10M%%2CPRECTOTCORR&community=AG&longitude=%s&latitude=%s&format=JSON',p.longitude,p.latitude),
       now(),0.88,
       jsonb_build_object(
         'api','POWER Climatology API','apiVersion','v2.9.7','range','January 2001 - December 2020',
         'sources',jsonb_build_array('MERRA2','POWER'),
         'derivation','year_round uses ANN; multi-month seasons use day-weighted means of monthly climatology',
         'precipitationBasis','average daily precipitation rate over selected season',
         'sourceCoordinates',jsonb_build_array(p.longitude,p.latitude),
         'qualityClass','INFERRED_ESTIMATED'
       ),true,src.id,'POWER Climatology API v2.9.7','APPROVED',
       'Deterministic unit conversion and day-weighted seasonal aggregation','GAL-ENV-DERIVE-1.0',
       '{"T2M":"C","RH2M":"%","WS10M":"m/s","PRECTOTCORR":"mm/day","storedTemperature":"F","storedWind":"mph","storedPrecipitation":"in/day"}'::jsonb,
       now()
from climate c
join public.gal_places p on p.city_name=c.city_name and p.canonical_status='APPROVED'
join labels l on l.season_code=c.season_code
cross join src
where not exists (
  select 1 from public.gal_place_environment_normals e
  where e.place_id=p.id and e.season_code=c.season_code and e.is_current
);

insert into gal_private.gal_location_ingestion_runs(
  source_id,run_kind,source_version,request_reference,status,started_at,completed_at,
  records_received,records_accepted,records_rejected,notes,metadata
)
select id,'PLACE_SEED','GeoNames web reference checked 2026-09-06','UX10.02 STEP15 governed seed','SUCCEEDED',now(),now(),6,6,0,
       'Six priority UX locations verified against GeoNames and promoted to the governed place master.',
       '{"step":"UX10.02 STEP15","seedScope":"priority_review_locations"}'::jsonb
from public.gal_location_sources where source_key='GEONAMES_PLACE_MASTER'
union all
select id,'CLIMATE_SEED','POWER Climatology API v2.9.7','NASA POWER climatology point API','SUCCEEDED',now(),now(),42,42,0,
       'Six places x seven playing-season views promoted from NASA POWER 2001-2020 climatology.',
       '{"step":"UX10.02 STEP15","derivationMethod":"GAL-ENV-DERIVE-1.0"}'::jsonb
from public.gal_location_sources where source_key='NASA_POWER_CLIMATOLOGY_2001_2020';

create or replace function public.gal_search_places(
  p_query text,
  p_country_code text default null,
  p_limit integer default 20
)
returns table(
  place_id text, geonames_id bigint, country_code text, country_name text,
  region_code text, region_name text, city_name text, latitude numeric,
  longitude numeric, elevation_m numeric, timezone text, source_name text,
  source_reference text
)
language sql
stable
security invoker
set search_path=''
as $$
  select p.place_id,p.geonames_id,p.country_code,p.country_name,p.region_code,p.region_name,p.city_name,
         p.latitude,p.longitude,p.elevation_m,p.timezone,p.source_name,p.source_reference
  from public.gal_places p
  where p.active and p.canonical_status='APPROVED'
    and (p_country_code is null or upper(p.country_code)=upper(p_country_code))
    and (coalesce(trim(p_query),'')='' or lower(p.city_name) like lower(trim(p_query)) || '%')
  order by
    case when lower(p.city_name)=lower(trim(coalesce(p_query,''))) then 0 else 1 end,
    p.population desc nulls last,
    p.city_name
  limit greatest(1,least(coalesce(p_limit,20),50));
$$;

create or replace function public.gal_resolve_place(
  p_country_code text,
  p_region text,
  p_city text
)
returns table(
  place_id text, geonames_id bigint, country_code text, country_name text,
  region_code text, region_name text, city_name text, latitude numeric,
  longitude numeric, elevation_m numeric, timezone text, source_name text,
  source_reference text, source_checked_at timestamptz, source_version text, provenance jsonb
)
language sql
stable
security invoker
set search_path=''
as $$
  select p.place_id,p.geonames_id,p.country_code,p.country_name,p.region_code,p.region_name,p.city_name,
         p.latitude,p.longitude,p.elevation_m,p.timezone,p.source_name,p.source_reference,p.source_checked_at,
         p.source_version,p.provenance
  from public.gal_places p
  where p.active and p.canonical_status='APPROVED'
    and upper(p.country_code)=upper(trim(p_country_code))
    and lower(p.city_name)=lower(trim(p_city))
    and (
      coalesce(trim(p_region),'')='' or
      lower(coalesce(p.region_code,''))=lower(trim(p_region)) or
      lower(coalesce(p.region_name,''))=lower(trim(p_region)) or
      lower(coalesce(p.provenance->>'sourceRegionName',''))=lower(trim(p_region))
    )
  order by p.population desc nulls last
  limit 1;
$$;

create or replace function public.gal_location_environment(p_place_id text,p_season_code text)
returns table(
  place_id text, environment_id text, season_code text,
  typical_temperature_f numeric, typical_wind_mph numeric, typical_humidity_pct numeric,
  typical_precipitation_in numeric, seasonality text, source_name text,
  source_reference text, source_checked_at timestamptz, confidence numeric, provenance jsonb
)
language sql
stable
security invoker
set search_path=''
as $$
  select p.place_id,e.environment_id,e.season_code,e.typical_temperature_f,e.typical_wind_mph,
         e.typical_humidity_pct,e.typical_precipitation_in,e.seasonality,e.source_name,e.source_reference,
         e.source_checked_at,e.confidence,e.provenance
  from public.gal_places p
  join public.gal_place_environment_normals e on e.place_id=p.id
  where p.active and p.canonical_status='APPROVED'
    and e.is_current and e.approval_status='APPROVED'
    and p.place_id=p_place_id and e.season_code=p_season_code
  limit 1;
$$;

create or replace function public.gal_profile_update_playing_location(
  p_country_code text,
  p_region text,
  p_city text,
  p_season_code text default 'year_round'
)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_place record;
  v_env record;
  v_location jsonb;
  v_geo jsonb;
  v_climate jsonb;
  v_season_label text;
  v_region_name text;
  v_country_name text;
begin
  if public.gal_current_user_id() is null then
    raise exception 'authenticated GAL user required' using errcode='42501';
  end if;

  v_season_label := case p_season_code
    when 'year_round' then 'Year-round'
    when 'jan_apr' then 'January-April'
    when 'mar_may' then 'March-May'
    when 'may_oct' then 'May-October'
    when 'jun_aug' then 'June-August'
    when 'sep_nov' then 'September-November'
    when 'nov_apr' then 'November-April'
    else null end;
  if v_season_label is null then
    raise exception 'unsupported playing season: %',p_season_code using errcode='22023';
  end if;

  select * into v_place from public.gal_resolve_place(p_country_code,p_region,p_city);
  v_country_name := coalesce(v_place.country_name,upper(trim(p_country_code)));
  v_region_name := coalesce(v_place.region_name,nullif(trim(p_region),''));

  v_location := public.gal_profile_apply_patch(
    'play',
    jsonb_strip_nulls(jsonb_build_object(
      'country',v_country_name,'countryCode',upper(trim(p_country_code)),
      'region',v_region_name,'regionCode',nullif(trim(p_region),''),
      'city',trim(p_city),'playingMonths',v_season_label
    )),
    '{}'::text[],
    'SELF_REPORTED'::public.gal_profile_quality,
    'profile_form','My Golfer Profile - Where You Play',1,'global','{}'::jsonb,now(),
    jsonb_build_object('service','gal_profile_update_playing_location','seasonCode',p_season_code),
    'playing_location_updated'
  );

  if v_place.place_id is null then
    return jsonb_build_object(
      'resolved',false,'climateAvailable',false,'reason','PLACE_NOT_FOUND',
      'locationPatch',v_location,'seasonCode',p_season_code
    );
  end if;

  v_geo := public.gal_profile_apply_patch(
    'play',
    jsonb_strip_nulls(jsonb_build_object(
      'placeId',v_place.place_id,'geonamesId',v_place.geonames_id,
      'latitude',v_place.latitude,'longitude',v_place.longitude,
      'elevationFt',case when v_place.elevation_m is null then null else round(v_place.elevation_m*3.280839895,0) end
    )),
    '{}'::text[],
    'INFERRED_ESTIMATED'::public.gal_profile_quality,
    'DERIVED_GEOSPATIAL','GeoNames governed place master',0.95,'global',
    '{"latitude":"°","longitude":"°","elevationFt":"ft"}'::jsonb,now(),
    jsonb_build_object(
      'provider','GeoNames','placeId',v_place.place_id,'geonamesId',v_place.geonames_id,
      'sourceReference',v_place.source_reference,'sourceCheckedAt',v_place.source_checked_at,
      'sourceVersion',v_place.source_version,'providerProvenance',v_place.provenance
    ),
    'playing_environment_geospatial_derived'
  );

  select * into v_env from public.gal_location_environment(v_place.place_id,p_season_code);
  if v_env.environment_id is null then
    return jsonb_build_object(
      'resolved',true,'placeId',v_place.place_id,'climateAvailable',false,
      'locationPatch',v_location,'geospatialPatch',v_geo,'seasonCode',p_season_code
    );
  end if;

  v_climate := public.gal_profile_apply_patch(
    'play',
    jsonb_strip_nulls(jsonb_build_object(
      'typicalTemperatureF',v_env.typical_temperature_f,
      'typicalWindMph',v_env.typical_wind_mph,
      'typicalHumidityPct',v_env.typical_humidity_pct,
      'typicalPrecipitationInPerDay',v_env.typical_precipitation_in,
      'seasonality',v_env.seasonality
    )),
    '{}'::text[],
    'INFERRED_ESTIMATED'::public.gal_profile_quality,
    'DERIVED_CLIMATE','NASA POWER governed climate enrichment',v_env.confidence,'global',
    '{"typicalTemperatureF":"°F","typicalWindMph":"mph","typicalHumidityPct":"%","typicalPrecipitationInPerDay":"in/day"}'::jsonb,now(),
    jsonb_build_object(
      'provider','NASA POWER','environmentId',v_env.environment_id,
      'sourceReference',v_env.source_reference,'sourceCheckedAt',v_env.source_checked_at,
      'environmentProvenance',v_env.provenance
    ),
    'playing_environment_climate_derived'
  );

  return jsonb_build_object(
    'resolved',true,'placeId',v_place.place_id,'geonamesId',v_place.geonames_id,
    'climateAvailable',true,'seasonCode',p_season_code,
    'locationPatch',v_location,'geospatialPatch',v_geo,'climatePatch',v_climate
  );
end;
$$;

revoke all on function public.gal_search_places(text,text,integer) from public;
revoke all on function public.gal_resolve_place(text,text,text) from public;
revoke all on function public.gal_location_environment(text,text) from public;
revoke all on function public.gal_profile_update_playing_location(text,text,text,text) from public;

grant execute on function public.gal_search_places(text,text,integer) to anon,authenticated;
grant execute on function public.gal_resolve_place(text,text,text) to anon,authenticated;
grant execute on function public.gal_location_environment(text,text) to anon,authenticated;
grant execute on function public.gal_profile_update_playing_location(text,text,text,text) to authenticated;

create or replace function gal_private.gal_promote_environment_normal(
  p_place_id text,
  p_season_code text,
  p_source_key text,
  p_temperature_f numeric,
  p_wind_mph numeric,
  p_humidity_pct numeric,
  p_precipitation_in_per_day numeric,
  p_period_start date,
  p_period_end date,
  p_source_version text,
  p_source_reference text,
  p_confidence numeric,
  p_provenance jsonb default '{}'::jsonb
)
returns text
language plpgsql
security definer
set search_path=''
as $$
declare
  v_place uuid;
  v_source uuid;
  v_environment_id text;
begin
  select id into v_place from public.gal_places
   where place_id=p_place_id and active and canonical_status='APPROVED';
  if v_place is null then raise exception 'approved place not found: %',p_place_id; end if;

  select id into v_source from public.gal_location_sources
   where source_key=p_source_key and status='ACTIVE' and source_kind='CLIMATE_NORMALS';
  if v_source is null then raise exception 'active climate source not found: %',p_source_key; end if;

  if p_confidence < 0 or p_confidence > 1 then raise exception 'confidence must be 0..1'; end if;
  if p_humidity_pct is not null and (p_humidity_pct < 0 or p_humidity_pct > 100) then raise exception 'humidity must be 0..100'; end if;

  update public.gal_place_environment_normals
     set is_current=false,
         approval_status=case when approval_status='APPROVED' then 'RETIRED'::public.gal_environment_approval_status else approval_status end
   where place_id=v_place and season_code=p_season_code and is_current;

  insert into public.gal_place_environment_normals(
    place_id,season_code,typical_temperature_f,typical_wind_mph,typical_humidity_pct,typical_precipitation_in,
    period_start,period_end,source_name,source_reference,source_checked_at,confidence,provenance,is_current,
    source_id,source_version,approval_status,derivation_method,method_version,retrieved_at
  )
  select v_place,p_season_code,p_temperature_f,p_wind_mph,p_humidity_pct,p_precipitation_in_per_day,
         p_period_start,p_period_end,s.provider_name,p_source_reference,now(),p_confidence,coalesce(p_provenance,'{}'::jsonb),true,
         v_source,p_source_version,'APPROVED','Provider-normalized governed ingestion','GAL-ENV-DERIVE-1.0',now()
  from public.gal_location_sources s where s.id=v_source
  returning environment_id into v_environment_id;

  return v_environment_id;
end;
$$;

revoke all on function gal_private.gal_promote_environment_normal(text,text,text,numeric,numeric,numeric,numeric,date,date,text,text,numeric,jsonb) from public,anon,authenticated;
grant execute on function gal_private.gal_promote_environment_normal(text,text,text,numeric,numeric,numeric,numeric,date,date,text,text,numeric,jsonb) to service_role;

comment on table public.gal_location_sources is 'Governed registry of external geographic and climate sources used by GAL.';
comment on table public.gal_places is 'GAL canonical place master. GeoNames identity is authoritative for STEP 15 seed records.';
comment on table public.gal_place_environment_normals is 'Versioned governed environment normals. Public reads expose approved current rows only.';
comment on function public.gal_profile_update_playing_location(text,text,text,text) is 'Saves golfer playing location, resolves canonical place, and appends governed geospatial/climate facts without inventing missing enrichment.';
