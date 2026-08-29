-- GI-1.1 Foundation Task 7
-- Purpose: complete append-only consent governance with additive metadata and consent classes.
-- Generated with Supabase CLI 2.116.0: supabase migration new gi11_consent_governance

-- Preserve existing consent values and extend the enum additively.
alter type public.gal_consent_type add value if not exists 'PERSONALIZATION';
alter type public.gal_consent_type add value if not exists 'PRODUCT_ANALYTICS';
alter type public.gal_consent_type add value if not exists 'COMMERCIAL_AGGREGATE_ANALYTICS';
alter type public.gal_consent_type add value if not exists 'RESEARCH_PARTICIPATION';
alter type public.gal_consent_type add value if not exists 'DATA_IMPORT';

-- Add provenance/context fields without changing existing consent rows.
alter table public.gal_consent_records
  add column if not exists interface text,
  add column if not exists jurisdiction text,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

-- Re-assert the append-only browser contract. Backend readiness introduced this early;
-- Task 7 makes it part of the formal GI-1.1 consent migration.
drop policy if exists gal_consent_self_all on public.gal_consent_records;
drop policy if exists gal_consent_self_select on public.gal_consent_records;
drop policy if exists gal_consent_self_insert on public.gal_consent_records;

revoke update, delete on table public.gal_consent_records from authenticated;
grant select, insert on table public.gal_consent_records to authenticated;

create policy gal_consent_self_select
  on public.gal_consent_records
  for select
  to authenticated
  using (user_id = public.gal_current_user_id());

create policy gal_consent_self_insert
  on public.gal_consent_records
  for insert
  to authenticated
  with check (user_id = public.gal_current_user_id());
