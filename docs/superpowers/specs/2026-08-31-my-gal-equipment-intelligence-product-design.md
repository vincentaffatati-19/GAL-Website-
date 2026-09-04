# My GAL Equipment Intelligence Product Design

Status: APPROVED / LOCKED  
Date: 2026-08-31  
Product surface: Authenticated registered-user and subscriber experience

## Product Position

The authenticated GAL experience is **My GAL — Your Equipment Intelligence Center**. It is not presented to golfers as a generic customer portal or SaaS dashboard.

The product promise is: **help the golfer build and maintain a better golf bag by turning known golfer, bag, guide, recommendation, and longitudinal information into clear equipment priorities and next actions.**

The governing interaction loop is:

`My Bag -> What GAL sees -> What matters -> What I should do -> What happened afterward`

The longitudinal insight engine remains the governed intelligence layer underneath this experience. The interface translates that infrastructure into golfer language rather than exposing database or governance terminology.

## Experience Model

Use familiar conventions from modern personal-intelligence, fitness, and financial applications: concise prioritized home brief, progressive disclosure, clear next actions, personal history, and persistent navigation. Do not imitate a competitor's visual identity or proprietary presentation.

GAL differentiates through an equipment-specific mental model and a closed-loop record of equipment decisions and outcomes.

## Primary Navigation

Desktop and mobile share one information architecture:

1. **Today** — Equipment Brief and highest-priority next actions.
2. **My Bag** — equipment inventory and club-level equipment intelligence.
3. **Insights** — material equipment issues and their golfer-facing lifecycle/history.
4. **Guides** — personalized Build a Better Bag guides that reuse known golfer/bag information.
5. **Progress** — equipment optimization history and resolved/recurrent issues.

On mobile, use a familiar bottom-navigation treatment when viewport and accessibility testing support it. Desktop may use restrained top or side navigation while preserving the same labels and hierarchy.

## Today: GAL Equipment Brief

Today is the default authenticated landing experience. It is **not** a chart-heavy dashboard and is **not** the raw insight feed.

The first release should compose available governed data into these modules:

- **Equipment Brief** — concise statement of what deserves attention now.
- **Material Insight cards** — prioritized golfer-facing issues with explanation and next action.
- **My Bag summary** — compact equipment context and status entry point.
- **Recently Solved** — resolved equipment issues when data exists.
- **Equipment Watch / For You** — reserved component boundary for future market/recommendation intelligence; do not invent recommendations when no governed data source exists.

A future **Bag Health** score is a signature-product opportunity, but it must not be fabricated in the first release. GAL will introduce a numeric Bag Health score only after its formula, evidence inputs, weighting, confidence, and change semantics are separately governed and validated.

## My Bag

My Bag should become a signature GAL surface. Present clubs in a golfer-recognizable bag hierarchy rather than a database table.

Club-level presentation may include golfer-safe states such as:

- Good fit / no current material issue
- Review
- Possible gap
- Possible overlap
- Watching

These labels must be derived from governed data. Absence of an insight does not automatically prove a club is a good fit.

Selecting a flagged club should progressively disclose:

1. what GAL sees;
2. why GAL is flagging it;
3. golfer-safe evidence/context;
4. confidence where governed and meaningful;
5. recommended next step;
6. relevant personalized guide or comparison workflow when available.

The first implementation slice may ship a compact My Bag summary and navigation shell before the full visual bag model if existing production data is insufficient for the richer view.

## Insights

Insights expose the longitudinal intelligence system in golfer language.

Internal governance states remain authoritative in the backend, but primary golfer-facing terminology is simplified:

- ACTIVE -> **Needs Attention**
- ACKNOWLEDGED -> **Watching** or **You're Reviewing This**, chosen by context
- RESOLVED resolution -> **Solved**
- REGRESSED resolution -> **Came Back**
- EVIDENCE_PENDING -> **Checking Progress**
- INEFFECTIVE -> **Still Needs Attention**

SUPPRESSED and EXPIRED are normally delivery/internal states and should not be elevated as prominent golfer labels unless a product requirement specifically calls for them.

The detail view should tell a chronological story when data exists: issue detected, golfer response, equipment/recommendation action, qualifying outcome, resolution, and recurrence. It must not expose raw detector names, source keys, governance actors, learning policies, or contributor data.

## Guides

Logged-in Buyers Guides should become progressively personalized.

The target experience is: **GAL remembers what it already knows and asks only for information it still needs.**

Known, governed golfer/bag/preferences data may prefill or skip guide questions only when the answer semantics are compatible with the current guide. Every prefilled answer must remain visible/editable before recommendation generation so stale longitudinal information does not silently force a recommendation.

Guide results should be able to feed trusted recommendation/action workflows and longitudinal outcomes without exposing service-only RPCs to the browser.

This design preserves the public Buyers Guides for anonymous acquisition while making the authenticated guide experience materially more valuable.

## Progress

Progress measures **equipment optimization**, not golf score or generic activity.

The initial Progress surface should show evidence-backed longitudinal history such as:

- issues identified;
- issues solved;
- issues that came back;
- equipment changes captured by governed workflows;
- dated milestones and recommendation actions.

Future value metrics such as estimated unnecessary purchases avoided or dollars saved require a separately defined calculation policy and must not be shown as factual values until that policy exists.

## Subscriber Differentiation

Registered users and subscribers use the same My GAL components and data contract. Subscriber status unlocks additive depth, never a separate portal implementation and never broader row ownership.

Potential subscriber enhancements include richer history, deeper explanations, saved comparisons, advanced bag-change analysis, and priority personalization. Production subscriber entitlements remain base-only until an authoritative billing/entitlement source is integrated; staging fixtures may exercise subscriber presentation.

## Interaction Principles

1. **Prioritize, don't overwhelm.** Lead with the one or few things that matter now.
2. **Prescription follows explanation.** Every recommended action should answer why it matters.
3. **Progressive disclosure.** Brief first; evidence and history on demand.
4. **Remember responsibly.** Reuse known information, but allow correction and never treat stale data as immutable truth.
5. **Close the loop.** A recommendation is not success; governed evidence determines whether the equipment issue was solved.
6. **Use golfer language.** Database lifecycle terminology stays behind the product boundary.
7. **Never invent intelligence.** Empty or insufficient data produces an honest empty/learning state, not fabricated Bag Health, confidence, savings, or recommendations.
8. **Shared experience.** Registered and subscriber surfaces change together through shared components.
9. **Mobile first.** Primary actions and navigation must work comfortably on a phone.
10. **GAL brand first.** Use the locked Option 7 GAL identity and current brand system; familiar interaction patterns must still feel uniquely GAL.

## Security and Architecture

This product model does not change the approved security architecture in `2026-08-31-portal-longitudinal-integration-design.md`:

- `/portal/` remains the authenticated SPA route;
- Supabase Auth remains identity/session authority;
- browser reads remain limited to golfer-safe RLS-protected data;
- service-role credentials remain server-only;
- browser mutations pass through narrow trusted Supabase Edge Functions;
- user identity is resolved server-side;
- internal longitudinal/learning/governance tables remain inaccessible to the browser;
- staging verification precedes production.

## First Release Product Scope

The first release must establish the **My GAL** mental model without pretending that all future data products already exist.

Deliver:

- My GAL branded authenticated shell;
- Today as the default route;
- Equipment Brief built from real governed insights;
- prioritized material insight cards and detail/actions;
- primary navigation for Today, My Bag, Insights, Guides, Progress;
- My Bag summary using available golfer-safe data, with honest incomplete-data states;
- Insights history/lifecycle translation;
- Guides entry surface designed for future known-data reuse;
- Progress surface using existing evidence-backed longitudinal history;
- shared registered/subscriber component architecture;
- mobile/accessibility baseline;
- all previously approved security and staging acceptance gates.

Do not ship a fabricated Bag Health score, dollar-savings metric, unsupported club-fit label, or personalized recommendation merely to fill the interface.

## Product Success Criteria

The first release succeeds when a golfer can answer, within seconds of opening My GAL:

1. **What does GAL know about my equipment?**
2. **What deserves my attention now?**
3. **Why does it matter?**
4. **What should I do next?**
5. **What has GAL helped me address over time?**

The experience should feel familiar enough to require little instruction but distinctive enough that **Equipment Intelligence** and **My GAL** become recognizable GAL product concepts.