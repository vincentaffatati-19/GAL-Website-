# Dynamic Golfer Visual V3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace provisional/fallback golfer visuals with a governed 12-person Body + Swing-plate resolver and verify age, gender, handedness, persistence, and visual rendering behavior in the STEP17 review candidate.

**Architecture:** Keep the existing profile and resolver model, but promote every persona to a governed Body record and dedicated four-stage Swing plate. Swing frames are rendered by cropping one plate into exact quarters; left-handed presentation mirrors the photographic layer while labels remain normal HTML.

**Tech Stack:** Static HTML/CSS/JavaScript, Python structural tests, Playwright browser verification.

**Spec:** GAL Dynamic Golfer Visual System locked design in this conversation and existing STEP17.2 RC3.

## Global Constraints
- Preserve approved GAL branding and profile copy.
- 12 persona keys remain stable.
- No swing fallback records.
- Junior support remains `Under 18`; detailed adult age ranges remain unchanged.
- Handedness is presentation logic only; no race/ethnicity field or inference.
- Do not promote to production until browser and visual QA pass.

---

### Task 1: V3 visual contract
**Files:** Modify `GAL-UX10.02-STEP17.2-RC3.html`; Test `test_dynamic_visual_v3.py`.
- [x] Write failing structural test for plate-aware contract and zero fallbacks.
- [x] Run test and verify RED.
- [x] Add governed 12-person body manifest, swing plate manifest, plate crop renderer, and left-hand mirror behavior.
- [x] Run structural test and verify GREEN.

### Task 2: Browser resolver verification
**Files:** Create `test_dynamic_visual_browser_v3.py` and browser screenshot.
- [x] Test all gender/age resolver families and both handedness values.
- [x] Verify immediate change, save/reload persistence, and zero JS console errors.
- [x] Capture verification screenshot.

### Task 3: Review candidate packaging
**Files:** Create `GAL-UX10.02-STEP17.3-DYNAMIC-VISUAL-RC.html`, QA report, asset manifest.
- [x] Preserve original RC3 unchanged.
- [x] Generate final QA report with pass/fail by persona family and unresolved production-storage caveats.
- [x] Package downloadable RC and review artifacts.
