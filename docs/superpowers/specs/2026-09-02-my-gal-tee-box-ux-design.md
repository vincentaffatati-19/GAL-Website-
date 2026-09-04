# My GAL Tee Box UX Design

Status: USER-APPROVED VISUAL DIRECTION / UX SPEC FOR REVIEW  
Date: 2026-09-02  
Product surface: My GAL authenticated landing experience  
Supersedes visual-layout assumptions in the 2026-08-31 My GAL product design where this document is more specific.

## 1. Locked Experience Concept

My GAL uses a premium golf-course tee-box environment as the authenticated home experience. The approved visual reference is the latest user-approved mockup from the 2026-09-02 design review: a coastal tee-box scene with a large centered GAL golf bag, club-category status callouts, Bag Status and Next Opportunity at left, Bag Value and Bag User's Guide below the hero, Quick Actions / Recent Insight / Progress below that, and persistent Today | My Bag | Insights | Guides | Progress navigation.

The experience must feel like the golfer is standing on a tee with their equipment, not like a conventional analytics dashboard with a golf photograph pasted behind it.

The governing UX idea is:

`Tee Box Environment -> My Bag -> What GAL Sees -> Highest-Priority Opportunity -> Why It Matters -> What To Do -> Progress`

## 2. Authoritative Brand System

All My GAL implementation must use the user-supplied **Stylized Option B: Motion Arc — Built on Option 7A GAL Custom Hybrid** brand kit as the authoritative visual reference.

Required identity:

- golf-ball icon with navy dimples / outline treatment;
- orange trajectory dots and target point;
- orange Motion Arc surrounding the golf ball;
- approved GAL wordmark with orange dot inside the A;
- GOLF ANALYTICS LAB secondary wordmark treatment;
- approved primary, icon-only, responsive/small-scale, and premium-on-dark lockups;
- GAL Navy and GAL Orange as core brand colors;
- Inter for product-interface typography unless a later authoritative brand-font specification supersedes it.

Do not substitute an earlier GAL logo, generic text GAL mark, CSS recreation, AI approximation, or alternate trajectory mark. Production assets must be extracted/exported from the approved source artwork and visually verified against the supplied brand board.

## 3. Tee Box Environment

The golf-course scene is part of the product experience, not decorative wallpaper.

Users may choose a preferred tee-box environment. Initial concepts include original GAL scenes inspired by the characteristics of famous golf settings such as Torrey Pines, Pebble Beach, and TPC Sawgrass. Until appropriate naming/image rights are confirmed, production must not imply that an original GAL scene is an official image, exact hole reproduction, licensed course experience, or affiliated course product.

The system should therefore support replaceable environment themes with safe product-facing names/descriptions. Course-specific licensed themes can be added later without restructuring My GAL.

Optional environment personalization may include time of day and atmosphere when it can be delivered without harming performance or accessibility.

The environment must maintain enough contrast for readable controls and must degrade gracefully on slower/mobile connections.

## 4. The Bag Is the Hero Object

The golfer's bag is the central visual object. It is an interactive visualization of equipment state, not the primary navigation system.

The bag should be rendered prominently in the tee-box scene and support club/equipment category targets for:

- Driver
- Fairway Woods
- Hybrids / utility clubs when present
- Irons
- Wedges
- Putter
- Ball

The visual bag should eventually reflect the golfer's actual equipment structure. If the golfer does not carry a category, the visual model should not falsely imply that they do. Unknown equipment should use an honest incomplete-data state.

The resting view should remain visually clean. Status markers/callouts may identify important categories, but detailed explanation appears through progressive disclosure after selection.

Do not require 3D interaction for launch. A performant 2D/2.5D composition with tappable zones is preferred unless testing demonstrates that richer interaction improves usability without unacceptable complexity or load cost.

## 5. Bag Customization

My GAL should support curated visual bag personalization without becoming an unrestricted design tool.

Planned customization dimensions:

- bag style, such as stand/cart/staff-style where assets support it;
- primary color;
- accent color;
- optional golfer initials or display personalization;
- approved GAL Motion Arc / GAL branding treatment.

Equipment configuration and visual bag customization are separate concepts:

- **Equipment configuration** changes what GAL knows about the golfer's actual bag.
- **Visual customization** changes how the bag is presented.

Visual preferences must never alter equipment intelligence or recommendation logic.

The architecture should not prevent future multiple-bag support (for example Primary, Travel, Backup), but multiple bags are not required for first release.

## 6. Bag Status

The landing page includes a compact Bag Status summary such as `5 of 7 categories evaluated` plus counts for golfer-safe states.

Status language must come from governed data. Candidate presentation states include:

- Needs Attention / Opportunity
- Reviewing / Watching
- Optimized / Strong Fit only where positive fit is actually supported by governed evidence
- Not Evaluated / GAL Needs More Information

Absence of a negative insight is not proof that a club is optimized.

The status summary should give a fast understanding of the bag while the bag visualization provides category-level exploration.

## 7. Next Opportunity / Equipment Intelligence

Today prioritizes one meaningful equipment opportunity rather than displaying every available insight with equal prominence.

Example mockup content such as `Driver — 12 yards of potential distance` demonstrates the desired presentation, not an approved factual calculation. A quantified claim may be displayed only when the governed data/evidence and calculation policy support it.

The interaction hierarchy is:

1. equipment/category;
2. golfer-safe status;
3. concise opportunity statement;
4. quantified impact only when defensible;
5. `See Why` / equivalent action;
6. progressive disclosure of evidence/context;
7. recommended next step;
8. relevant Guide or comparison workflow when appropriate.

The detailed interaction should preferably use an overlay, bottom sheet, or similarly contextual treatment where practical so the golfer retains a sense of place in the tee-box experience.

## 8. Bag Value

Bag Value is a first-class My Bag capability and a summarized component on Today. It is not a sixth primary-navigation destination.

Target valuation concepts:

- current retail/replacement value;
- estimated resale value;
- estimated trade-in value where reliable data exists;
- percentage of value retained;
- valuation date/freshness;
- confidence/provenance where meaningful.

Each valuation must be traceable to equipment identity/configuration, condition assumptions or known condition, valuation source(s), observation date, estimate type, and confidence/freshness metadata.

Illustrative mockup values such as `$3,840 retail`, `$2,260 resale`, `$1,675 trade-in`, and `59% retained` are design examples only. They must not ship as user facts without real valuation evidence.

Future intelligence may combine fit and economics (for example upgrade timing, likely net upgrade cost, or `keep it` guidance), but GAL must not bias the system toward purchases. Retaining current equipment should be a valid recommendation when evidence supports it.

A separate market-data/valuation methodology must be defined before production valuation claims are enabled.

## 9. Bag User's Guide

Provide a persistent but secondary `How My Bag Works` / Bag User's Guide entry point.

The guide explains:

- status markers and colors;
- evaluated vs. not evaluated;
- how to select a club/category;
- what `See Why` means;
- how Guides relate to bag intelligence;
- how equipment updates affect GAL;
- how Progress records what happened afterward;
- how Bag Value estimates should be interpreted.

The guide should support onboarding but should not force a repeated tutorial on returning users.

## 10. Today Page Composition

Desktop/tablet composition follows the approved visual reference:

1. authoritative Option 7A Motion Arc GAL header lockup;
2. My GAL — Your Equipment Intelligence Center identity;
3. profile/account access;
4. tee-box/environment selector;
5. large tee-box hero with centered bag;
6. Bag Status summary;
7. Next Opportunity;
8. club/category status markers around the bag;
9. Bag Value summary;
10. How My Bag Works;
11. Quick Actions;
12. Recent Insight;
13. Progress at a Glance;
14. persistent five-part navigation;
15. restrained trust/independence message where appropriate.

The approved mockup is a composition reference, not permission to fabricate the sample metrics it contains.

## 11. Mobile Behavior

Mobile must preserve the emotional hierarchy:

`Course -> Bag -> Status -> Next Opportunity -> Actions`

The bag remains the hero rather than shrinking into a thumbnail above generic cards.

Required mobile principles:

- 44x44px or larger practical touch targets;
- bottom navigation for Today | My Bag | Insights | Guides | Progress;
- status callouts must not obscure the bag or become too dense;
- club/category detail may use a bottom sheet;
- Bag Status and Next Opportunity should be quickly reachable without excessive scrolling;
- decorative scene detail must not compromise text contrast;
- reduced-motion preferences must be honored;
- landscape/desktop enhancements must not be required to use the product.

A dedicated mobile composition must be visually approved before implementation is considered UX-complete.

## 12. Quick Actions

Candidate quick actions include:

- Update My Equipment
- Add New Equipment
- Compare Equipment
- Browse Guides
- Customize My Bag
- Choose My Tee Box / environment

These actions should reuse known golfer/equipment data rather than ask the golfer to repeatedly re-enter information.

## 13. Progress

Progress remains equipment optimization history, not a generic engagement score.

The mockup's `71% Journey Progress`, milestone counts, and unlocked-insight counts are illustrative. No aggregate journey percentage should ship until its calculation and meaning are governed.

Evidence-backed history may include issues identified, resolved, recurrent, equipment changes, recommendation actions, and dated milestones.

## 14. Data and Truthfulness Contract

Every visible intelligence element must map to an authoritative source category:

- golfer-entered profile/equipment data;
- governed GAL equipment records;
- governed longitudinal insights;
- guide answers/results that are semantically compatible with the current use;
- governed recommendation/action records;
- evidence-backed outcomes/resolutions;
- approved market valuation data/methodology;
- presentation-only user preferences such as bag/course theme.

If data is missing, the interface uses an honest learning/incomplete state. It does not infer `Optimized`, invent a distance gain, invent a resale value, create an unsupported confidence score, or manufacture progress.

## 15. Interaction Contract to Design Next

Before feature implementation, define and approve behavior for these primary interactions:

- selecting Driver/Woods/Hybrids/Irons/Wedges/Putter/Ball;
- See Why;
- View Bag Value;
- Customize My Bag;
- Choose My Tee Box;
- How My Bag Works;
- Update/Add/Compare Equipment;
- Recent Insight;
- Progress;
- persistent primary navigation.

For each interaction define: entry state, overlay/page behavior, data requirements, loading state, empty state, error state, accessibility behavior, mobile behavior, and return-to-Today behavior.

## 16. Security and Architecture

This UX does not weaken the approved portal architecture:

- Supabase Auth remains identity/session authority;
- browser reads remain golfer-safe and RLS-protected;
- service-role credentials remain server-only;
- trusted mutations use allowlisted server-side/Edge Function contracts;
- user identity is resolved server-side;
- internal governance/learning data remains inaccessible to the browser;
- registered and subscriber experiences share components and contracts;
- staging verification precedes production.

Presentation preferences such as course theme and bag appearance must be separated from analytical state.

## 17. Acceptance Criteria for the UX Gate

Before resuming feature implementation, My GAL UX is accepted when:

1. the approved tee-box + interactive bag composition is preserved;
2. the exact approved Option 7A Motion Arc brand assets are used;
3. desktop and mobile compositions are approved;
4. primary interactions are defined;
5. every displayed metric has a real data source or is explicitly withheld;
6. Bag Value has a documented valuation policy before real dollar estimates ship;
7. club states do not overclaim fit;
8. customization is clearly separated from analytical truth;
9. accessibility and performance requirements are defined;
10. the experience still answers quickly: what GAL knows, what matters, why, what to do, and what happened afterward.

## 18. Explicitly Deferred / Not Yet Governed

Do not treat these mockup elements as production-ready facts without separate methodology/implementation approval:

- numeric overall Bag Health / Equipment Score;
- numeric Journey Progress percentage;
- unsupported `Optimized` labels;
- estimated yardage gains without evidence;
- retail/resale/trade values without valuation provenance;
- exact branded-course depictions or affiliation claims without rights review;
- full 3D bag interaction;
- multiple saved bags.

## Decision

The tee-box + interactive customized bag concept is the locked visual direction for My GAL. The next design task is the interaction specification, followed by a dedicated mobile composition review. Implementation resumes only after those UX gates are approved.