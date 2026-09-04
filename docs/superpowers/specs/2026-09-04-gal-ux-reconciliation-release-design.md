# GAL UX Reconciliation Release Design

Status: USER-APPROVED IMPLEMENTATION DIRECTION
Date: 2026-09-04
Branch: `ux-reconciliation-rc`

## Goal
Bring the deployed My GAL experience forward to the latest approved/locked UX specifications without weakening the validated equipment, privacy, RLS, fitting, and entitlement architecture.

## Source of Truth
This release reconciles implementation to these approved specifications:
- `2026-09-02-my-gal-tee-box-ux-design.md`
- `2026-09-03-gal-mobile-golfer-profile-ux.md`
- `2026-09-03-gal-ai-driver-fitting-mobile-flow.md`
- `2026-09-03-gal-ai-fitting-product-model.md`
- `2026-08-31-my-gal-equipment-intelligence-product-design.md`

## Release Stages

### RC-UX1 — My GAL Today / Tee Box
Implement the approved premium tee-box composition as the real authenticated landing experience. Preserve the locked five-part primary navigation: Today | My Bag | Insights | Guides | Progress. Add profile/account access separately.

Required composition:
- exact approved Motion Arc brand asset;
- premium course/tee-box environment treatment;
- centered bag hero;
- Bag Status;
- Next Opportunity;
- category markers for Driver/Fairway/Hybrid/Irons/Wedges/Putter/Ball when present or honestly unknown;
- Bag Value placeholder state only when governed valuation is unavailable;
- How My Bag Works;
- Quick Actions;
- Recent Insight;
- Progress at a Glance;
- mobile bottom navigation and 44x44 practical targets.

No invented score, yardage, valuation, progress percentage, confidence, or optimized state.

### RC-UX2 — Build Your GAL Golfer
Add `/portal/profile` as a graphical authenticated experience without replacing the five-part product navigation.

Required structure:
- Build Your GAL Golfer entry;
- profile completeness as data coverage, not golfer quality;
- You;
- Your Game;
- Your Swing;
- Your Miss;
- Where You Play;
- Connect Your Golf;
- Tell GAL Once / Connect It Once messaging;
- source/freshness/data-quality treatment;
- graphical measurement, shot-shape and strike-zone patterns;
- adaptive representation contract for age band, gender/presentation and handedness;
- progressive completion and resume-safe UX.

Connected-app examples remain illustrative unless an approved integration is actually available.

### RC-UX3 — My Bag + Driver AI Fitting
Align My Bag and Driver fitting with the approved visual language and mobile flow.

Driver fitting order:
1. Quick View
2. Fit Setup
3. Target Characteristics
4. Recommendations
5. Why This Fit
6. Compare
7. Next Action
8. Outcome Tracking
9. Progress Over Time

Characteristics Before Brands is a hard editorial-integrity rule. Keep/Adjust/Reconfigure/Replace remain peer actions. Missing evidence narrows or blocks recommendations.

### RC-UX4 — Integrated Candidate
Run the same component set for registered and subscriber users, with subscription capabilities additive only. Verify Tell GAL Once reuse, public/authenticated guide continuity, Driver fitting, profile links, My Bag, Today/Insights/Progress, mobile behavior, brand assets, privacy/RLS boundaries, build security, and exact-head staging preview.

## Data and Trust Rules
- Existing Supabase Auth remains identity authority.
- Browser uses publishable key + RLS; no service-role browser material.
- Shared governed Equipment Knowledge contracts remain authoritative.
- No page creates independent product truth.
- Unknown is not good fit.
- AI_FIT_LIMITED remains distinct from AI_FIT_READY.
- Connected or reused profile values must preserve provenance/freshness where material.
- Commercial metadata remains downstream from analytical rank.
- Registered/subscriber users share analytical truth.

## Visual Review Requirement
Each release stage must be separately reviewable before the next stage is considered accepted. Preferred review artifact is a Vercel Preview deployment for the exact stage commit. If Vercel quota blocks a stage preview, the stage remains technically complete but visually unaccepted until a preview becomes available.

## Production Boundary
No production deployment or production Supabase migration is authorized by this release design. Production promotion remains a separate explicit gate.