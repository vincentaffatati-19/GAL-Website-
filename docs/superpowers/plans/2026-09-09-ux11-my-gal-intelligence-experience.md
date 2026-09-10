# GAL UX11 — My GAL Intelligence Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or subagent-driven-development where available) and superpowers:test-driven-development. Execute each task RED → GREEN → REFACTOR and verify before moving on.

**Goal:** Assemble `GAL-UX11.0-RC1` from the corrected UX10.02 profile lineage and approved photographic My GAL assets, while preserving governed bag/profile/recommendation behavior and explicitly excluding the rejected UX10.03 Better Bag Scorecard hierarchy.

**Architecture:** Keep the corrected static My GAL → Golfer Profile → category recommendation logic as the implementation baseline, but replace provisional presentation and unsupported derived metrics with governed UX11 surfaces. My GAL uses independent photographic tee-box and bag presentation layers. Golfer Profile uses the locked 12-family Body/Swing resolver and native-aspect four-stage Swing presentation. Recommendation ranking remains inside equipment-category contexts only.

**Tech Stack:** Static HTML/CSS/JavaScript, existing Supabase profile RPC client, Node contract tests, browser verification through the existing preview/deployment path where available.

**Authoritative specs:**
- `docs/superpowers/specs/2026-09-09-ux11-my-gal-intelligence-experience-design.md`
- `docs/ux11/GAL-UX11-PROFILE-VISUAL-LINEAGE-AND-ROUTING-LOCK.md`
- `docs/ux11/GAL-UX11.0-RC1-ASSEMBLY-MANIFEST.yaml`
- `docs/GAL_ARTIFACT_PROVENANCE_AND_RC_ASSEMBLY_RULE.md`

## Global constraints
- Stay on `feature/ux11-my-gal-intelligence-experience`; do not merge or deploy to Production.
- Do not restore UX10.03 Better Bag Priority Index, cross-category Top 3, or invented whole-bag/category scores.
- Unknown/insufficient data stays explicit; do not fabricate Bag Health, opportunity, value, status, or recommendation evidence.
- Golf ball does not count toward the 14-club limit; duplicate-club warning behavior remains required.
- Tee-box and bag choices are presentation-only and independent.
- Reuse exact approved photographic assets from their governed lineage; no CSS-drawn scenery/bags and no regenerated approximations.
- Final profile routing follows the UX11 profile lineage lock exactly, including gender-safe unknown-age routing and both senior bands.
- Left-handed presentation mirrors photographic golfer layers only; text/stage labels remain unmirrored.
- Swing stages render at native source aspect ratio; no fixed-height/background-stretch implementation.
- External integrations and Supabase leaked-password protection remain release blockers.

---

### Task 1: Lock UX11 static contract in tests
**Files:** Create `tests/test-ux11-my-gal-intelligence.js`.
- [ ] Add assertions forbidding CSS scene/bag stand-ins and fabricated bag-health scoring.
- [ ] Add assertions requiring exact photographic scene/bag asset lineage and independent presentation selectors.
- [ ] Add assertions for five-item My GAL navigation plus separate Golfer Profile control.
- [ ] Add assertions for 12 Body/Swing routes, 50-case gender×age matrix behavior, unknown-age Male/Female, senior routing, handedness, native Swing aspect contract, and six collapsed sections.
- [ ] Add assertions forbidding Better Bag Scorecard / cross-category Top 3 hierarchy.
- [ ] Run against current UX11 branch snapshot and verify expected RED failures.

### Task 2: Replace crude My GAL presentation and unsupported bag scoring
**Files:** Modify `my-gal.html`, `my-gal__styles.css`, `my-gal__app.js`.
- [ ] Replace CSS-drawn sky/tree/fairway/tee with approved photographic tee-box image layer.
- [ ] Replace CSS/shape bag and synthetic club fan with approved GAL bag image layer.
- [ ] Add independent tee-box and bag visual selectors using exact recovered asset lineage.
- [ ] Preserve governed bag loading and 14-club count; add duplicate-club warning without fabricating evaluation status.
- [ ] Replace invented `health` score and inferred Good/Review judgments with truthful saved/missing/unknown state.
- [ ] Expose Bag Status, Next Opportunity, Bag Value, Quick Actions, Recent Insight, Progress at a Glance, and Bag User’s Guide as governed-data/explicit-hold surfaces only.
- [ ] Run Task 1 test and relevant legacy contracts; verify GREEN for My GAL slice.

### Task 3: Restore the final governed Golfer Profile visual/routing contract
**Files:** Modify `profile.html`, `profile__styles.css`, `profile__app.js`; create `profile__visuals.js` if separation improves testability.
- [ ] Preserve authenticated `gal_profile_snapshot()` / `gal_profile_apply_patch()` behavior and active revision handoff.
- [ ] Add Gender and Age Range controlled presentation inputs without inventing facts; route visual presentation through locked resolver.
- [ ] Implement all 12 persona families and Body/Swing parity.
- [ ] Implement Male/Female unknown-age aliases without age claims; neutral fallbacks remain neutral.
- [ ] Implement 65–74 and 75+ senior routing.
- [ ] Implement right-handed base and left-handed photographic-only mirroring.
- [ ] Render Address / Backswing / Impact / Finish as native-aspect source stages; mobile 2×2.
- [ ] Restore six collapsed `+ / −` profile sections and keep Your Miss reference isolated from Save controls.
- [ ] Run full routing/static contract; verify 12/12 Body, 12/12 Swing, 50/50 matrix, parity, handedness, native aspect GREEN.

### Task 4: Normalize My GAL navigation and category recommendation semantics
**Files:** Modify `my-gal.html`, `profile.html`, `recommendations.html`, related styles/apps as needed.
- [ ] Make Today / My Bag / Insights / Guides / Progress the five primary My GAL destinations.
- [ ] Keep Golfer Profile as a separate destination/control rather than a sixth tab.
- [ ] Ensure Top 3 wording/ranking appears only inside supported equipment-category contexts.
- [ ] Preserve compare and canonical Add to Bag where existing engines support them.
- [ ] Show explicit unavailable/insufficient states for unsupported category engines instead of fabricated rankings.
- [ ] Verify no UX10.03 Scorecard hierarchy/tokens remain in active UX11 surfaces.

### Task 5: RC provenance, regression, and preview verification
**Files:** Update `docs/ux11/GAL-UX11.0-RC1-ASSEMBLY-MANIFEST.yaml`; create `docs/ux11/GAL-UX11.0-RC1-QA.md` after evidence exists.
- [ ] Record implementation commit(s), exact visual asset lineage, and profile lock inheritance.
- [ ] Run all UX11 Node/static contracts plus affected legacy contracts and JS syntax checks.
- [ ] Verify source files contain zero CSS-drawn scene/bag stand-ins and zero fabricated bag-health formula.
- [ ] Verify browser preview at desktop and mobile if browser automation is available; otherwise mark browser visual gate BLOCKED/UNVERIFIED, never PASS by static substitution.
- [ ] Verify approved photographic scene/bag assets load from their exact governed lineage.
- [ ] Verify dynamic golfer Body/Swing routes, native aspect, and left-handed presentation visually where available.
- [ ] Document remaining release blockers: external platform integrations and Supabase leaked-password protection.
- [ ] Keep RC review-only; no merge/main or Production promotion.
