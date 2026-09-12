# GAL UX11 RC1 — Profile Integration Root Cause

Status: VERIFIED ROOT CAUSE / REMEDIATION BRANCH

## Verified repository state
- Repository: `vincentaffatati-19/GAL-Website-`
- Source branch: `feature/ux11-my-gal-intelligence-experience`
- Verified source head: `6666c5a1279b8062b6d63554bb631535491878c5`
- Recovery branch: `feature/ux11-profile-integration-recovery`
- UX10 corrected baseline: `092aadef8d64886716cf99d2045d0ea8cc90fe50`
- Source head is 11 commits ahead / 0 behind that baseline.
- RC assembly manifest: `docs/ux11/GAL-UX11.0-RC1-ASSEMBLY-MANIFEST.yaml`, schema 1.2.
- Locked routing authority: `docs/ux11/GAL-UX11-PROFILE-VISUAL-LINEAGE-AND-ROUTING-LOCK.md`.

## Root cause
The RC1 review package and the live UX11 branch are not equivalent Profile implementations.

The review package correctly inherits the locked `GAL-UX10.02-FINAL-PROFILE-RC.html` implementation and preserves its governed Dynamic Golfer Visual System. The UX11 branch, however, still contains the simpler modular `profile.html` / `profile__app.js` editor. That branch implementation does not contain the approved Dynamic Golfer Body/Swing presentation, the full gender × age visual resolver, the six governed disclosure areas, or the required modular `profile__visuals.js` dependency.

Therefore the branch cannot satisfy `tests/test-ux11-my-gal-intelligence.js` by adding a stub resolver. The Profile surface itself must be integrated from the approved lineage.

## Locked implementation authority
The remediation must preserve, not recreate:
- 12 governed Body persona routes and 12 matching Swing routes.
- 50-case Gender × Age resolver behavior.
- explicit Male/Female unknown-age gender authority without an age claim.
- Male/Female 65–74 and 75+ senior routing.
- Body/Swing persona-key parity.
- photographic-layer-only left-handed mirroring.
- native-aspect four-stage Swing rendering: Address, Backswing, Impact, Finish.
- six approved collapsed Profile disclosure areas.
- STEP18 same-profile-revision downstream consistency.

## Asset-custody finding
Live Supabase storage inspection confirms the exact eight GAL-owned runtime persona pairs under `gal-profile-visuals/ux10-02/v3`:
- junior_male
- junior_female
- male_young
- male_middle
- female_middle
- male_senior
- neutral_junior
- neutral_adult

The four approved embedded persona pairs are intentionally absent from that bucket and remain embedded in the authoritative Final Profile RC:
- female_young
- male_mature
- female_mature
- female_senior

This matches the locked 4 embedded + 8 Supabase runtime custody rule. Remediation must not regenerate, substitute, or silently re-host those four embedded masters.

## Review-candidate finding
`GAL-UX11.0-RC1-REVIEW-CANDIDATE.zip` preserves the authoritative Final Profile source byte-for-byte as `profile-source-ux10.02.html` with SHA-256:
`c2dd228f782fd357949c472a07d6a2cb68be6308ea60d749dfac8fe0bdc5c084`

Its review `profile.html` differs from that source only in review-shell labeling/banner treatment; the governed Profile implementation remains inherited from the approved source.

## Browser verification boundary
A fresh browser run in the current ChatGPT execution environment is blocked by an administrator policy for both loopback HTTP and `file://` navigation. This is an environment limitation and must be recorded as BLOCKED / UNVERIFIED rather than converted into a product pass or failure.

Historical STEP18 browser QA remains valid lineage evidence: the integrated staging candidate passed the complete gender/age/handedness routing matrix, location-change scenarios, same-revision downstream snapshots, and reported 0 console/page errors. It does not substitute for a fresh UX11 browser pass after modular integration.

## Required remediation sequence
1. Keep RC1 and source head immutable as the recovery checkpoint.
2. Perform Profile integration only on `feature/ux11-profile-integration-recovery`.
3. Make the existing UX11 regression contract executable in CI and confirm the current branch fails for the expected Profile-integration reason.
4. Integrate the approved Profile structure and resolver without changing locked visual assets or custody.
5. Preserve the current Supabase governed snapshot/patch contracts and STEP18 same-revision semantics while restoring the approved Profile UX.
6. Re-run JavaScript/static contract tests.
7. Run fresh desktop/mobile browser verification in an environment that permits browser navigation.
8. Only after all gates pass, assemble the next founder-review candidate. Production promotion remains unauthorized.
