create policy gal_insight_signals_no_client_access
on public.gal_insight_signals
as restrictive
for all
to anon, authenticated
using (false)
with check (false);
