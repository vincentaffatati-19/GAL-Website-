# My GAL Driver Intelligence Interaction Design

Status: UX SPEC FOR REVIEW  
Date: 2026-09-03  
Product surface: My GAL -> Driver / See Why interaction  
Depends on: 2026-08-31 My GAL Equipment Intelligence Product Design; 2026-09-02 My GAL Tee Box UX Design; 2026-09-03 GAL Golfer Profile + Connected Data Design.

## 1. Purpose

This specification defines the first club-level intelligence interaction in My GAL. The Driver experience establishes the reusable interaction pattern for fairway woods, hybrids, irons, wedges, putter, and ball.

The golfer should be able to move from the tee-box home experience into driver intelligence without losing context, understand what GAL believes is happening, why it matters, what evidence supports that conclusion, what action is appropriate, and what happens afterward.

The core interaction is:

`Tap Driver -> See Why -> Understand -> Explore -> Take Action -> Track Result`

## 2. Contextual Presentation

Driver intelligence should open contextually over the My GAL tee-box experience using a desktop overlay / panel and a mobile bottom-sheet or full-height sheet. The golfer should retain a clear sense that they are still inside My GAL rather than being routed into a disconnected analytics product.

The background tee-box scene and bag may visually recede but should remain present where viewport and accessibility allow.

Primary controls must include a clear close/back action returning the golfer to the same My GAL state.

## 3. Tell GAL Once / Connect It Once

The Driver experience must consume the shared GAL Golfer Profile and Evidence Layer.

It must not ask again for any driver-fitting input GAL already possesses when that value is valid, sufficiently fresh, and semantically compatible with the current analysis.

Examples include:

- handedness;
- age band where relevant;
- height;
- wrist-to-floor;
- handicap / scoring context;
- driver club speed;
- driver carry;
- common directional miss;
- impact tendency;
- playing environment;
- golfer goals;
- current driver specifications;
- connected-app observations.

If data must be confirmed because it is stale, contradictory, or materially context-specific, GAL should explain why rather than silently asking the same question again.

## 4. Driver Snapshot

The top of the interaction provides a concise Driver Snapshot using only supported evidence.

Candidate fields:

- Driver club speed;
- Ball speed;
- Carry distance;
- Total distance where trustworthy;
- Launch angle;
- Spin rate;
- Attack angle;
- Smash factor where measured and meaningful;
- Dispersion tendency;
- strike-location tendency;
- current loft;
- shaft identity / flex / length;
- driver head/model;
- environment normalization indicator where used.

Each metric should be accompanied by provenance when the user inspects it, for example `TrackMan • measured Aug 24, 2026`, `Arccos • 31 qualifying drives`, or `Self-reported`.

The resting view should not overwhelm the golfer with every available metric.

## 5. Overview Tab

The Overview answers four questions in order:

1. What is GAL seeing?
2. Is it material?
3. What appears to be driving it?
4. What should I do next?

The first release should emphasize only the one or few material factors most relevant to the golfer.

Example factors may include:

- launch too low / high;
- spin too low / high;
- excessive right / left dispersion;
- heel or toe strike tendency;
- inconsistent strike pattern;
- equipment configuration mismatch;
- carry gap versus golfer capability;
- excessive variance;
- current driver performing well enough that no change is warranted.

The interface must permit a positive outcome such as `Keep your current driver` when evidence supports it.

## 6. Quantified Opportunity

A quantified claim such as `+12 yards potential carry` may appear only when GAL has an approved calculation methodology and sufficient evidence.

Until such methodology exists, the product may use non-numeric language such as:

- `Potential distance opportunity`;
- `Launch conditions may be limiting carry`;
- `Dispersion is the larger opportunity than distance`;
- `Current driver appears well matched to your measured performance`.

The mockup's sample yardage, optimal ranges, launch/spin values, recommendations, and fit labels are illustrative only.

No numeric gain should be inferred merely from a generic launch chart or population benchmark.

## 7. Why It Matters

The `Why It Matters` view translates fitting mechanics into golfer language.

It should explain relationships such as:

- launch and spin influence flight/carry;
- strike location influences ball speed, launch, spin, curvature, and consistency;
- face/path relationships influence starting direction and curvature;
- shaft/head/loft settings can influence delivery or outcome but do not automatically fix swing mechanics;
- environmental conditions affect observed flight and should be distinguished from normalized performance.

Where useful, graphical illustrations should show trajectory, face impact, dispersion, or club-delivery concepts.

Education must remain explanatory rather than falsely diagnostic when evidence is incomplete.

## 8. Evidence and Data Quality

Every conclusion should be traceable to evidence in the GAL Evidence Layer.

Evidence classes may include:

- GAL-verified fitting/test data;
- connected launch-monitor data;
- connected on-course performance data;
- authoritative handicap/scoring data;
- golfer-entered measured values;
- golfer estimates;
- derived/normalized GAL calculations using an approved method.

When multiple sources disagree, GAL preserves the observations and chooses the context-appropriate source rather than overwriting history.

The user should be able to inspect a concise `Why GAL thinks this` view showing the most relevant evidence and freshness.

## 9. Recommendations

Recommendations must be generated from governed golfer/profile/bag/evidence inputs.

Potential recommendation categories:

- keep current equipment;
- adjust current driver settings;
- verify loft / shaft / length / swing weight;
- test a different configuration;
- compare a shortlist of alternative drivers;
- perform a launch-monitor session;
- collect more data before changing equipment;
- complete missing golfer profile measurements;
- address a swing-delivery issue before equipment replacement where appropriate.

A product shortlist must not appear merely because the interface has room for one.

Every recommendation should state why it fits the golfer's current evidence and what outcome GAL expects to test.

## 10. Compare

The Compare experience should reuse known golfer data automatically.

The current driver is the baseline. Candidate alternatives may be compared on relevant dimensions such as:

- expected launch/spin window;
- forgiveness / dispersion characteristics;
- head bias / adjustability;
- shaft/configuration compatibility;
- current and expected carry where an approved evidence model supports it;
- bag economics / value where valuation methodology exists.

Comparison should remain golfer-specific, not a generic ranking disguised as personalization.

## 11. Inspect & Specs

A driver specification panel should show known current-club details, including where available:

- manufacturer/model;
- loft;
- adjustable setting;
- shaft manufacturer/model;
- shaft flex;
- shaft weight;
- playing length;
- swing weight;
- grip;
- acquisition date;
- purchase price where voluntarily provided;
- current estimated resale/trade value only when supported by the separate valuation methodology.

Unknown fields should invite the golfer to add the information once to My Bag, after which all GAL tools reuse it.

## 12. Real-World Results

GAL may eventually show privacy-safe aggregate results from comparable golfers only when governed aggregate-learning criteria are satisfied.

Claims such as `similar golfers gained 11.3 yards` require:

- a defined comparison cohort;
- minimum sample size;
- privacy safeguards;
- outcome attribution rules;
- measurement consistency;
- freshness;
- approved presentation policy.

Until those requirements are met, the section should be omitted rather than populated with illustrative numbers.

## 13. Action and Outcome Loop

Every meaningful Driver recommendation should create a clear action path and, where appropriate, a longitudinal action record.

Examples:

- `Test 10.5° setting`;
- `Book / perform launch-monitor test`;
- `Compare three candidate drivers`;
- `Keep current driver`;
- `Update current shaft specification`;
- `Collect 20 more qualifying drives`.

The product must distinguish `I viewed a recommendation` from `I acted on it`.

A later qualifying observation or test determines whether the issue was resolved, remained ineffective, or recurred.

## 14. Status Language

Use the governed golfer-facing lifecycle language.

Permitted states include contextually appropriate versions of:

- Needs Attention;
- Watching / You're Reviewing This;
- Solved;
- Came Back;
- Checking Progress;
- Still Needs Attention;
- GAL Needs More Information.

Do not use `Optimized`, `Strong Fit`, or a numeric driver score unless a separate governed methodology supports a positive-fit determination.

## 15. Mobile Interaction

On mobile, tapping Driver opens a bottom sheet or full-height sheet with the following priority:

1. Driver identity/status;
2. concise insight;
3. key evidence metrics;
4. Why It Matters;
5. recommended next action;
6. secondary details / compare / specs.

Tabs may collapse into segmented controls or stacked sections when necessary.

The golfer must be able to close the interaction and return to the same bag/tee-box state.

Touch targets should be at least practical 44x44px; charts and controls must be accessible without precision gestures.

## 16. Loading, Empty, Conflict, and Error States

### Loading
Show a stable skeleton preserving the Driver panel layout. Do not present placeholder intelligence as real data.

### Missing data
Explain what GAL can and cannot determine. Example: `GAL needs a measured driver speed or recent carry data to evaluate this opportunity more precisely.` Reuse profile data and ask only for the missing item.

### Conflicting data
Show the discrepancy when materially relevant and allow the golfer to inspect sources. Example: `Your launch monitor and on-course carry differ. GAL is using launch-monitor data for fitting and on-course data for playing-distance context.`

### Stale data
Request a refresh only where age of data materially affects the conclusion.

### Error
Preserve context and provide retry without discarding golfer edits or navigation state.

## 17. Privacy and Security

Driver intelligence must follow existing My GAL architecture:

- browser reads are golfer-safe and RLS-protected;
- service-role credentials remain server-only;
- connected-app tokens/credentials are never exposed to the browser unnecessarily;
- external provider data is normalized into the GAL evidence model;
- internal detector/governance/aggregate-learning tables remain hidden;
- trusted mutations use allowlisted server-side contracts;
- source provenance may be shown without exposing sensitive implementation internals.

## 18. Reusable Club Pattern

The Driver interaction establishes a reusable product shell:

`Snapshot | Why It Matters | Recommendations | Compare | Specs | Evidence | Action | Progress`

Each club category may substitute category-specific measurements while preserving the same mental model.

Examples:

- Fairway woods/hybrids: launch, carry, gapping, turf/tee usage, overlap;
- Irons: carry gaps, dispersion, strike, lie/length, descent, consistency;
- Wedges: loft gaps, carry matrix, bounce/grind context, partial-shot coverage;
- Putter: length/lie/loft, stroke tendencies, start line, speed control where measured;
- Ball: speed, launch/spin response, flight, short-game behavior, feel/cost preferences.

## 19. Explicitly Not Yet Approved as Production Claims

The current design mockup includes visually useful but ungoverned examples. Do not ship as real golfer intelligence without separate methodology/evidence:

- `+12 yards` or any potential-gain number;
- exact optimal launch/spin ranges presented as golfer-specific conclusions;
- `7 of 14 optimized`;
- `71% bag optimization`;
- `Fitting Confidence: High` without a governed confidence model;
- specific recommended driver rankings;
- `similar golfers gained X yards`;
- retail/trade values without the Bag Value methodology;
- `Mark as Optimized` as a user-controlled truth state.

A golfer may acknowledge, act, test, or update equipment; they should not be able to self-declare a governed issue solved/optimized without qualifying evidence.

## 20. Acceptance Criteria

The Driver interaction is UX-ready when:

1. it preserves the tee-box / bag context;
2. it consumes shared Golfer Profile/Evidence data under Tell GAL Once;
3. every visible conclusion has identifiable provenance;
4. it works honestly with incomplete and conflicting data;
5. quantified opportunities are withheld unless methodology supports them;
6. recommendations include `keep current equipment` and `collect more evidence` as valid outcomes;
7. action and outcome are distinct;
8. the same interaction model can extend across every club category;
9. mobile behavior is approved;
10. no mockup placeholder is mistaken for production intelligence.

## Decision

The Driver / See Why experience is the first reusable club-level intelligence pattern for My GAL. It should remain visual, contextual, evidence-backed, progressive, and golfer-specific. The next UX task is a dedicated mobile Driver composition followed by the broader club-category adaptation matrix before implementation planning resumes.
