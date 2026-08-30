create policy gal_learning_snapshots_no_client_access on public.gal_learning_snapshots as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_learning_candidates_no_client_access on public.gal_learning_candidates as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_insight_resolution_rules_no_client_access on public.gal_insight_resolution_rules as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_insight_resolution_events_no_client_access on public.gal_insight_resolution_events as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_learning_snapshot_contributors_no_client_access on public.gal_learning_snapshot_contributors as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_learning_consent_reconciliations_no_client_access on public.gal_learning_consent_reconciliations as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_governance_actors_no_client_access on public.gal_governance_actors as restrictive for all to anon,authenticated using(false) with check(false);
create policy gal_learning_evaluation_policies_no_client_access on public.gal_learning_evaluation_policies as restrictive for all to anon,authenticated using(false) with check(false);
