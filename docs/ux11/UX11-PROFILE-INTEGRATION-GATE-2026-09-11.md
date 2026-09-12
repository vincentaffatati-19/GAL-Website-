# UX11 Profile Integration Gate — 2026-09-11

Status: **HOLD — single governed binary asset blocker**

## Founder review
The `GAL-UX11.0-RC1-REVIEW-CANDIDATE.zip` founder-review gate has been cleared by the founder. This does **not** authorize production promotion.

## Recovery branch
- Source / reviewed branch: `feature/ux11-my-gal-intelligence-experience`
- Recovery branch: `feature/ux11-profile-integration-recovery`
- Recovery is based directly on the reviewed UX11 branch and contains the modular Profile integration, resolver, CSS/HTML/app wiring, regression workflow, and strengthened governed contract.
- Current compare state at checkpoint creation: recovery **16 commits ahead / 0 behind** source.

## Fresh regression evidence
Latest inspected GitHub Actions run on the recovery branch:
- Workflow: `UX11 Regression Contract`
- Run ID: `34668069312`
- Recovery SHA: `1005d577f512fb7085df2d67a74473a7a0cae5b4`
- JavaScript syntax checks: **PASS**
- Governed UX11 regression contract: **FAIL**

The failure is not a resolver-logic failure. The branch references the approved `profile__miss-reference.png`, and the regression contract correctly requires its exact governed bytes, but the binary file is absent from Git.

## Exact required asset
Authoritative source: `GAL-UX10.02-FINAL-PROFILE-RC.html`

Required local repository path:
`profile__miss-reference.png`

Exact properties:
- File size: `826825` bytes
- SHA-256: `721d149366e5132bede0ea33eef809baae309e646da6acd063a403da15306348`
- Git blob SHA when represented as a Git blob: `f691448296de0238ea08e79f1edfd42661cb9be5`

The exact PNG has been extracted and independently verified from the authoritative final Profile RC. It must be committed byte-for-byte. A visually similar replacement, regeneration, re-encoding, or weakened hash gate is prohibited.

## Custody verification
Both GAL Supabase environments were checked for an existing object with the exact `826825` byte size. No matching stored object exists, so there is no safe existing server-side copy to relink.

## Release decision
Do **not** fast-forward or merge `feature/ux11-profile-integration-recovery` into `feature/ux11-my-gal-intelligence-experience` while the governed regression is red.

The only permitted next release-gate operation is:
1. commit the exact approved `profile__miss-reference.png` bytes to the recovery branch;
2. rerun `UX11 Regression Contract`;
3. require all syntax and governed contract checks to pass;
4. perform fresh desktop/mobile browser verification in a browser-enabled environment;
5. only then advance the reviewed UX11 branch.

Production promotion remains unauthorized until the broader GAL release/security/integration gates are also cleared.
