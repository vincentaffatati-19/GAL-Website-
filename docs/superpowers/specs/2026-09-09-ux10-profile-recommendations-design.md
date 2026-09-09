# UX10 Profile Recommendations v1 — Design

## Goal
Rebuild GAL equipment recommendations on the UX10 Profile architecture using governed Driver and Fairway Woods/Hybrid product projections as authoritative product truth.

## Approved experience
Use two views of one recommendation result:
1. **Bag Needs** (default): determine the equipment job first, then rank products across eligible categories. Driver is a dedicated need; top-of-bag distance compares Fairway Woods and Hybrids together.
2. **Equipment Categories** (secondary): browse the same Profile-driven ranking by Driver, Fairway Wood, or Hybrid.

## Data boundaries
- Driver product truth comes from `GAL_DRIVERS` / Driver Image Governance v2.0 projection.
- Fairway/Hybrid product truth comes from `GALFairwayHybridData` / Fairway-Hybrid Image Governance v2.0 projection.
- Recommendation records contain canonical product IDs, role/category, score/confidence, reasons/tradeoffs, estimated carry where applicable, and engine version. They do **not** duplicate product model, price, specs, or media truth.
- UI hydrates each canonical ID from the governed product projection and resolves media through the category media resolver.
- Internal image-governance status codes are not recommendation-facing content.

## Profile contract
Consume UX10 `gal_profile_snapshot()` through an adapter boundary. Preferred sources are an injected `GALProfileService.snapshot()` or an existing Supabase client RPC. A clearly labeled staging preview profile is permitted only when no authenticated frontend Profile client is present. Preview data must never be represented as live golfer truth.

## Recommendation v1 inputs
Driver ranking uses current Profile facts where available: driver swing speed, primary miss, and launch preference. Top-of-bag ranking uses driver swing speed, primary miss, and target top-of-bag distance. Fairway/Hybrid fit traits remain recommendation rules, not catalog fields.

## UX
Each card shows Best Match/Alternative, governed image or controlled image-hold state, GAL Fit score, model hydrated from product truth, price or em dash, primary fit reason, expandable explanation, Compare, and Add to Bag. Compare is capped at three. Add to Bag uses canonical IDs, preserves the shared bag adapter boundary, enforces 14 clubs, and warns on duplicate categories.

## Release boundary
This is a staging-only feature branch. No production merge is part of this implementation. Visual acceptance must remain pending if protected preview access prevents automated verification.
