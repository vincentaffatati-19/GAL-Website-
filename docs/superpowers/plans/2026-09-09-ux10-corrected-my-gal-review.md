# UX10 Corrected My GAL Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the visual tee-box My Bag and golfer-facing Profile into the current UX10 integrated RC, connected to governed Profile, Bag, and recommendation services.

**Architecture:** Build `my-gal.html` and `profile.html` as thin UI surfaces over existing `GALBagAdapter`, `GALSupabaseProfileClient`, `gal_profile_snapshot()`, and `gal_profile_apply_patch()`. Share My GAL subnavigation and keep `recommendations.html` as the Bag Needs/recommendation destination. No product/Profile truth is duplicated in the UI.

**Tech Stack:** Static HTML/CSS/JavaScript, Supabase JS 2.116.0, existing UX10 Profile RPCs, existing GAL recommendation and bag adapters.

**Spec:** `docs/superpowers/specs/2026-09-09-ux10-corrected-my-gal-review-design.md`

## Global Constraints
- Branch from `codex/ux10-02-step17-18-integrated-rc`; staging review only.
- Preserve `GAL-REC-1.0` and canonical product IDs.
- Use publishable Supabase key only; no service-role credential.
- Empty Profile and empty Bag are honest states; no demo substitution.
- Profile writes use `gal_profile_apply_patch()` with `SELF_REPORTED`, `profile_form`, and global scope.
- Existing Driver/Fairway-Hybrid governed media and remaining Mizuno holds are unchanged.

---

### Task 1: Add regression contracts for restored My GAL surfaces

**Files:**
- Create: `tests/test-ux10-my-gal-review.js`

**Interfaces:**
- Consumes: static `my-gal.html`, `profile.html`, `recommendations.html`.
- Produces: review contract that requires tee-box scene, bag stage, Profile destination, recommendation destination, and Profile save RPC wiring.

- [ ] **Step 1: Write the failing test**
Assert `my-gal.html` contains `id="teeScene"`, `id="bagStage"`, `data-tee=`, links to `profile.html` and `recommendations.html`; assert `profile.html` contains the launch field IDs and loads `profile__app.js`; assert `profile__app.js` calls `gal_profile_apply_patch` and reloads `gal_profile_snapshot`.
- [ ] **Step 2: Run test to verify it fails**
Run `node tests/test-ux10-my-gal-review.js`; expect missing-file/assertion failure.
- [ ] **Step 3: Commit the test**
Commit message: `test: define corrected UX10 My GAL review contract`.

### Task 2: Restore tee-box My Bag view

**Files:**
- Create: `my-gal.html`
- Create: `my-gal__styles.css`
- Create: `my-gal__app.js`

**Interfaces:**
- Consumes: `GALBagAdapter.load()` / `.save()` when available; local `gal_equipment_bag_v1` fallback.
- Produces: scene model `{items, clubCount, categoryState, gaps}` rendered into the tee-box scene.

- [ ] **Step 1: Build scene markup and responsive styling**
Use a course/tee-box CSS scene, central bag silhouette/stage, tee controls, category status rail, and intelligence rail. Keep the GAL global header/footer and add My GAL subnavigation.
- [ ] **Step 2: Implement bag projection**
Normalize existing bag items by canonical ID/category, count only club records toward 14, derive category state and open-gap summary, and label browser-local fallback when remote adapter is absent.
- [ ] **Step 3: Run the contract test**
Run `node tests/test-ux10-my-gal-review.js`; My Bag assertions must pass.
- [ ] **Step 4: Commit**
Commit message: `feat: restore UX10 tee-box My Bag review`.

### Task 3: Restore governed Golfer Profile UI

**Files:**
- Create: `profile.html`
- Create: `profile__styles.css`
- Create: `profile__app.js`

**Interfaces:**
- Consumes: `GALSupabaseProfileClient.currentUser()`, `.ready()`, `.sendMagicLink()`, `.signOut()`; RPC `gal_profile_snapshot()`; RPC `gal_profile_apply_patch(args)`.
- Produces: saved Profile revisions containing launch facts used by `GAL-REC-1.0`.

- [ ] **Step 1: Build signed-out/signed-in Profile surface**
Signed-out state offers passwordless email. Signed-in state shows Profile completeness, revision, and editable sections.
- [ ] **Step 2: Map fields to governed areas**
`game`: `handedness`, `handicap_index`, `skill_band`; `swing`: `driver_swing_speed_mph`, `driver_launch_preference`; `miss`: `driver_primary_miss`; `play`: `top_bag_target_yards`, `home_play_location_text`.
- [ ] **Step 3: Implement save sequence**
For each changed area call `gal_profile_apply_patch` with JSON facts, units (`mph`, `yards`, `index` where applicable), `SELF_REPORTED`, `profile_form`, `My Golfer Profile`, global scope. After all saves, call `gal_profile_snapshot()` and rerender revision/completeness.
- [ ] **Step 4: Preserve form values on error**
Show RPC error inline; do not replace typed values with defaults.
- [ ] **Step 5: Run contract test**
Run `node tests/test-ux10-my-gal-review.js`; Profile assertions must pass.
- [ ] **Step 6: Commit**
Commit message: `feat: restore governed UX10 Golfer Profile`.

### Task 4: Connect review navigation and recommendation handoff

**Files:**
- Modify: `recommendations.html`
- Modify: `recommendations__app.js` only if needed for fresh snapshot behavior.

**Interfaces:**
- Consumes: fresh `GALRecommendationProfile.load()` on page boot/auth change.
- Produces: visible My GAL navigation between My Bag, Profile, and Bag Needs/Recommendations.

- [ ] **Step 1: Add My GAL subnavigation**
Links: My Bag -> `my-gal.html`, Golfer Profile -> `profile.html`, Bag Needs -> `recommendations.html`.
- [ ] **Step 2: Verify recommendation boot reloads Profile**
Do not cache Profile across navigation; existing `load()` call must fetch current `gal_profile_snapshot()`.
- [ ] **Step 3: Run existing recommendation regression**
Run `node tests/test-recommendations.js`, `node tests/test-recommendation-runtime.js`, and `node tests/test-recommendation-auth.js`; expect PASS.
- [ ] **Step 4: Commit**
Commit message: `feat: connect corrected My GAL review flow`.

### Task 5: Full staging verification and review PR

**Files:**
- Create: `docs/ux10.02/GAL-UX10.02-CORRECTED-MY-GAL-REVIEW-QA.md`

**Interfaces:**
- Consumes: full branch and staging deployment.
- Produces: reviewable PR against `codex/ux10-02-step17-18-integrated-rc`.

- [ ] **Step 1: Run all browser/runtime contracts**
Run the new My GAL test plus Driver image, Fairway/Hybrid remediation, recommendation engine/runtime/auth tests.
- [ ] **Step 2: Verify staging Profile security**
Confirm authenticated execution and anon denial for `gal_profile_snapshot` and `gal_profile_apply_patch`.
- [ ] **Step 3: Verify Vercel deployment**
Require READY/success and HTTP 200 for `my-gal.html`, `profile.html`, and `recommendations.html` through the authenticated Vercel fetch channel; state SSO limits explicitly if a route cannot be fetched.
- [ ] **Step 4: Open review PR**
Base `codex/ux10-02-step17-18-integrated-rc`; do not merge.
