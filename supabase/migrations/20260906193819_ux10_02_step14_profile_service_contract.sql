-- GAL UX10.02 STEP 14 — Production Profile Service Contract
-- Applied first to GAL Longitudinal Staging on 2026-09-06.
-- Converts the UX10.02 governed profile behavior into a persistent Supabase contract.

do $$ begin
  create type public.gal_profile_fact_status as enum ('ACTIVE','SUPERSEDED','RECORDED_ONLY','RETIRED');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.gal_profile_quality as enum ('MEASURED','OBSERVED','SELF_REPORTED','INFERRED_ESTIMATED');
exception when duplicate_object then null; end $$;

alter table public.gal_users
  add column if not exists profile_revision bigint not null default 0;

alter table public.gal_profile_facts
  add column if not exists fact_id text not null default public.gal_public_id('GAL-PF'),
  add column if not exists area text not null default 'general',
  add column if not exists unit text,
  add column if not exists quality_class public.gal_profile_quality not null default 'SELF_REPORTED',
  add column if not exists source_type text not null default 'profile_form',
  add column if not exists fact_status public.gal_profile_fact_status not null default 'ACTIVE',
  add column if not exists revision bigint not null default 0,
  add column if not exists provenance jsonb not null default '{}'::jsonb,
  add column if not exists supersedes_fact_id uuid,
  add column if not exists superseded_by_fact_id uuid,
  add column if not exists superseded_at timestamptz,
  add column if not exists retired_at timestamptz,
  add column if not exists retired_reason text,
  add column if not exists recorded_at timestamptz not null default now();

alter table public.gal_profile_facts
  drop constraint if exists gal_profile_facts_user_id_fact_key_scope_key;

alter table public.gal_profile_facts
  drop constraint if exists gal_profile_facts_fact_id_key;
alter table public.gal_profile_facts
  add constraint gal_profile_facts_fact_id_key unique (fact_id);

alter table public.gal_profile_facts
  drop constraint if exists gal_profile_facts_supersedes_fact_id_fkey;
alter table public.gal_profile_facts
  add constraint gal_profile_facts_supersedes_fact_id_fkey
  foreign key (supersedes_fact_id) references public.gal_profile_facts(id) on delete set null;

alter table public.gal_profile_facts
  drop constraint if exists gal_profile_facts_superseded_by_fact_id_fkey;
alter table public.gal_profile_facts
  add constraint gal_profile_facts_superseded_by_fact_id_fkey
  foreign key (superseded_by_fact_id) references public.gal_profile_facts(id) on delete set null;

alter table public.gal_profile_facts
  drop constraint if exists gal_profile_facts_area_check;
alter table public.gal_profile_facts
  add constraint gal_profile_facts_area_check
  check (area in ('measurements','game','swing','miss','play','connected','general'));

create unique index if not exists gal_profile_facts_one_active_idx
  on public.gal_profile_facts(user_id, fact_key, scope)
  where fact_status='ACTIVE';
create index if not exists gal_profile_facts_history_idx
  on public.gal_profile_facts(user_id, area, fact_key, scope, recorded_at desc);
create index if not exists gal_profile_facts_revision_idx
  on public.gal_profile_facts(user_id, revision);

create table if not exists public.gal_profile_revisions (
  id uuid primary key default gen_random_uuid(),
  revision_id text not null unique default public.gal_public_id('GAL-PRV'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  revision bigint not null,
  event_type text not null,
  area text not null,
  fact_keys text[] not null default '{}'::text[],
  source_type text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(user_id, revision)
);
create index if not exists gal_profile_revisions_user_idx
  on public.gal_profile_revisions(user_id, revision desc);

create table if not exists public.gal_profile_audit_events (
  id uuid primary key default gen_random_uuid(),
  audit_event_id text not null unique default public.gal_public_id('GAL-PAE'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  revision bigint not null,
  event_type text not null,
  area text not null,
  source_type text not null,
  fact_ids uuid[] not null default '{}'::uuid[],
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists gal_profile_audit_user_idx
  on public.gal_profile_audit_events(user_id, revision desc, created_at desc);

create table if not exists public.gal_places (
  id uuid primary key default gen_random_uuid(),
  place_id text not null unique default public.gal_public_id('GAL-PLC'),
  geonames_id bigint unique,
  country_code text not null,
  country_name text not null,
  region_code text,
  region_name text,
  city_name text not null,
  latitude numeric(9,6),
  longitude numeric(9,6),
  timezone text,
  population bigint,
  elevation_m numeric,
  elevation_source text,
  source_name text not null default 'GeoNames',
  source_reference text,
  source_checked_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (latitude is null or (latitude between -90 and 90)),
  check (longitude is null or (longitude between -180 and 180))
);
create index if not exists gal_places_country_region_idx
  on public.gal_places(country_code, region_code);
create index if not exists gal_places_city_prefix_idx
  on public.gal_places((lower(city_name)) text_pattern_ops);

create table if not exists public.gal_place_environment_normals (
  id uuid primary key default gen_random_uuid(),
  environment_id text not null unique default public.gal_public_id('GAL-ENV'),
  place_id uuid not null references public.gal_places(id) on delete cascade,
  season_code text not null,
  typical_temperature_f numeric,
  typical_wind_mph numeric,
  typical_humidity_pct numeric,
  typical_precipitation_in numeric,
  seasonality text,
  period_start date,
  period_end date,
  source_name text not null,
  source_reference text,
  source_checked_at timestamptz not null default now(),
  confidence numeric not null default 0.8 check (confidence between 0 and 1),
  provenance jsonb not null default '{}'::jsonb,
  is_current boolean not null default true,
  created_at timestamptz not null default now(),
  check (typical_humidity_pct is null or typical_humidity_pct between 0 and 100)
);
create unique index if not exists gal_place_environment_current_idx
  on public.gal_place_environment_normals(place_id, season_code)
  where is_current;

create or replace function gal_private.profile_quality_rank(p_quality public.gal_profile_quality)
returns integer
language sql
immutable
strict
set search_path=''
as $$
  select case p_quality
    when 'MEASURED' then 4
    when 'OBSERVED' then 3
    when 'SELF_REPORTED' then 2
    when 'INFERRED_ESTIMATED' then 1
  end;
$$;

create or replace function gal_private.profile_recompute_winner(
  p_user_id uuid,
  p_fact_key text,
  p_scope text,
  p_at timestamptz
) returns uuid
language plpgsql
set search_path=''
as $$
declare
  v_winner uuid;
begin
  select f.id into v_winner
  from public.gal_profile_facts f
  where f.user_id=p_user_id
    and f.fact_key=p_fact_key
    and f.scope=p_scope
    and f.fact_status <> 'RETIRED'
    and f.retired_at is null
  order by gal_private.profile_quality_rank(f.quality_class) desc,
           f.observed_at desc,
           f.recorded_at desc,
           f.id desc
  limit 1;

  if v_winner is null then
    return null;
  end if;

  update public.gal_profile_facts
     set fact_status = case
           when fact_status='RECORDED_ONLY' then 'RECORDED_ONLY'::public.gal_profile_fact_status
           else 'SUPERSEDED'::public.gal_profile_fact_status
         end,
         superseded_at = case when fact_status='ACTIVE' then p_at else superseded_at end,
         superseded_by_fact_id = v_winner,
         updated_at = p_at
   where user_id=p_user_id
     and fact_key=p_fact_key
     and scope=p_scope
     and id<>v_winner
     and fact_status<>'RETIRED';

  update public.gal_profile_facts
     set fact_status='ACTIVE',
         superseded_at=null,
         superseded_by_fact_id=null,
         updated_at=p_at
   where id=v_winner;

  return v_winner;
end;
$$;

create or replace function gal_private.profile_fact_update_guard()
returns trigger
language plpgsql
set search_path=''
as $$
begin
  if new.user_id is distinct from old.user_id
     or new.fact_id is distinct from old.fact_id
     or new.area is distinct from old.area
     or new.fact_key is distinct from old.fact_key
     or new.fact_value is distinct from old.fact_value
     or new.unit is distinct from old.unit
     or new.source is distinct from old.source
     or new.source_category is distinct from old.source_category
     or new.source_type is distinct from old.source_type
     or new.quality_class is distinct from old.quality_class
     or new.confidence is distinct from old.confidence
     or new.user_confirmed is distinct from old.user_confirmed
     or new.scope is distinct from old.scope
     or new.stale_after_days is distinct from old.stale_after_days
     or new.observed_at is distinct from old.observed_at
     or new.created_at is distinct from old.created_at
     or new.recorded_at is distinct from old.recorded_at
     or new.source_reference is distinct from old.source_reference
     or new.provenance is distinct from old.provenance
     or new.revision is distinct from old.revision then
    raise exception 'GAL_PROFILE_FACT_IMMUTABLE';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_gal_profile_fact_update_guard on public.gal_profile_facts;
create trigger trg_gal_profile_fact_update_guard
before update on public.gal_profile_facts
for each row execute function gal_private.profile_fact_update_guard();

create or replace function gal_private.profile_apply_patch_impl(
  p_area text,
  p_facts jsonb default '{}'::jsonb,
  p_clear_keys text[] default '{}'::text[],
  p_quality public.gal_profile_quality default 'SELF_REPORTED',
  p_source_type text default 'profile_form',
  p_source_name text default 'My Golfer Profile',
  p_confidence numeric default null,
  p_scope text default 'global',
  p_units jsonb default '{}'::jsonb,
  p_observed_at timestamptz default now(),
  p_provenance jsonb default '{}'::jsonb,
  p_event_type text default 'profile_facts_updated'
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_user_id uuid;
  v_revision bigint;
  v_now timestamptz := now();
  v_key text;
  v_value jsonb;
  v_fact_id uuid;
  v_previous_active uuid;
  v_winner uuid;
  v_fact_ids uuid[] := '{}'::uuid[];
  v_keys text[] := '{}'::text[];
  v_default_confidence numeric;
begin
  if p_area not in ('measurements','game','swing','miss','play','connected') then
    raise exception 'GAL_PROFILE_AREA_INVALID';
  end if;
  if p_facts is null or jsonb_typeof(p_facts)<>'object' then
    raise exception 'GAL_PROFILE_FACTS_MUST_BE_OBJECT';
  end if;
  if p_confidence is not null and (p_confidence<0 or p_confidence>1) then
    raise exception 'GAL_PROFILE_CONFIDENCE_INVALID';
  end if;

  select u.id into v_user_id
  from public.gal_users u
  where u.auth_user_id=(select auth.uid()) and u.account_status='ACTIVE'
  limit 1;
  if v_user_id is null then
    raise exception 'GAL_PROFILE_AUTH_REQUIRED' using errcode='42501';
  end if;

  if p_facts='{}'::jsonb and coalesce(array_length(p_clear_keys,1),0)=0 then
    select profile_revision into v_revision from public.gal_users where id=v_user_id;
    return jsonb_build_object('revision',v_revision,'factIds','[]'::jsonb,'noop',true);
  end if;

  update public.gal_users
     set profile_revision=profile_revision+1, updated_at=v_now
   where id=v_user_id
   returning profile_revision into v_revision;

  foreach v_key in array coalesce(p_clear_keys,'{}'::text[]) loop
    update public.gal_profile_facts
       set fact_status='RETIRED',
           retired_at=v_now,
           retired_reason='user_cleared',
           updated_at=v_now
     where user_id=v_user_id
       and area=p_area
       and fact_key=v_key
       and scope=p_scope
       and source_type=p_source_type
       and quality_class=p_quality
       and fact_status<>'RETIRED';
    perform gal_private.profile_recompute_winner(v_user_id,v_key,p_scope,v_now);
    v_keys := array_append(v_keys,v_key);
  end loop;

  v_default_confidence := coalesce(
    p_confidence,
    case p_quality
      when 'MEASURED' then 1.0
      when 'OBSERVED' then 0.85
      when 'SELF_REPORTED' then 0.75
      else 0.50
    end
  );

  for v_key,v_value in select key,value from jsonb_each(p_facts) loop
    if jsonb_typeof(v_value)='null'
       or (jsonb_typeof(v_value)='string' and btrim(v_value#>>'{}')='') then
      continue;
    end if;

    select f.id into v_previous_active
      from public.gal_profile_facts f
     where f.user_id=v_user_id
       and f.fact_key=v_key
       and f.scope=p_scope
       and f.fact_status='ACTIVE'
     limit 1;

    insert into public.gal_profile_facts(
      user_id,fact_key,fact_value,source,source_category,confidence,user_confirmed,scope,
      stale_after_days,observed_at,updated_at,created_at,source_reference,
      area,unit,quality_class,source_type,fact_status,revision,provenance,recorded_at
    ) values (
      v_user_id,v_key,v_value,coalesce(nullif(p_source_name,''),p_source_type),p_quality::text,v_default_confidence,
      (p_quality='SELF_REPORTED'),coalesce(nullif(p_scope,''),'global'),
      null,coalesce(p_observed_at,v_now),v_now,v_now,p_provenance->>'reference',
      p_area,p_units->>v_key,p_quality,p_source_type,'RECORDED_ONLY',v_revision,coalesce(p_provenance,'{}'::jsonb),v_now
    ) returning id into v_fact_id;

    v_winner := gal_private.profile_recompute_winner(
      v_user_id,v_key,coalesce(nullif(p_scope,''),'global'),v_now
    );
    if v_winner=v_fact_id and v_previous_active is not null and v_previous_active<>v_fact_id then
      update public.gal_profile_facts
         set supersedes_fact_id=v_previous_active, updated_at=v_now
       where id=v_fact_id;
    end if;
    v_fact_ids := array_append(v_fact_ids,v_fact_id);
    v_keys := array_append(v_keys,v_key);
  end loop;

  select coalesce(array_agg(distinct x), '{}'::text[])
    into v_keys
    from unnest(v_keys) x;

  insert into public.gal_profile_revisions(
    user_id,revision,event_type,area,fact_keys,source_type,metadata,created_at
  ) values(
    v_user_id,v_revision,p_event_type,p_area,v_keys,p_source_type,
    jsonb_build_object('quality',p_quality,'scope',p_scope),v_now
  );

  insert into public.gal_profile_audit_events(
    user_id,revision,event_type,area,source_type,fact_ids,metadata,created_at
  ) values(
    v_user_id,v_revision,p_event_type,p_area,p_source_type,v_fact_ids,
    jsonb_build_object('keys',to_jsonb(v_keys),'quality',p_quality,'scope',p_scope),v_now
  );

  return jsonb_build_object(
    'revision',v_revision,'factIds',to_jsonb(v_fact_ids),'keys',to_jsonb(v_keys),'noop',false
  );
end;
$$;

create or replace function public.gal_profile_apply_patch(
  p_area text,
  p_facts jsonb default '{}'::jsonb,
  p_clear_keys text[] default '{}'::text[],
  p_quality public.gal_profile_quality default 'SELF_REPORTED',
  p_source_type text default 'profile_form',
  p_source_name text default 'My Golfer Profile',
  p_confidence numeric default null,
  p_scope text default 'global',
  p_units jsonb default '{}'::jsonb,
  p_observed_at timestamptz default now(),
  p_provenance jsonb default '{}'::jsonb,
  p_event_type text default 'profile_facts_updated'
) returns jsonb
language sql
security invoker
set search_path=''
as $$
  select gal_private.profile_apply_patch_impl(
    p_area,p_facts,p_clear_keys,p_quality,p_source_type,p_source_name,p_confidence,
    p_scope,p_units,p_observed_at,p_provenance,p_event_type
  );
$$;

create or replace view public.gal_profile_active_facts_v
with (security_invoker=true)
as
select id,fact_id,user_id,area,fact_key,fact_value,unit,quality_class,source_type,source,
       confidence,scope,observed_at,recorded_at,revision,provenance
from public.gal_profile_facts
where fact_status='ACTIVE' and retired_at is null;

create or replace function public.gal_profile_snapshot()
returns jsonb
language sql
stable
security invoker
set search_path=''
as $$
  select jsonb_build_object(
    'schemaVersion','GAL-GIP-1.0',
    'userId',u.gal_user_id,
    'profileId','profile:'||u.gal_user_id,
    'revision',u.profile_revision,
    'updatedAt',u.updated_at,
    'facts',coalesce((
      select jsonb_agg(jsonb_build_object(
        'factId',f.fact_id,'area',f.area,'key',f.fact_key,'value',f.fact_value,'unit',f.unit,
        'quality',f.quality_class,'sourceType',f.source_type,'source',f.source,'confidence',f.confidence,
        'scope',f.scope,'observedAt',f.observed_at,'recordedAt',f.recorded_at,
        'revision',f.revision,'provenance',f.provenance
      ) order by f.area,f.fact_key)
      from public.gal_profile_active_facts_v f
      where f.user_id=u.id
    ),'[]'::jsonb)
  )
  from public.gal_users u
  where u.id=public.gal_current_user_id();
$$;

create or replace function public.gal_location_search(
  p_country_code text default null,
  p_region_code text default null,
  p_query text default null,
  p_limit integer default 12
) returns table(
  place_id text, geonames_id bigint, country_code text, country_name text,
  region_code text, region_name text, city_name text, latitude numeric,
  longitude numeric, timezone text, elevation_m numeric
)
language sql
stable
security invoker
set search_path=''
as $$
  select p.place_id,p.geonames_id,p.country_code,p.country_name,p.region_code,p.region_name,
         p.city_name,p.latitude,p.longitude,p.timezone,p.elevation_m
  from public.gal_places p
  where p.active
    and (p_country_code is null or p.country_code=p_country_code)
    and (p_region_code is null or p.region_code=p_region_code)
    and (p_query is null or btrim(p_query)='' or lower(p.city_name) like lower(btrim(p_query))||'%')
  order by p.population desc nulls last,p.city_name
  limit greatest(1,least(coalesce(p_limit,12),25));
$$;

create or replace function public.gal_location_environment(
  p_place_id text,
  p_season_code text
) returns table(
  place_id text, environment_id text, season_code text, typical_temperature_f numeric,
  typical_wind_mph numeric, typical_humidity_pct numeric, typical_precipitation_in numeric,
  seasonality text, source_name text, source_reference text, source_checked_at timestamptz,
  confidence numeric, provenance jsonb
)
language sql
stable
security invoker
set search_path=''
as $$
  select p.place_id,e.environment_id,e.season_code,e.typical_temperature_f,e.typical_wind_mph,
         e.typical_humidity_pct,e.typical_precipitation_in,e.seasonality,e.source_name,
         e.source_reference,e.source_checked_at,e.confidence,e.provenance
  from public.gal_places p
  join public.gal_place_environment_normals e on e.place_id=p.id
  where p.active and e.is_current and p.place_id=p_place_id and e.season_code=p_season_code
  limit 1;
$$;

alter table public.gal_profile_facts enable row level security;
alter table public.gal_profile_revisions enable row level security;
alter table public.gal_profile_audit_events enable row level security;
alter table public.gal_places enable row level security;
alter table public.gal_place_environment_normals enable row level security;

drop policy if exists gal_profile_facts_self_insert on public.gal_profile_facts;
drop policy if exists gal_profile_facts_self_update on public.gal_profile_facts;
drop policy if exists gal_profile_facts_self_delete on public.gal_profile_facts;
drop policy if exists gal_profile_facts_self_select on public.gal_profile_facts;
create policy gal_profile_facts_self_select
  on public.gal_profile_facts for select to authenticated
  using (user_id=public.gal_current_user_id());

create policy gal_profile_revisions_self_select
  on public.gal_profile_revisions for select to authenticated
  using (user_id=public.gal_current_user_id());
create policy gal_profile_audit_self_select
  on public.gal_profile_audit_events for select to authenticated
  using (user_id=public.gal_current_user_id());
create policy gal_places_public_select
  on public.gal_places for select to anon,authenticated
  using (active);
create policy gal_environment_public_select
  on public.gal_place_environment_normals for select to anon,authenticated
  using (is_current);

revoke all on public.gal_profile_facts from anon,authenticated;
grant select on public.gal_profile_facts to authenticated;
revoke all on public.gal_profile_revisions from anon,authenticated;
grant select on public.gal_profile_revisions to authenticated;
revoke all on public.gal_profile_audit_events from anon,authenticated;
grant select on public.gal_profile_audit_events to authenticated;
revoke all on public.gal_users from anon,authenticated;
grant select on public.gal_users to authenticated;
revoke all on public.gal_places from anon,authenticated;
grant select on public.gal_places to anon,authenticated;
revoke all on public.gal_place_environment_normals from anon,authenticated;
grant select on public.gal_place_environment_normals to anon,authenticated;

grant usage on schema gal_private to authenticated;
revoke all on function gal_private.profile_apply_patch_impl(
  text,jsonb,text[],public.gal_profile_quality,text,text,numeric,text,jsonb,timestamptz,jsonb,text
) from public,anon;
grant execute on function gal_private.profile_apply_patch_impl(
  text,jsonb,text[],public.gal_profile_quality,text,text,numeric,text,jsonb,timestamptz,jsonb,text
) to authenticated;
revoke all on function public.gal_profile_apply_patch(
  text,jsonb,text[],public.gal_profile_quality,text,text,numeric,text,jsonb,timestamptz,jsonb,text
) from public,anon;
grant execute on function public.gal_profile_apply_patch(
  text,jsonb,text[],public.gal_profile_quality,text,text,numeric,text,jsonb,timestamptz,jsonb,text
) to authenticated;
revoke all on function public.gal_profile_snapshot() from public,anon;
grant execute on function public.gal_profile_snapshot() to authenticated;
revoke all on function public.gal_location_search(text,text,text,integer) from public;
grant execute on function public.gal_location_search(text,text,text,integer) to anon,authenticated;
revoke all on function public.gal_location_environment(text,text) from public;
grant execute on function public.gal_location_environment(text,text) to anon,authenticated;
grant select on public.gal_profile_active_facts_v to authenticated;
