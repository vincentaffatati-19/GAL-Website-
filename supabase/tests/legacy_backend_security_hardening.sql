begin;

do $$
declare
  v_config text[];
  v_auth_exec boolean;
  v_update boolean;
  v_delete boolean;
  v_policy_count integer;
begin
  if to_regprocedure('public.gal_parse_set_club_count(text)') is not null then
    select proconfig into v_config from pg_proc where oid='public.gal_parse_set_club_count(text)'::regprocedure;
    if v_config is null or not ('search_path=public, pg_temp'=any(v_config)) then
      raise exception 'gal_parse_set_club_count search_path is not fixed: %',v_config;
    end if;
  end if;

  if to_regprocedure('public.gal_add_to_my_bag(jsonb)') is not null then
    select has_function_privilege('authenticated','public.gal_add_to_my_bag(jsonb)','EXECUTE') into v_auth_exec;
    if v_auth_exec then raise exception 'authenticated can still execute gal_add_to_my_bag'; end if;
  end if;

  select has_table_privilege('authenticated','public.gal_consent_records','UPDATE'),
         has_table_privilege('authenticated','public.gal_consent_records','DELETE')
  into v_update,v_delete;
  if v_update or v_delete then raise exception 'consent history is not append-only'; end if;

  select count(*) into v_policy_count from pg_policies
  where schemaname='public' and tablename='gal_consent_records' and policyname in ('gal_consent_self_select','gal_consent_self_insert');
  if v_policy_count<>2 then raise exception 'expected consent select+insert policies'; end if;

  if to_regprocedure('public.gal_v64320_import(text,text,jsonb)') is not null then
    raise exception 'obsolete import RPC still exists';
  end if;
end $$;

rollback;
