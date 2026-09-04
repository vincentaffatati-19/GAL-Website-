# GAL AI Fitting Product Model

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: Public Buyers Guides, authenticated My GAL, My Bag, equipment fitting, recommendations, Equipment Intelligence, and Progress.

## Decision

GAL distinguishes public **Buyers Guides** from authenticated **GAL AI Fitting**.

Buyers Guides remain public-facing education, discovery, acquisition, SEO/AEO, and lightweight recommendation experiences. For authenticated golfers, the product evolves into **GAL AI Fitting**: a persistent personalized equipment-fitting capability that uses everything GAL validly knows about the golfer and the available equipment universe.

The core promise is:

**Personalized equipment fitting powered by your game.**

GAL combines relevant golfer profile data, swing and performance evidence, current equipment, playing environment, golfer priorities, equipment knowledge, predictive analytics, and longitudinal outcomes to identify equipment characteristics and configurations that best fit the golfer.

## Product Hierarchy

**Build a Better Bag** — education/content umbrella.

**GAL Buyers Guides** — public discovery, education, acquisition, and lightweight recommendations.

**GAL AI Fitting** — authenticated personalized equipment fitting.

**My GAL** — persistent Equipment Intelligence Center.

**My Bag** — golfer's actual equipment, configuration, status, and governed value information.

**GAL Equipment Intelligence** — evaluates evidence-backed fit and performance opportunities over time.

**Progress** — determines what happened after equipment/fitting actions using qualifying outcome evidence.

## Funnel

`Anonymous -> Buyers Guide -> Register -> Golfer Profile / Connected Data -> GAL AI Fitting -> My Bag -> Equipment Intelligence -> Outcome / Progress`

Public Buyers Guides may encourage registration to unlock deeper AI Fitting, but public usefulness must not depend on fabricated personalization.

## Tell GAL Once

GAL AI Fitting follows the locked **Tell GAL Once / Connect It Once** rule.

A fitting first checks the shared Golfer Profile/Evidence Layer for semantically compatible, sufficiently fresh information. It reuses valid known data and asks only for genuinely missing, stale, or context-specific inputs.

Reused information must remain reviewable/editable where it materially affects the fitting.

Example: if GAL already knows handicap, driver speed, current driver, shaft, typical miss, carry, environment, and equipment priorities, the Driver Fit must not ask those questions again merely because an older Buyers Guide questionnaire did.

## Fitting Target: Configuration, Not Merely Product

GAL AI Fitting should ultimately fit an equipment **configuration**, not merely rank a model name.

For Driver, a mature fitting may include supported recommendations for:
- head/model;
- loft/effective loft;
- adjustable setting;
- shaft model/profile where evidence/data permits;
- flex;
- shaft weight range;
- playing length;
- grip size/type where relevant;
- other defensible configuration dimensions.

Category-specific fitting dimensions will differ for woods, hybrids, irons, wedges, putter, and ball.

GAL must not present unsupported precision. If evidence supports only a characteristic or range, recommend the characteristic/range rather than inventing an exact component.

## Characteristics Before Brands

The analytical engine must determine the golfer's target equipment characteristics before ranking brands/models.

Conceptually:

`Golfer Need -> Target Equipment Characteristics -> Compatible Configurations -> Ranked Options -> Explanation`

Example target characteristics might include launch/spin window, forgiveness, directional bias, effective loft range, shaft-weight/profile range, and playing-length range.

Commerce, affiliate relationships, retailer availability, sponsorships, or brand popularity must not determine the analytical target profile.

This rule protects GAL independence and recommendation credibility.

## Core Inputs

GAL AI Fitting may consume, when relevant and governed:
- Golfer Profile;
- physical measurements such as height, wrist-to-floor, hand dimensions;
- handedness and age/context where relevant;
- handicap/scoring context;
- golfer goals and preferences;
- swing speed and delivery data;
- launch-monitor observations;
- strike/miss patterns;
- on-course observed performance;
- current My Bag equipment/configuration;
- environmental context and normalized performance where appropriate;
- GAL Equipment Knowledge Layer;
- previous fittings/recommendations/actions;
- qualifying longitudinal outcomes;
- future validated aggregate learning.

## Equipment Knowledge Layer

The underlying Buyers Guide/equipment database evolves into a shared **GAL Equipment Knowledge Layer**.

It should support evidence-backed product/configuration attributes required by fitting, including category-specific characteristics, available configurations, adjustability, construction/performance tendencies, shaft/component data where available, pricing/value/availability when appropriate, provenance, and freshness.

The public Buyers Guide and authenticated AI Fitting must share this governed equipment knowledge rather than maintain inconsistent product truth.

## Evidence Ladder Applies

All GAL AI Fitting conclusions are governed by the locked GAL Equipment Intelligence Evidence Ladder:

1. **Profile Fit**
2. **Performance Opportunity**
3. **Equipment Attribution**

AI Fitting may use predictive models to identify candidate configurations, but causal or quantified claims must not exceed the evidence level.

## Fitting Evidence / Confidence

GAL should communicate the strength of evidence supporting a fitting without confusing it with golfer skill or an overall equipment score.

Initial UX should favor explainable labels such as `Limited`, `Developing`, `Strong`, or equivalent governed terminology, plus what evidence is present/missing.

A numeric Fitting Confidence percentage may be introduced only after GAL defines and validates a governed methodology for inputs, weighting, uncertainty, freshness, and interpretation.

The interface should be able to explain:
- why fitting evidence is strong/limited;
- which sources were used;
- which missing inputs would materially improve the fit;
- how recently relevant evidence was measured.

## Explainability

GAL AI Fitting must not become a black-box `buy this club` system.

Every recommendation should be capable of answering:
1. What does GAL know about me that matters here?
2. What performance/equipment need did GAL identify?
3. What target equipment characteristics follow from that need?
4. Why does this configuration match those characteristics?
5. What alternatives were considered?
6. What uncertainty remains?
7. What would improve the fitting evidence?
8. What should I do next?

A golfer should be able to ask why a popular or specific club was not recommended and receive an evidence-based comparison when the data supports one.

## Closed-Loop Fitting

The fitting does not end at recommendation or purchase.

`Fit -> Recommendation -> Adjustment/Test/Purchase -> New Evidence -> Outcome -> Resolution/Regression -> Longitudinal Learning`

GAL should evaluate whether the fitting/change actually improved the targeted outcome when qualifying post-change evidence becomes available.

This closes the loop between AI Fitting and My GAL Progress.

## Learning

Future longitudinal learning may use privacy-safe, governed aggregate outcomes to improve predictions for similar golfer/equipment contexts. Similarity-based or machine-learning recommendations must remain explainable and governed.

Statistical association discovered across golfers must not automatically be presented as causal equipment truth.

## Registered / Subscriber Strategy

Public Buyers Guides remain an acquisition surface. GAL AI Fitting is a stronger candidate for authenticated and potentially subscriber-differentiated value.

Registered and subscriber experiences must continue to use shared components/data contracts. Subscription may unlock additive fitting depth, history, comparisons, advanced analysis, or other governed capabilities rather than creating a separate portal implementation.

Final entitlement boundaries require separate product/business approval.

## Naming Rule

Use **Buyers Guide** for the public education/discovery product where appropriate.

Use **GAL AI Fitting**, **AI Club Fitting**, or category-specific forms such as **GAL AI Driver Fitting** for authenticated personalized fitting.

Do not describe the authenticated persistent fitting capability merely as a Buyers Guide when it is using the golfer's shared profile, evidence, My Bag, predictive analysis, and longitudinal outcomes.

## UX Implication

Future Driver/Woods/Hybrids/Irons/Wedges/Putter/Ball authenticated flows should be designed as AI Fitting experiences rather than repeated questionnaires.

The fitting experience should visually communicate:
- what GAL already knows;
- what GAL still needs;
- evidence sources/freshness;
- identified need/opportunity;
- target equipment characteristics;
- recommended configuration(s);
- why each recommendation fits;
- uncertainty/confidence appropriate to evidence;
- next action;
- post-change outcome tracking.

## Governance Rule

GAL AI Fitting, public Buyers Guides, My Bag, Equipment Intelligence, and Progress must use the same governed Golfer Profile/Evidence Layer, Equipment Knowledge Layer, Evidence Ladder, and longitudinal outcome architecture. No product surface may create an independent fitting truth or silently override shared golfer/equipment evidence.