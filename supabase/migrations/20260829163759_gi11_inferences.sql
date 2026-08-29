-- GI-1.1 Foundation Task 5
-- Purpose: store system-generated golfer inferences with immutable provenance,
-- owner-only read access, and governed confirm/reject lifecycle transitions.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_inferences

create table public.gal_inferences (
  id uuid primary key default gen_random_uuid(),
  inference_id text unique not null default public.gal_public_id('GAL-INF'),
  user_id uuid not null references public.gal_users(id) on delete cascade,
  inference_key text not null references public.gal_fact_catalog(fact_key),
  inferred_value jsonb,
  value_state text not null default 'INFERRED_ONLY',
  confidence numeric(4,3) not null,
  status text not null default 'CANDIDATE',
  model_key text not null,
  model_version text not null,
  evidence_snapshot jsonb not null default '{}'::jsonb,
  explanation text,
  scope text not null default 'global',
  privacy_class text,
  commercial_class text,
  created_at timestamptz not null default now(),
  activated_at timestamptz,
  confirmed_at timestamptz,
  rejected_at timestamptz,
  superseded_at timestamptz,
  expired_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint gal_inferences_value_state_check
    check (value_state in ('KNOWN','UNKNOWN','NOT_APPLICABLE','INFERRED_ONLY')),
  constraint gal_inferences_confidence_check
    check (confidence >= 0 and confidence <= 1),
  constraint gal_inferences_status_check
    check (status in ('CANDIDATE','ACTIVE','CONFIRMED','REJECTED','SUPERSEDED','EXPIRED')),
  constraint gal_inferences_model_fk
    foreign key (model_key, model_version)
    references public.gal_model_registry(model_key, model_version)
);

create index gal_inferences_user_key_created_idx
  on public.gal_inferences(user_id, inference_key, created_at desc);

create index gal_inferences_user_status_idx
  on public.gal_inferences(user_id, status);

create index gal_inferences_user_active_idx
  on public.gal_inferences(user_id, inference_key, created_at desc)
  where status in ('ACTIVE','CONFIRMED');

alter table public.gal_inferences enable row level security;

revoke all on table public.gal_inferences from public, anon, authenticated;
grant select on table public.gal_inferences to authenticated;
grant select, insert, update, delete on table public.gal_inferences to service_role;

create policy gal_inferences_self_select
  on public.gal_inferences
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

-- Private lifecycle helper. It is outside the exposed public schema and performs
-- a strict ownership check before changing only lifecycle columns.
create or replace function gal_private.gal_set_inference_lifecycle(
  p_inference_id text,
  p_target_status text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_inference_uuid uuid;
  v_current_status text;
  v_target_status text := pg_catalog.upper(pg_catalog.btrim(p_target_status));
begin
  if v_target_status not in ('CONFIRMED','REJECTED') then
    raise exception 'GI11_INFERENCE_INVALID_TARGET_STATUS' using errcode = '22023';
  end if;

  select u.id
    into v_user_id
  from public.gal_users u
  where u.auth_user_id = auth.uid()
    and u.account_status = 'ACTIVE'
  limit 1;

  if v_user_id is null then
    raise exception 'GI11_ACTIVE_GAL_USER_REQUIRED' using errcode = '42501';
  end if;

  select i.id, i.status
    into v_inference_uuid, v_current_status
  from public.gal_inferences i
  where i.inference_id = p_inference_id
    and i.user_id = v_user_id
  for update;

  if v_inference_uuid is null then
    raise exception 'GI11_INFERENCE_NOT_OWNED' using errcode = '42501';
  end if;

  if v_current_status = v_target_status then
    return v_inference_uuid;
  end if;

  if v_current_status not in ('CANDIDATE','ACTIVE') then
    raise exception 'GI11_INFERENCE_INVALID_TRANSITION' using errcode = '22023';
  end if;

  update public.gal_inferences
  set
    status = v_target_status,
    confirmed_at = case
      when v_target_status = 'CONFIRMED' then pg_catalog.transaction_timestamp()
      else confirmed_at
    end,
    rejected_at = case
      when v_target_status = 'REJECTED' then pg_catalog.transaction_timestamp()
      else rejected_at
    end,
    updated_at = pg_catalog.transaction_timestamp()
  where id = v_inference_uuid;

  return v_inference_uuid;
end;
$$;

revoke all on function gal_private.gal_set_inference_lifecycle(text, text)
  from public, anon, authenticated;
grant execute on function gal_private.gal_set_inference_lifecycle(text, text)
  to authenticated, service_role;

-- Browser-facing endpoints stay SECURITY INVOKER. Their only privileged action is
-- the bounded call into the non-exposed helper above.
create or replace function public.gal_confirm_inference(p_inference_id text)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select gal_private.gal_set_inference_lifecycle(p_inference_id, 'CONFIRMED');
$$;

revoke all on function public.gal_confirm_inference(text) from public, anon;
grant execute on function public.gal_confirm_inference(text) to authenticated, service_role;

create or replace function public.gal_reject_inference(p_inference_id text)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select gal_private.gal_set_inference_lifecycle(p_inference_id, 'REJECTED');
$$;

revoke all on function public.gal_reject_inference(text) from public, anon;
grant execute on function public.gal_reject_inference(text) to authenticated, service_role;
