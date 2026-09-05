# GAL GOVERNANCE RULE — LOCKED

**Status:** USER-APPROVED / LOCKED  
**Effective:** 2026-09-04  
**Amended:** 2026-09-04 — Mandatory step-by-step preview/review gate

This rule governs all Golf Analytics Lab design, UX, code, database, guide, branding, portal, data-model, and release work.

## Mandatory source-of-truth preflight

Before any substantive GAL work begins, the assistant/implementer must retrieve and verify the current authoritative governance material relevant to the task.

For UX/website work, this always includes:

1. `GAL_GOVERNANCE_RULE.md`;
2. `GAL_UX_MANIFEST.json`;
3. `GAL_UX_CURRENT.md`;
4. the authoritative versioned UX specification referenced by the manifest;
5. the locked visual reference when the task affects presentation;
6. any older governing specification explicitly inherited by the current manifest.

For non-UX work, retrieve the applicable current governing specification/version record before editing implementation.

## Conflict rule

The user's latest explicit decision overrides older material. If the requested work conflicts with a current lock, the conflict must be surfaced before implementation. The newest code, newest release candidate, newest mockup, or most recent assistant output does not automatically become the source of truth.

If authoritative material cannot be retrieved or a material conflict cannot be resolved, implementation stops until the conflict is resolved.

## Decision persistence rule

When the user says `lock it`, `replace it`, `make this the rule`, `use this going forward`, or equivalent language, that decision must be persisted into the appropriate GAL governance record immediately rather than left only in conversational memory.

## Mandatory step-by-step preview and user review gate

The user reviews every meaningful GAL implementation step. This is a hard release/workflow gate.

- After each meaningful design, UX, website, portal, branding, guide, or implementation step, stop and provide the user a preview of that exact step.
- Do not batch multiple unreviewed visual/UX steps together when they can reasonably be reviewed separately.
- Do not proceed to the next meaningful step until the user has reviewed the preview and explicitly directs the work to continue, approve, or revise.
- Every preview must represent the exact current candidate being described. A stale deployment, prior artifact, approximate mockup, or unrelated READY deployment is not an acceptable preview.
- For visual work, inspect the rendered output against the governing visual reference and locked brand before presenting it.
- For website/app work, the preview must be functional enough for the user to inspect the changed experience; where practical, provide both the directly openable preview and a downloadable review package.
- Clearly identify what changed in that preview and what has deliberately not changed.
- Do not call a preview verified unless the relevant automated checks/build and direct rendered-output checks have been completed.
- Production promotion remains separately gated and still requires explicit user approval.

This review gate applies even when the requested implementation is part of a larger approved plan. Approval of the plan does not waive step-by-step previews.

## UX authority

For GAL UX, authority order is:

1. later explicit user-approved UX lock;
2. `GAL_UX_MANIFEST.json`;
3. `GAL_UX_CURRENT.md`;
4. authoritative versioned UX specification;
5. inherited/older approved specifications;
6. implementation/code.

Code may lag the lock. Code cannot silently supersede it.

## UX10 versioning rule

The current architectural UX family is `GAL-UX10`.

- Current locked version: `GAL-UX10.02`.
- Revisions within the same architecture increment sequentially: `.03`, `.04`, `.05`, and so on.
- Review candidates append `-RC1`, `-RC2`, etc.
- A new whole-number family such as `GAL-UX11` requires an explicit user-approved architectural replacement decision.
- A code change, release candidate, visual experiment, or assistant interpretation cannot create a new UX family or version on its own.
- Every locked UX revision updates the UX manifest, current-UX pointer, versioned specification, and governance archive together.

## UX10 architectural rule

For `GAL-UX10`, the tee-box environment and personalized bag visual are independent presentation layers.

- tee-box choice changes only the scenic background preference;
- bag visual choice changes only the foreground bag presentation;
- neither presentation preference may alter equipment identity, analytical state, scoring, insights, recommendations, outcomes, or governed golfer data;
- a single composited course+bag image is not an acceptable active UX10 architecture;
- production remains untouched until explicitly approved by the user.

## Rule modification

This governance rule may only be changed by an explicit future user instruction to amend or replace the GAL Governance Rule.
