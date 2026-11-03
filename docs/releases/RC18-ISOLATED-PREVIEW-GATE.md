# RC18 isolated review — deployment gate

Status: HOLD — NOT DEPLOYED. Production must remain untouched.

## Approved sources
- Exact RC16 archive: GAL-Website-v7.0.0-RC16-Staging-Verified-Approval-Candidate.zip; SHA256 9497c66f3503d21f65e67aed922d19527e7ca61c2c964b51e5b00e58b72a2ae7.
- Official Option 7A Motion Arc original assets; do not approximate the logo.
- RC18 local assembled review ZIP exists outside this repository, but its complete binary payload has NOT been committed here.

## Blocking work before GitHub Pages preview
1. Import complete authenticated RC16 payload, including binary graphics, with file-level manifest and checksum comparison.
2. Apply and review RC18 Putter shared-contract fix and Golf Ball entry without overwriting locked UX.
3. Verify all six guides: Golf Balls, Drivers, Irons, Wedges, Putters, Fairway Woods/Hybrids; questionnaires, scoring, images, save-to-bag and guest routes.
4. Reconcile UX11 locked five-view navigation and full profile persona routing: 12 Body, 12 Swing, 50-case gender/age matrix, unknown age, senior routing, handedness, aspect ratios.
5. Test auth, profile persistence, My GAL, subscriber portal, account deletion, and external staging dependencies.
6. Establish an isolated GitHub Pages preview that cannot replace production. Verify exact URL and browser acceptance.
7. Resolve regression failures and record test evidence. Do not declare PASS without running tests.

No production deployment is authorized. This branch is a recovery/deployment workstream, not the complete RC18 website.
