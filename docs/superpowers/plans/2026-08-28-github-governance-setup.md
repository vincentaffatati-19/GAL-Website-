# GAL GitHub Governance Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace direct production uploads with a governed feature → develop → release → main workflow and establish the first Golfer Intelligence feature branch.

**Architecture:** Keep `main` as the GitHub Pages production branch, integrate work through `develop`, isolate new work in `feature/*`, and promote verified release candidates through `release/*`. Repository files document and validate the process; GitHub branch protection/rulesets remain the final enforcement layer.

**Tech Stack:** GitHub branches, pull requests, GitHub Actions, flat GitHub Pages site, Supabase/PostgreSQL backend planning.

**Spec:** `docs/GAL_STORAGE_AND_DEPLOYMENT_POLICY.md`

## Global Constraints

- `main` is production only.
- `develop` is integrated development.
- `feature/*` is isolated feature work.
- `release/*` is the production release-candidate path.
- Production golfer data is excluded from development/preview unless sanitized/anonymized.
- No secrets are committed to Git.
- Shared golfer/user and industry/customer portal changes are verified together.

---

### Task 1: Repository workflow governance

**Files:**
- Create: `CONTRIBUTING.md`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`
- Create: `.github/workflows/release-policy.yml`

- [x] Document branch and production rules.
- [x] Add the GAL pull-request verification checklist.
- [x] Add a GitHub Actions check requiring future PRs into `main` to originate from `release/*`.
- [ ] Merge the governance changes into `main` through a reviewed pull request.

### Task 2: GitHub branch protection

**Files:** Repository settings only.

- [x] Verify current branch state and confirm `main` is presently unprotected.
- [ ] Enable GitHub branch protection/ruleset for `main` requiring pull requests and blocking direct pushes. The current ChatGPT GitHub connector does not expose branch-protection writes, so this setting requires GitHub UI/API access with ruleset-write capability.

### Task 3: Golfer Intelligence development branch

**Files:** Feature-specific files will be added in subsequent implementation work.

- [x] Create `feature/golfer-intelligence-v1` from `develop`.
- [ ] Sync the branch to the latest `develop` governance commit before feature implementation begins.
- [ ] Add Golfer Intelligence schema/specification and tests on the feature branch only.
