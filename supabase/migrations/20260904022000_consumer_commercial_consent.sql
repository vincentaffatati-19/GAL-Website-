alter type public.gal_consent_type add value if not exists 'COMMERCIAL_AGGREGATE';

create or replace view public.gal_commercial_aggregate_eligible_users_v
with (security_invoker = true)
as
with latest_analytics as (
  select distinct on (user_id)
    user_id,
    status,
    recorded_at
  from public.gal_consent_records
  where consent_type::text = 'ANALYTICS_OPTIONAL'
  order by user_id, recorded_at desc, id desc
),
latest_commercial as (
  select distinct on (user_id)
    user_id,
    status,
    recorded_at
  from public.gal_consent_records
  where consent_type::text = 'COMMERCIAL_AGGREGATE'
  order by user_id, recorded_at desc, id desc
)
select
  analytics.user_id,
  greatest(analytics.recorded_at, commercial.recorded_at) as effective_consent_at
from latest_analytics analytics
join latest_commercial commercial using (user_id)
where analytics.status = 'ACCEPTED'
  and commercial.status = 'ACCEPTED';

revoke all on public.gal_commercial_aggregate_eligible_users_v from public;
revoke all on public.gal_commercial_aggregate_eligible_users_v from anon;
revoke all on public.gal_commercial_aggregate_eligible_users_v from authenticated;
grant select on public.gal_commercial_aggregate_eligible_users_v to service_role;

comment on view public.gal_commercial_aggregate_eligible_users_v is
  'Internal-only commercial aggregate eligibility. Requires latest ANALYTICS_OPTIONAL and COMMERCIAL_AGGREGATE consent to both be ACCEPTED. Never expose this view to browser roles.';
