# GAL UX5 — My GAL Intelligence Dashboard

**Status:** USER-APPROVED / LOCKED  
**Date:** 2026-09-04  
**UX identifier:** `GAL-UX5-MID`  
**First review candidate:** `GAL-UX5-MID-RC1`  
**Product surface:** Authenticated My GAL registered-user and subscriber experience

## 1. Decision

The user-approved visual configuration supplied on 2026-09-04 is the current authoritative GAL UX direction and is named **GAL UX5 — My GAL Intelligence Dashboard** (`GAL-UX5-MID`).

This specification supersedes `RC-UX4` as the visual authority and makes the 2026-09-02 locked tee-box + interactive-bag specification more exact. Where this document is silent, the approved 2026-09-02 tee-box specification and 2026-08-31 My GAL Equipment Intelligence product specification remain in force.

The implementation must preserve the existing governed-data, longitudinal-insight, security, account, and registered/subscriber shared-component contracts. This is a presentation and interaction architecture decision, not permission to invent analytical facts.

## 2. Authoritative visual reference

The locked visual reference is the user-supplied image:

- filename: `My Gal Dashboard with landing.png`
- dimensions: 1536 × 1024 pixels
- SHA-256: `3f0cf896cb88632d6bcf0f780de110bad6516b3264a8755de2c932edbca44f84`

The image is authoritative for desktop composition, hierarchy, density, visual tone, panel relationships, and progressive disclosure. Production implementation may refine typography, spacing, accessibility, loading behavior, and responsive behavior without changing the governing experience.

## 3. Product identity

The experience remains **My GAL**, not a generic analytics dashboard or account portal.

Primary navigation is locked as:

`Today | My Bag | Insights | Guides | Progress`

Golfer Profile/account access remains separately accessible and does not replace the five-part primary navigation.

The locked brand system is Option 7A Motion Arc / GAL Custom Hybrid, using GAL Navy, GAL Orange, white/light neutrals, and the approved logo assets. Do not substitute an older logo, a CSS approximation, generated logo, generic text mark, or merchandise-only identity.

## 4. Desktop composition

The approved desktop architecture has three coordinated experience zones.

### 4.1 My GAL bag environment

The left/main zone presents:

- My GAL title and concise personal-equipment positioning;
- tee-box/environment selection;
- a realistic, premium golf bag as the hero object;
- equipment-category status rail for Driver, Fairway/3 Wood, Hybrid, Irons, Wedges, Putter, and Ball;
- compact Bag Status;
- Next Opportunity;
- Bag Value;
- Customize My Bag;
- Bag User's Guide;
- Quick Actions;
- Recent Insight;
- Progress at a Glance.

The background/scene must support the feeling that the golfer is standing with their equipment in a premium tee-box environment. The scene is part of the product experience, not generic wallpaper.

The bag and club imagery should be realistic and polished. Crude hand-built golfer, club, bag, or course illustrations are specifically rejected for this UX.

### 4.2 Contextual club intelligence surface

Selecting a club/category opens a large contextual intelligence panel while preserving the bag context. The interaction should feel like inspecting the selected club inside My GAL, not navigating into an unrelated application.

The selected-club surface uses the tab model:

`Overview | Why It Matters | Recommendations | Compare`

The Overview pattern may include, when governed data exists:

- current golfer/equipment snapshot;
- measured/observed performance metrics;
- performance versus an evidence-backed target or optimal range;
- key insights;
- factors holding performance back;
- recommended next action;
- mark/resolution state where supported by the longitudinal lifecycle.

### 4.3 Explanation / exploration rail

The right-side explanatory pattern is a progressive-disclosure system that helps the golfer understand what is behind the headline insight. Candidate modules include:

- Why It Matters;
- Recommendations;
- Compare;
- Inspect & Specs;
- Real-World Results.

These modules are conditional. They appear only when GAL has governed data or an approved source/method to support them.

## 5. Interaction model

The governing loop is:

`See my bag -> identify what needs attention -> select a club -> understand why -> compare/review options -> take an action -> track what happened`

The visual experience should make this loop obvious without forcing a tutorial.

Club/category markers must communicate status quickly. Status labels such as Optimize, Good, Needs Attention, Watching, or Not Evaluated must map to governed underlying evidence. Absence of a negative insight is not proof of optimization.

The detailed panel is progressive disclosure: concise first, supporting evidence and options second. The golfer should retain spatial/contextual awareness of the bag during exploration.

## 6. Instructional pattern

The lower desktop composition includes a concise `How It Works` sequence that communicates the core interaction in plain golfer language, for example:

1. Tap a Club
2. See Why
3. Explore
4. Take Action
5. Track Progress

A companion `Works for Every Club` pattern reinforces that the same mental model applies across the bag.

These are product-education elements, not separate primary navigation destinations.

## 7. Responsive/mobile behavior

Desktop composition is locked, but mobile is an intentional adaptation rather than a scaled-down screenshot.

Mobile must preserve this hierarchy:

`My GAL / tee-box -> bag -> category/status -> highest-priority opportunity -> club detail -> action -> progress`

Mobile requirements include:

- persistent five-part navigation, using bottom navigation where appropriate;
- practical 44×44 px or larger touch targets;
- the bag remains visually meaningful rather than collapsing into a thumbnail;
- club intelligence may become a bottom sheet/full-screen detail treatment;
- status markers cannot obscure the bag;
- Bag Status and Next Opportunity remain quickly reachable;
- text contrast and reduced-motion preferences are respected;
- no desktop-only interaction is required to use the product.

A dedicated mobile composition still requires visual review before UX5 is considered production-complete.

## 8. Data and truthfulness contract

The locked screenshot contains presentation examples. It does not authorize fabricated golfer data.

Any visible value such as driver speed, launch angle, spin rate, carry distance, yardage gain, bag value, trade-in value, profile completeness, optimization percentage, recommendations, comparison results, or real-world outcomes must be backed by a governed source and calculation policy.

If the data is unavailable, stale, insufficient, or methodologically unapproved, the interface uses an honest incomplete/learning state.

Do not infer `Optimized` from silence. Do not invent a recommendation to fill a panel. Do not manufacture confidence, progress, valuation, or real-world-result claims.

## 9. Existing architecture retained

UX5 does not alter the approved application/security architecture:

- `/portal/` remains the authenticated SPA boundary;
- Supabase Auth remains the identity/session authority;
- browser reads remain golfer-safe and RLS-protected;
- service-role credentials remain server-only;
- trusted mutations remain allowlisted server-side/Edge Function contracts;
- internal governance/learning data remains inaccessible to the browser;
- registered and subscriber experiences share components and are updated together;
- development/preview/staging remain separate from production;
- production promotion requires explicit user approval.

## 10. Implementation strategy

The approved implementation strategy is **rebuild the UX5 presentation around this configuration while preserving governed GAL logic underneath**.

Do not attempt to preserve RC-UX4's visual architecture merely because the code already exists. Reuse data contracts, safe business logic, tests, and shared components where they remain compatible; replace presentation structures that conflict with UX5.

Avoid a second parallel product implementation. UX5 becomes the single target experience after review and controlled promotion.

## 11. Acceptance criteria

`GAL-UX5-MID-RC1` is ready for visual review when:

1. the desktop composition clearly matches the locked visual hierarchy;
2. the exact approved GAL logo/brand assets render correctly;
3. realistic bag/equipment imagery replaces crude illustration primitives;
4. top navigation is Today | My Bag | Insights | Guides | Progress;
5. club/category status selection works across the bag;
6. contextual club intelligence opens without losing bag context;
7. Overview | Why It Matters | Recommendations | Compare are implemented as the core detail model;
8. explanation modules do not fabricate unsupported data;
9. My Bag, Today, and shared registered/subscriber surfaces remain synchronized;
10. accessibility and responsive behavior are verified;
11. all portal tests and build/security checks pass;
12. production remains untouched until explicit approval.

## 12. UX authority and anti-drift rule

UX authority is not derived from the most recent code or release candidate.

The repository root contains:

- `GAL_UX_MANIFEST.json` — machine-readable current-UX authority;
- `GAL_UX_CURRENT.md` — human-readable current-UX authority.

If a future implementation, assistant session, release candidate, or old specification conflicts with the current lock, the conflict must be surfaced and reconciled. It must not silently redesign the product.

A later user-approved UX decision may supersede UX5, but it must receive a new identifier and update the manifest/pointer at the same time.

## 13. Why this lock exists

A prior approved tee-box UX specification already existed on 2026-09-02, but later work drifted toward a different RC-UX4 visual treatment. The failure was an authority/retrieval discipline problem: the existing locked specification was not treated as the mandatory source of truth before the newer candidate was changed.

UX5 therefore adds explicit versioning and a single current-UX pointer so that future work can distinguish approved UX from merely recent implementation state.
