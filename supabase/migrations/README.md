# GAL Supabase Migrations

This directory is the Git source of truth for GAL database migrations created from the GI-1.1 readiness checkpoint forward.

Before the first GI-1.1 migration is created, the current remote schema must be imported into this repository using the current Supabase CLI workflow (`supabase init`, `supabase link` to an approved non-production branch, then `supabase db pull`). Do not hand-author a fake historical baseline.

GI-1.1 migrations must follow the approved design and implementation plans under `docs/superpowers/` and must not be applied directly to production during feature development.
