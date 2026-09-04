# GAL UX Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconcile the My GAL portal implementation to the latest approved tee-box, Golfer Profile, My Bag, and Driver AI Fitting UX while preserving validated data/security architecture.

**Architecture:** Keep the existing shared Supabase/equipment/fitting clients and replace only the golfer-facing shell/rendering layer with components that implement the locked UX. Add Profile as a secondary authenticated route. Ship four reviewable release commits (RC-UX1 through RC-UX4) with stage-specific tests and exact-head preview targets.

**Tech Stack:** TypeScript, Vite, Vitest, Supabase JS, static HTML/CSS, Vercel Preview deployments.

**Spec:** `docs/superpowers/specs/2026-09-04-gal-ux-reconciliation-release-design.md`

## Global Constraints
- Exact approved Motion Arc asset only; no generated or substitute GAL logo.
- Primary navigation stays Today | My Bag | Insights | Guides | Progress.
- Profile is secondary account/product access, not a sixth primary navigation item.
- No invented scores, yardage, valuation, progress percentage, confidence, or optimized states.
- Characteristics Before Brands remains a hard ordering rule.
- Registered/subscriber analytical truth is identical; entitlements only add capabilities.
- Browser must not contain service-role material.
- Production remains untouched.

---

### Task 1: RC-UX1 — Tee Box Today Experience

**Files:**
- Modify: `portal/src/main.ts`
- Modify: `portal/src/surfaces/today.ts`
- Modify: `portal/src/styles/portal.css`
- Create: `portal/src/surfaces/teeBox.ts`
- Test: `portal/src/__tests__/teeBoxToday.test.ts`
- Test: `portal/src/__tests__/portalUxContract.test.ts`

**Interfaces:**
- Consumes: existing `renderTodaySurface()`, `fetchGolferInsights()`, `renderMyBag()` and locked brand constants.
- Produces: `renderTeeBoxToday(): Promise<string>` and a shell with profile access plus locked five-part navigation.

- [ ] **Step 1: Write failing UX contract tests**
Assert the rendered Today experience contains a tee-box hero, bag hero, Bag Status, Next Opportunity, Bag Value, How My Bag Works, Quick Actions, Recent Insight, Progress at a Glance, profile link, and locked five-part nav. Assert no sample metric strings are hard-coded.

- [ ] **Step 2: Run targeted tests and confirm failure**
Run `pnpm vitest run src/__tests__/teeBoxToday.test.ts src/__tests__/portalUxContract.test.ts` from `portal/`.

- [ ] **Step 3: Implement minimal RC-UX1 rendering**
Create `teeBox.ts` with honest governed/empty states and update `main.ts` so Today uses it. Add secondary `/portal/profile` link in the header. Use CSS-only course environment treatment behind the exact approved bag/brand content; do not claim a real course.

- [ ] **Step 4: Add responsive styling**
Preserve bag-first visual hierarchy, 44x44 targets, desktop hero composition and mobile bottom navigation.

- [ ] **Step 5: Run full portal test/build/security gate**
Run tests, TypeScript/Vite build, and service-role scan.

- [ ] **Step 6: Commit as RC-UX1**
Commit message: `feat: release RC-UX1 tee box My GAL experience`.

---

### Task 2: RC-UX2 — Graphical Golfer Profile

**Files:**
- Modify: `portal/src/router.ts`
- Modify: `portal/src/main.ts`
- Create: `portal/src/profile/types.ts`
- Create: `portal/src/profile/client.ts`
- Create: `portal/src/profile/render.ts`
- Create: `portal/src/profile/connect.ts`
- Modify: `portal/src/styles/portal.css`
- Test: `portal/src/__tests__/profileRoute.test.ts`
- Test: `portal/src/__tests__/golferProfileUx.test.ts`

**Interfaces:**
- Consumes: Supabase session boundary and `gal_profile_facts` via existing browser-safe client patterns.
- Produces: `/portal/profile`, `renderGolferProfile(): Promise<string>`, five graphical profile areas plus Connect Your Golf.

- [ ] **Step 1: Write failing profile route and UX tests**
Assert profile route resolves; output contains Build Your GAL Golfer, You, Your Game, Your Swing, Your Miss, Where You Play, Connect Your Golf, Tell GAL Once, Connect It Once, completeness-as-coverage copy, provenance/freshness states, and no unsupported live integration claims.

- [ ] **Step 2: Run targeted tests and confirm failure**
Run the two new tests.

- [ ] **Step 3: Implement browser-safe profile fact reader**
Read only the authenticated golfer's `gal_profile_facts`, preserving source/date/quality fields available from the current schema and failing safely when unavailable.

- [ ] **Step 4: Implement graphical profile hub**
Use a central golfer silhouette/representation placeholder built from accessible HTML/CSS, five tappable profile sections, graphical wrist-to-floor guidance, shot-shape lane, strike-zone grid, environment cards, and Connect Your Golf cards. Do not infer demographic values that are not present.

- [ ] **Step 5: Implement progressive completion**
Calculate completeness only as count of known governed profile categories; label it data coverage, never ability/fit quality.

- [ ] **Step 6: Run full portal test/build/security gate**
Run all tests/build/security scan.

- [ ] **Step 7: Commit as RC-UX2**
Commit message: `feat: release RC-UX2 graphical golfer profile`.

---

### Task 3: RC-UX3 — My Bag + Driver AI Fitting UX

**Files:**
- Modify: `portal/src/bag/render.ts`
- Modify: `portal/src/fitting/driver/render.ts`
- Modify: `portal/src/styles/portal.css`
- Test: `portal/src/__tests__/myBagUx.test.ts`
- Test: `portal/src/__tests__/driverFitUx.test.ts`

**Interfaces:**
- Consumes: existing governed bag and Driver AI Fit read models.
- Produces: bag hero/category layout and nine-step Driver fitting workspace while preserving analytical order.

- [ ] **Step 1: Write failing My Bag visual-contract tests**
Assert category targets, unknown/incomplete states, bag-guide access, and no unsupported positive-fit labels.

- [ ] **Step 2: Write failing Driver flow-order test**
Assert Quick View → Fit Setup → Target Characteristics → Recommendations → Why This Fit → Compare → Next Action → Outcome Tracking → Progress Over Time and that target characteristics precede brands/models.

- [ ] **Step 3: Implement My Bag hero treatment**
Render actual known categories from the bag client, with honest missing-category/configuration states and contextual actions.

- [ ] **Step 4: Implement Driver fitting workspace**
Refactor current Driver renderer into the locked nine-step mobile-first progression. Preserve limited/readiness/compatibility failure states and Keep/Adjust/Reconfigure/Replace peer actions.

- [ ] **Step 5: Run full portal test/build/security gate**
Run all tests/build/security scan.

- [ ] **Step 6: Commit as RC-UX3**
Commit message: `feat: release RC-UX3 My Bag and Driver fitting UX`.

---

### Task 4: RC-UX4 — Integrated Candidate and Staging Gate

**Files:**
- Modify: `portal/src/main.ts`
- Modify: `portal/src/entitlements/*` only if needed for display capability wiring
- Add/modify integration tests under `portal/src/__tests__/`
- Add: `vercel.json` if absent on this branch, using the already-tested portal build/rewrite contract
- Update: Wave 3 acceptance records to supersede the rejected UX-incomplete candidate.

**Interfaces:**
- Consumes: RC-UX1/2/3 surfaces plus existing guide/insight/progress/entitlement contracts.
- Produces: one integrated preview candidate for registered and subscriber smoke testing.

- [ ] **Step 1: Add integrated registered/subscriber equivalence tests**
Assert identical equipment facts/readiness/order with only additive capability differences.

- [ ] **Step 2: Add Tell GAL Once reuse/provenance integration tests**
Assert profile/guide reuse does not create contradictory equipment truth and reused values remain visible/editable where material.

- [ ] **Step 3: Add route/mobile/brand acceptance tests**
Assert all locked routes, exact brand asset use, profile secondary access, and mobile navigation contract.

- [ ] **Step 4: Run full CI gate on exact RC-UX4 head**
All unit tests, TypeScript build, Vite build, service-role scan.

- [ ] **Step 5: Deploy exact-head Vercel Preview**
Require compiled portal output and `/portal/*` SPA rewrite. Do not accept a raw-source deployment.

- [ ] **Step 6: Smoke-test review routes**
Test `/portal/`, `/portal/profile`, `/portal/bag`, `/portal/insights?fit=driver`, `/portal/guides?category=driver`, `/portal/progress`.

- [ ] **Step 7: Record final UX reconciliation acceptance**
Mark PASS only when exact-head preview matches the locked UX direction and technical gates remain green.

- [ ] **Step 8: Commit as RC-UX4**
Commit message: `feat: release RC-UX4 integrated UX candidate`.

## Review Links
After each RC commit, capture and report:
- GitHub commit/PR link;
- exact Vercel Preview URL when available;
- route-specific review links for the surfaces introduced in that RC.

No RC is visually accepted without a working preview link.