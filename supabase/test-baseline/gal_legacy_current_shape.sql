-- GAL GI-1.1 sanitized legacy-current-shape test fixture
-- Purpose: reproduce the existence and access shape of the obsolete temporary import RPC.
-- IMPORTANT: this fixture contains no historical token, production payload, or user data.

create or replace function public.gal_v64320_import(
  p_token text,
  p_mode text,
  p_rows jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  return jsonb_build_object('ok', false, 'reason', 'sanitized_test_stub');
end;
$$;

revoke execute on function public.gal_v64320_import(text,text,jsonb) from public, anon, authenticated;
grant execute on function public.gal_v64320_import(text,text,jsonb) to service_role;
