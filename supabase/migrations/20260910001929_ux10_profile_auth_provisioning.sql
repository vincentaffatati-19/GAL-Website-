-- UX10 Profile recommendations: provision canonical GAL identity for newly authenticated users.
-- Applied first to GAL Longitudinal Staging on 2026-09-10 as migration 20260910001929.

create or replace function gal_private.provision_gal_user_from_auth()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  insert into public.gal_users(auth_user_id)
  values (new.id)
  on conflict (auth_user_id) do nothing;
  return new;
end;
$$;

revoke all on function gal_private.provision_gal_user_from_auth() from public, anon, authenticated;

drop trigger if exists trg_gal_provision_user_from_auth on auth.users;
create trigger trg_gal_provision_user_from_auth
after insert on auth.users
for each row execute function gal_private.provision_gal_user_from_auth();
