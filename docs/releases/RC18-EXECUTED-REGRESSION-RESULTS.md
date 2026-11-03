# RC18 executable regression evidence — 2026-11-03

Test source: exact local RC18 complete integrated ZIP, extracted.

- Python pytest: **9 passed, 2 failed**.
- Node Driver integration runtime: PASS.
- Node Driver scoring regression: PASS.
- UX11 profile integration: FAIL, `Home missing UX11 flow Today`.
- UX12 simplification: FAIL, `my-gal: My Bag must be first primary section`.

Python failures:
1. Historical RC15 putter hash expected `5e0e6408516f67ee1594a139700e893b4e644ae48ccd87252be97bef3d4379b9`, RC18 putter actual `6a80a42081a78ab4e6df866c7b396d172a525bcf3df7fa9e4b8d841d894d5405`. Iron and My GAL original hashes unchanged.
2. Historical RC15 test forbids any migrations; RC16 intentionally added account-deletion migration.

The UX11/UX12 navigation expectations require reconciliation with final locked decisions. Do not simply delete failing tests.

Deployment: no live preview. Local git access to github.com failed DNS resolution; GitHub connector can write repo objects but cannot directly ingest the local binary archive. Branch currently contains documentation only, not the full 431-file package. Production untouched.
