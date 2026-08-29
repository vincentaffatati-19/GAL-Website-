# GI-1.1 Database Test Helpers

This directory will contain synthetic-only pgTAP/RLS fixtures after the current production-shaped schema baseline is imported into the isolated development environment.

Required helper behavior:

- create deterministic synthetic Auth/GAL users in test transactions;
- set authenticated JWT context for user A and user B;
- verify `gal_current_user_id()` resolves the expected canonical GAL user;
- roll back all fixture data at the end of each test;
- never use real production golfer records.

See `docs/superpowers/plans/2026-08-29-gi-1.1-execution-contracts.md` for the binding test conventions.
