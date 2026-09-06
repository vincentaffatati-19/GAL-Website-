-- GAL UX10.02 STEP 14 — location-change and deterministic supersession hardening
-- Same-quality facts resolve by profile revision before timestamps.
-- Primary city changes retire location-specific derived and override facts.

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
           f.revision desc,
           f.observed_at desc,
           f.recorded_at desc,
           f.id desc
  limit 1;

  if v_winner is null then return null; end if;

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
  v_now timestamptz := clock_timestamp();
  v_key text;
  v_value jsonb;
  v_fact_id uuid;
  v_previous_active uuid;
  v_winner uuid;
  v_fact_ids uuid[] := '{}'::uuid[];
  v_keys text[] := '{}'::text[];
  v_default_confidence numeric;
  v_previous_city text;
  v_next_city text;
  v_environment_key text;
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

  if p_area='play' and p_facts ? 'city' then
    v_next_city := nullif(btrim(p_facts->>'city'),'');
    select f.fact_value#>>'{}' into v_previous_city
    from public.gal_profile_facts f
    where f.user_id=v_user_id
      and f.area='play'
      and f.fact_key='city'
      and f.scope=p_scope
      and f.fact_status='ACTIVE'
    limit 1;

    if v_previous_city is not null
       and v_next_city is not null
       and v_previous_city is distinct from v_next_city then
      update public.gal_profile_facts
         set fact_status='RETIRED',
             retired_at=v_now,
             retired_reason='primary_location_changed',
             updated_at=v_now
       where user_id=v_user_id
         and area='play'
         and scope=p_scope
         and source_type in ('USER_OVERRIDE','DERIVED_GEOSPATIAL','DERIVED_CLIMATE')
         and fact_key in (
           'geonamesId','latitude','longitude','elevationFt','typicalTemperatureF',
           'typicalWindMph','typicalHumidityPct','seasonality','environmentOverrideNote'
         )
         and fact_status<>'RETIRED';

      foreach v_environment_key in array array[
        'geonamesId','latitude','longitude','elevationFt','typicalTemperatureF',
        'typicalWindMph','typicalHumidityPct','seasonality','environmentOverrideNote'
      ] loop
        perform gal_private.profile_recompute_winner(v_user_id,v_environment_key,p_scope,v_now);
      end loop;
    end if;
  end if;

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
      (p_quality='SELF_REPORTED'),coalesce(nullif(p_scope,''),'global'),null,coalesce(p_observed_at,v_now),v_now,v_now,
      p_provenance->>'reference',p_area,p_units->>v_key,p_quality,p_source_type,'RECORDED_ONLY',v_revision,
      coalesce(p_provenance,'{}'::jsonb),v_now
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
