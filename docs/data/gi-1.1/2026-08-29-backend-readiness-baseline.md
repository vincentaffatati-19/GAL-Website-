# GI-1.1 Backend Readiness Baseline — 2026-08-29

## Purpose

This document records the production-shaped backend state before any GI-1.1 implementation migration is applied. It is a readiness/audit artifact, not an authorization to change production.

## Environment status

- Production Supabase project: reachable and queryable.
- PostgreSQL: 17.x production family.
- `supabase_migrations` schema: present.
- Persistent Supabase development branches: none at baseline.
- `pgcrypto`: installed (1.3).
- `pgtap`: available (1.3.3), not installed in production at baseline.
- `public.gal_current_user_id()`: present.
- Git feature branch: `feature/golfer-intelligence-v1`.
- Repository had no `supabase/` tree before this readiness checkpoint.

## Recorded production migration history

1. `20260821030856 gal_core_identity`
2. `20260821030905 gal_catalog_registry`
3. `20260821030919 gal_my_bag_tables`
4. `20260821030929 gal_rls_policies`
5. `20260821030942 gal_functions`
6. `20260821030950 gal_views_indexes`
7. `20260821031159 gal_add_to_my_bag_rpc`
8. `20260821031434 gal_catalog_seed_295`
9. `20260821031510 gal_security_hardening`
10. `20260821031536 gal_performance_hardening`
11. `20260821031617 gal_signup_consent_rpc`
12. `20260821153733 gal_driver_catalog_seed_v11`
13. `20260821155245 driver_v1_1_production_repository`
14. `20260821155820 driver_v1_1_production_snapshots`
15. `20260821155902 production_data_file_snapshots`
16. `20260821162317 gal_v64320_temp_import_rpc`
17. `20260821172943 gal_production_release_registry_v64320`
18. `20260821173409 gal_release_artifact_registry_v64320`
19. `20260821224149 add_putter_data_service_registry`
20. `20260822020242 create_gal_wedge_production_tables`
21. `20260822160539 gal_golfer_intelligence_spine_v01`
22. `20260822160648 gal_buyer_events_fk_indexes_v01`
23. `20260822164146 gal_bag_rules_engine_v01`
24. `20260822164235 gal_add_to_my_bag_warning_mode_v02`
25. `20260822164329 gal_intelligence_context_bag_rules_v02`
26. `20260822164629 gal_parse_set_club_count_fix_v02`
27. `20260822221057 gal_add_to_my_bag_display_snapshot_v03`
28. `20260822221516 gal_restrict_legacy_import_rpc_v01`

## Security baseline findings

### Release-blocking before GI-1.1 production promotion

1. `public.gal_parse_set_club_count(text)` has no fixed function `search_path` (`proconfig` is null).
2. `public.gal_add_to_my_bag(jsonb)` is `SECURITY DEFINER` and directly executable by `authenticated`.
3. Existing `gal_consent_records` permissions/policies must be migrated from broad self-CRUD to append-only consent history per the approved GI-1.1 design.
4. Supabase Auth leaked-password protection is disabled; enable before real registered-golfer launch.

### Informational RLS findings

Several equipment/reference/release tables have RLS enabled with no policies. These must be classified intentionally as server-only/reference tables or receive narrowly scoped policies; do not add blanket policies merely to silence the advisor.

### Performance baseline

Two current foreign keys lack covering indexes:

- `gal_wedge_commerce_routes.canonical_product_id`
- `gal_wedge_prices.canonical_product_id`

Multiple indexes are currently reported unused. No index should be removed solely from this pre-launch signal because the relevant operational tables have little or no production traffic.

## Function baseline

### `public.gal_add_to_my_bag(jsonb)`

- language: PL/pgSQL
- `SECURITY DEFINER`: yes
- fixed search path: `public`
- executable by authenticated: yes
- performs canonical user lookup, creates/uses active bag, writes immutable decision snapshot, and inserts/updates bag items.

The GI-1.1 security design must preserve needed trusted-write behavior without leaving an unnecessary browser-callable privilege boundary.

### `public.gal_parse_set_club_count(text)`

- language: PL/pgSQL
- immutable: yes
- `SECURITY DEFINER`: no
- function search path: not fixed at baseline

## Required readiness gate before schema implementation

- provision isolated Supabase development branch;
- create or designate staging/RC environment;
- import the current remote schema into Git with the current Supabase CLI workflow rather than inventing a historical migration;
- create `supabase/config.toml` using `supabase init`;
- enable/run pgTAP only in safe development/test workflows;
- run the committed RED security tests against the isolated production-shaped branch;
- patch the security findings there, verify GREEN, then record new advisor results;
- establish synthetic RLS fixtures;
- activate database CI after the baseline schema is reproducible;
- verify backup/recovery posture before any later production migration.

## Cost gate

At this baseline, a Supabase development branch is quoted at **$0.01344/hour**. Branch creation requires explicit user cost confirmation before provisioning.

## Production mutation status

**None.** This readiness checkpoint queried metadata/advisors only and changed Git documentation/test scaffolding on the feature branch.
