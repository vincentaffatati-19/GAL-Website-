# GAL AI Driver Fitting — Mobile Flow

Status: APPROVED / LOCKED
Date: 2026-09-03

## Reference Direction
The approved mobile storyboard is the design reference for the GAL AI Driver Fitting experience. Implementation must use the exact approved GAL Option 7A Motion Arc brand assets; generated mockup logos/product imagery/metrics are illustrative only.

## Mobile Flow
1. Quick View — opportunity at a glance without forcing the golfer out of My Bag context.
2. Fit Setup — show what GAL already knows and ask only for genuinely missing/stale/context-specific inputs.
3. Target Characteristics — define golfer needs before any brands/models are introduced.
4. Recommendations — show best-matching equipment configurations after the target is established.
5. Why This Fit — evidence-backed explanation of how a configuration meets the target.
6. Compare — head-to-head comparison of relevant alternatives.
7. Next Action — buy, find a fitter, test, optimize current equipment, or save/update My Bag.
8. Outcome Tracking — compare qualifying before/after evidence after an equipment action/change.
9. Progress Over Time — longitudinal view of whether the change actually helped.

## Governing UX Rules
- One primary decision/focus per mobile screen.
- Progressive disclosure rather than compressing the desktop dashboard onto a phone.
- Thumb-friendly controls and practical 44x44 minimum touch targets.
- Preserve evidence provenance, freshness, and context.
- Tell GAL Once / Connect It Once applies throughout.
- Characteristics Before Brands must be visible in the experience, not merely a policy.
- The Target Characteristics step explicitly occurs before products are ranked or displayed.
- Optimize My Current Driver remains a peer action to purchase/test/fitter paths; GAL must not turn every fitting into a purchase funnel.
- Commerce appears after analytical recommendation and must not influence fit/ranking.
- Affiliate/commission disclosure is clear at the action/commerce stage.
- Evidence Ladder governs wording and quantified claims.
- No invented confidence percentage, performance gain, fit label, or causal equipment claim may ship without governed evidence/methodology.

## Hybrid Entry
The approved interaction model is hybrid: tapping Driver from My Bag opens a Quick View/detail panel first; the golfer may then open the full AI Driver Fit for deeper analysis.

## Editorial Integrity
The experience follows:
`Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`

Never:
`Brand/Product -> Find reasons to recommend it -> Affiliate link`

## Outcome Loop
`Quick View -> AI Fit -> Target Characteristics -> Recommendation -> Action/Change -> New Evidence -> Outcome -> Progress -> Longitudinal Learning`

## Mobile States Required for Implementation
The eventual implementation must include loading, partial-data, missing-data, stale-data, disconnected-source, no-supported-opportunity, error, and return/resume states in addition to the approved happy-path storyboard.