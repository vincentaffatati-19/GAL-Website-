# GAL UX10.02 Dashboard + Golfer Profile Activation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the governed UX10 dashboard and UX10.02 Golfer Profile active together on the website preview, using the locked Stylized Option B: Motion Arc brand system and truthful golfer data.

**Architecture:** Preserve the existing UX10 dashboard/data contracts and replace the current long-form Profile renderer with a Profile Home + focused-workspace router driven by the existing `gal_profile_facts` model. Brand assets are reconstructed deterministically from repository-safe base64 source parts and verified by SHA-256 in CI. Dashboard and Profile share the same My GAL shell and five-part primary navigation; Golfer Profile remains separate.

**Tech Stack:** TypeScript, Vite, Vitest, Supabase JS, CSS, GitHub Actions, Vercel preview.

**Spec:** `docs/superpowers/specs/2026-09-04-gal-ux10-02-golfer-profile-experience-design.md`

## Global Constraints

- Current UX family is `GAL-UX10`; current locked revision is `GAL-UX10.02`.
- Review candidate is `GAL-UX10.02-RC1`.
- Primary navigation remains `Today | My Bag | Insights | Guides | Progress`.
- Golfer Profile remains separate from primary navigation.
- Mobile Profile flow is `Profile Home -> You / Measurements -> Your Swing -> Your Miss -> Connected Golf`.
- Profile Home contains six areas: You, Your Game, Your Swing, Your Miss, Where You Play, Connected Golf.
- `Where You Play` and `Your Game` remain Profile Home areas without becoming mandatory mobile progression screens.
- Your Miss shot-shape options are exactly `Hook | Pull | Straight | Push | Slice`.
- Existing `gal_profile_facts` remains the profile-fact source.
- No fabricated golfer metrics, percentages, connection states, or derived facts.
- `Connected` may be shown only when valid connection state exists; absent a dedicated connection authority, provider cards remain unavailable/not connected rather than inferred from sample UI.
- Tee-box and bag visuals remain independent; UX10.01 dashboard architecture is inherited unchanged.
- UX10 brand authority is **Stylized Option B: Motion Arc**, built on Option 7A — GAL Custom Hybrid, using the user-supplied brand board `motion_arc_golf_analytics_brand_board(3).png` as the visual authority.
- Production remains untouched until explicit user approval.

---

### Task 1: Lock and deliver the correct UX10 brand assets

**Files:**
- Create: `GAL_BRAND_CURRENT.md`
- Modify: `GAL_UX_MANIFEST.json`
- Modify: `GAL_UX_CURRENT.md`
- Modify: `docs/superpowers/specs/2026-09-04-gal-ux10-02-golfer-profile-experience-design.md`
- Create: `portal/brand/gal-motion-arc-dark-lockup.b64.partNN`
- Create: `portal/brand/gal-motion-arc-responsive.b64.partNN`
- Modify: `portal/src/branding.ts`
- Modify: `.github/workflows/my-gal-portal-ci.yml`
- Modify: `.github/workflows/ux-preview-publish.yml`
- Test: `portal/src/__tests__/branding.test.ts`

**Interfaces:**
- Produces `BRAND_LOGO_SRC = '/portal/gal-motion-arc-dark-lockup.png'` for the dark UX10 application shell.
- Produces deterministic CI reconstruction with exact SHA-256 checks.

- [ ] **Step 1: Write failing branding tests** requiring the Motion Arc asset path and forbidding `gal-option7a-motion.jpg` as the UX10 header source.
- [ ] **Step 2: Verify the branding tests fail** on the current branch.
- [ ] **Step 3: Add repository-safe base64 source parts** for the exact crops derived from the locked brand board.
- [ ] **Step 4: Update `branding.ts` and CI reconstruction/checksum gates** to use the Motion Arc lockup.
- [ ] **Step 5: Update governance files/spec** with the exact brand-board filename, 1448×1086 dimensions, and SHA-256 `22a46b60200762203aa52a5db1942fc8a40336c0ba0ea748520c1fad1bdd5166`.
- [ ] **Step 6: Re-run branding tests** and confirm they pass.

### Task 2: Introduce the Profile workspace model

**Files:**
- Modify: `portal/src/profile/types.ts`
- Create: `portal/src/profile/model.ts`
- Test: `portal/src/__tests__/golferProfileModel.test.ts`

**Interfaces:**
- Produces `ProfileWorkspace = 'home' | 'you' | 'game' | 'swing' | 'miss' | 'environment' | 'connected'`.
- Produces `profileWorkspaceFromParams(searchParams)` and governed fact-selection helpers.
- Produces data-quality classification helpers for `Measured`, `Observed`, `Self-Reported`, `Inferred / Estimated`.

- [ ] **Step 1: Write failing model tests** for six Profile Home areas, workspace routing, exact miss-shape labels, and data-quality mapping.
- [ ] **Step 2: Verify tests fail** because the model helpers do not exist.
- [ ] **Step 3: Implement the smallest model helpers** needed to satisfy the tests.
- [ ] **Step 4: Re-run model tests** and confirm pass.

### Task 3: Replace long Profile page with Profile Home + focused workspaces

**Files:**
- Modify: `portal/src/profile/render.ts`
- Modify: `portal/src/main.ts`
- Test: `portal/src/__tests__/golferProfileUx.test.ts`

**Interfaces:**
- `renderGolferProfile(searchParams?: URLSearchParams): Promise<string>` selects one focused workspace.
- Profile Home links use `/portal/profile?section=<workspace>`.
- Main route passes current search params into the Profile renderer.

- [ ] **Step 1: Rewrite Profile UX tests first** to require Profile Home, six area links, focused screens, and absence of the old one-long-page composition.
- [ ] **Step 2: Verify the tests fail** against the existing renderer.
- [ ] **Step 3: Implement Profile Home** with truthful golfer identity fallback, coverage language, six area cards, Tell GAL Once, and data-quality legend.
- [ ] **Step 4: Implement focused `You` and `Your Game` workspaces** from governed profile facts with missing/freshness states.
- [ ] **Step 5: Implement focused `Your Swing` workspace** with Driver/7-Iron selector, governed metric cards only, `View All Swing Data`, and a connect/import next action when data is missing.
- [ ] **Step 6: Implement focused `Your Miss` workspace** with finish-direction control, exact `Hook | Pull | Straight | Push | Slice`, strike-location selector, and `Save My Miss Profile` presentation without falsely claiming persistence until a governed mutation exists.
- [ ] **Step 7: Implement focused `Where You Play` workspace** using usual environment facts while keeping specific test-session conditions separate.
- [ ] **Step 8: Implement focused `Connected Golf` workspace** with GHIN/Arccos/TrackMan/Garmin/other-source cards in truthful unavailable/not-connected states unless valid connection authority exists; show `What GAL Learned` only from actual sourced facts.
- [ ] **Step 9: Re-run Profile UX tests** and confirm pass.

### Task 4: Match the locked responsive Profile visual system

**Files:**
- Create: `portal/src/styles/ux10-profile.css`
- Modify: `portal/src/main.ts`
- Test: `portal/src/__tests__/golferProfileUx.test.ts`

**Interfaces:**
- Adds focused Profile shell/card styling without altering dashboard scene behavior.
- Keeps mobile five-part bottom nav viewport anchored.

- [ ] **Step 1: Add failing structural/style assertions** for dedicated UX10 Profile classes and mobile focused-workspace behavior.
- [ ] **Step 2: Verify failure** before CSS/import changes.
- [ ] **Step 3: Add `ux10-profile.css`** with dark navy workspace headers, orange actions, responsive master/detail cards, 44px touch targets, data-quality chips, mobile fixed bottom-nav compatibility, and accessible focus states.
- [ ] **Step 4: Import the stylesheet from `main.ts`** and update the shell version marker to `GAL-UX10.02-RC1`.
- [ ] **Step 5: Re-run Profile UX tests** and confirm pass.

### Task 5: Verify dashboard + Profile coexist without UX10 regression

**Files:**
- Test: `portal/src/__tests__/candidateVisuals.test.ts`
- Test: `portal/src/__tests__/branding.test.ts`
- Test: `portal/src/__tests__/golferProfileUx.test.ts`
- Test: existing UX10 dashboard/personalization tests

**Interfaces:**
- Dashboard remains `Today` and inherits UX10.01 independent tee-box/bag behavior.
- Profile uses UX10.02 focused workspaces and correct Motion Arc brand asset.

- [ ] **Step 1: Add/adjust regression assertions** proving dashboard and Profile share one branded shell while tee-box and bag state remain independent.
- [ ] **Step 2: Run the full portal test suite** with `pnpm test:run`.
- [ ] **Step 3: Run `pnpm build`** and verify TypeScript/Vite production build succeeds.
- [ ] **Step 4: Run security/anti-fabrication scans** used by CI and ensure retired combined/incorrect brand assets are not active in built JS/HTML.

### Task 6: Publish a reviewable active website preview

**Files:**
- Modify as needed: `.github/workflows/ux-preview-publish.yml`
- Generated by CI: `preview/portal/**`

**Interfaces:**
- Publishes the verified `GAL-UX10.02-RC1` build to the feature-branch preview only.
- Vercel preview exposes `/portal/` dashboard and `/portal/profile` Profile experience.

- [ ] **Step 1: Confirm CI reconstructs Motion Arc + UX10 assets and all tests/build gates are green.**
- [ ] **Step 2: Publish the verified static preview artifact.**
- [ ] **Step 3: Verify `/portal/` loads the UX10 dashboard with correct Motion Arc logo.**
- [ ] **Step 4: Verify `/portal/profile` loads Profile Home and each focused section route.**
- [ ] **Step 5: Verify mobile navigation and focused Profile screens in a browser.**
- [ ] **Step 6: Provide the user the live review URL; do not promote production.**
