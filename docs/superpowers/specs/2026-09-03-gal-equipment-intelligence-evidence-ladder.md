# GAL Equipment Intelligence Evidence Ladder

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: My GAL, Buyers Guides, equipment fitting, recommendations, predictive analytics, longitudinal outcomes, and future GAL equipment-intelligence products.

## Core Rule

GAL must separate an observed performance opportunity from attribution of that opportunity to equipment. GAL may not blame a club, quantify a gain, or recommend a replacement beyond what the available evidence supports.

The governing loop is:

`Golfer Profile + My Bag + GAL Equipment Knowledge + Connected/Measured Performance + Environment -> GAL Equipment Intelligence -> Fitting/Buyers Guide -> Action/Change -> Outcome -> Longitudinal Learning`

## Evidence Inputs

### Golfer Profile
Provides relevant physical, game, swing, miss-pattern, environmental, preference, and goal context. Profile information follows the Tell GAL Once / Connect It Once rule and retains provenance, freshness, and editability.

### My Bag
Provides the golfer's current equipment configuration. Driver analysis should use known head/model, loft, adjustability, shaft, flex, weight/profile where available, playing length, grip, settings, and other configuration facts that materially affect analysis.

### GAL Equipment Knowledge Layer
The Buyers Guide equipment database is not merely a questionnaire backend. It is a governed equipment-knowledge source describing relevant equipment characteristics such as head/model, loft options, adjustability, forgiveness/MOI characteristics, launch/spin tendencies, bias, shaft options/characteristics, price/value, and other evidence-backed attributes.

### Performance Evidence
Performance may come from GAL-controlled tests, validated launch-monitor data, connected launch monitors, connected on-course systems, authoritative handicap/scoring sources, golfer-entered measurements, or golfer estimates. Preserve observations rather than destructively replacing conflicting values.

### Environment
Performance analysis should account for relevant measurement conditions when known, including elevation and atmospheric/environmental conditions. GAL should not treat materially different playing/test environments as equivalent without normalization or appropriate qualification.

## Context-Specific Evidence Selection

There is no single universal source ranking. GAL selects the best evidence for the question being answered.

Examples:
- Launch-monitor data may be strongest for spin, launch, attack angle, path, face, ball speed, and controlled fitting comparisons.
- On-course data may be stronger for real-world playing distance, dispersion, club usage, and performance under actual conditions.
- Authoritative handicap sources may be strongest for current Handicap Index.
- GAL-controlled comparison tests may be strongest for causal equipment-change attribution.

Every derived conclusion must retain enough provenance to explain which evidence supported it.

## Evidence Ladder

### Level 1 — Profile Fit
Inputs: Golfer Profile + current equipment + GAL Equipment Knowledge.

Permitted conclusion examples:
- Current configuration deserves review.
- Current equipment characteristics may not align well with the golfer's stated goals, swing/miss context, or fitting profile.

Not permitted from Level 1 alone:
- quantified yardage loss/gain;
- causal statement that the club is costing distance/accuracy;
- unsupported replacement claim.

### Level 2 — Performance Opportunity
Adds sufficient measured or observed performance evidence.

Permitted conclusion examples:
- GAL sees a potential distance, dispersion, launch, spin, gapping, or consistency opportunity.
- Observed performance falls outside an evidence-backed expected/optimized performance envelope.
- Quantified modeled opportunity may be shown only when the calculation methodology, inputs, environmental treatment, uncertainty, and data quality support it.

A modeled opportunity is not automatically equipment attribution.

### Level 3 — Equipment Attribution
Requires stronger evidence linking the performance opportunity to the equipment/configuration, preferably including controlled fitting/comparison evidence or sufficiently strong multi-source evidence.

Permitted conclusion examples when supported:
- Current driver configuration is likely contributing to excess spin.
- A tested configuration change improved carry/dispersion by a measured amount.

Strong causal wording requires correspondingly strong evidence.

## Predictive / Ball-Flight Modeling

GAL may model expected or optimized performance using relevant inputs such as club speed, ball speed, launch, spin, attack angle, strike, equipment configuration, and environment.

Conceptually:

`Expected Performance = f(speed, ball speed, launch, spin, delivery, strike, environment, equipment)`

and

`Modeled Opportunity = defensible optimized/alternative outcome - observed/baseline outcome`

The model must not silently assume that changing equipment will produce the modeled optimized delivery conditions. A ball-flight opportunity and an equipment-change opportunity are distinct claims.

## Driver Example

If measured data suggests a golfer could carry farther under a physically reasonable launch/spin envelope, GAL may state that it sees a modeled ball-flight opportunity when methodology and evidence support the number.

GAL must not state `Your driver costs you 12 yards` merely because a simulation shows 12 additional yards under different launch/spin conditions. Excess spin or launch can arise from strike, delivered loft, attack angle, face/path, golfer variability, equipment, or interactions among these factors.

Preferred presentation separates:
- what GAL observed;
- modeled opportunity;
- possible causes;
- confidence/evidence by cause;
- what additional evidence would resolve uncertainty;
- recommended next action.

## Buyers Guide Integration

The Buyers Guide consumes relevant known profile, bag, performance, and insight data under Tell GAL Once. It must not re-ask semantically identical valid questions.

When Driver Intelligence identifies a supported need (for example lower spin while retaining forgiveness and improving right-side dispersion), the Driver Buyers Guide should use that need as fitting context and search/rank equipment characteristics accordingly.

Unknown information may still be requested, such as budget or a context-specific preference not already known.

## Closed-Loop Outcome Rule

A recommendation is not success. After a fitting, adjustment, purchase, or equipment change, GAL should seek qualifying outcome evidence and compare it with the pre-change baseline where appropriate.

The loop is:

`Insight -> Recommendation -> Action/Change -> New Evidence -> Outcome -> Resolution/Regression -> Longitudinal Learning`

Comparative measured outcomes are preferred for claims about realized improvement.

## Explainability Rule

Predictive analytics and future machine learning must not become an unexplained `buy this club` black box. Golfer-facing intelligence must be traceable in understandable language to:

1. what GAL observed;
2. what GAL modeled or compared;
3. what GAL believes;
4. evidence/confidence appropriate to that belief;
5. what the golfer can do next;
6. what additional evidence would improve the conclusion when uncertainty remains.

## UI Language Rule

Prefer opportunity-first language until equipment attribution is supported.

Preferred: `GAL Sees a Driver Opportunity`.

Use stronger equipment-causal language only at the appropriate evidence level.

Mockup metrics such as 12 yards potential, 82% confidence, specific launch/spin values, or equipment-attribution statements are illustrative unless backed by real golfer evidence and an approved calculation policy.

## Governance

All GAL products must use the same governed evidence logic. Buyers Guides, My GAL, fitting workflows, club detail screens, recommendations, and longitudinal analytics may not independently invent competing definitions of fit, opportunity, attribution, confidence, or improvement.

This Evidence Ladder is the common analytical contract for future club-category experiences, beginning with Driver and extending to woods, hybrids, irons, wedges, putter, and ball with category-specific methodologies.