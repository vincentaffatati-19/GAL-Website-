-- STEP 16 hardening: PostgreSQL http extension grants EXECUTE to PUBLIC by default.
-- This migration documents the first ACL hardening attempt; the subsequent private-schema migration provides effective isolation.
do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as proc
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='extensions'
      and (p.proname='http' or p.proname like 'http\_%' escape '\')
  loop
    execute format('revoke execute on function %s from public, anon, authenticated', r.proc);
  end loop;
end $$;
