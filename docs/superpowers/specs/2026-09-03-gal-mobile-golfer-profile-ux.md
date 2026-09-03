# GAL Mobile Golfer Profile UX

Status: APPROVED / LOCKED
Date: 2026-09-03
Applies to: authenticated Golfer Profile, GAL AI Fitting, My GAL, connected golf data, graphical measurement capture, and future profile-powered products.

## Locked Visual Direction

The approved mobile profile experience is the latest high-fidelity mobile mockup created on 2026-09-03. Treat that composition and interaction language as the reference direction for implementation unless explicitly changed.

The experience is centered on **Build Your GAL Golfer** rather than a generic account-profile form.

Primary promise:

**The more GAL understands your game, the better we can fit your equipment.**

## Primary Profile Structure

The graphical profile is organized into five core areas:

1. **You** — physical measurements and fitting data.
2. **Your Game** — handicap, scoring context, goals, priorities, and playing frequency/context.
3. **Your Swing** — speed, delivery, launch-monitor metrics, carry data, and other measured swing/performance inputs.
4. **Your Miss** — shot shape, dispersion, strike location, and category-specific miss patterns.
5. **Where You Play** — typical environment and course conditions.

A sixth cross-cutting entry point is:

**Connect Your Golf** — connected apps, devices, launch monitors, scoring/handicap systems, and other approved external evidence sources.

## Tell GAL Once / Connect It Once

The mobile profile must visibly reinforce the locked rules:

- Tell GAL Once.
- Connect It Once.
- GAL reuses valid, semantically compatible data across AI Fitting, My Bag, Equipment Intelligence, Guides, and future products.
- GAL asks only for data that is missing, stale, or genuinely context-specific.

## Mobile Home / Entry

The profile entry should feel useful rather than administrative.

The approved direction includes:

- a personalized My GAL mobile home;
- a visible profile-strength/completeness indicator;
- a prominent **Build Your GAL Golfer** action;
- AI Fitting/My Bag/Progress context;
- a clear **Connect Your Golf** path.

Profile completeness describes data coverage, not golfer quality or ability.

## Graphical Profile Hub

Use a central golfer representation with five labeled profile areas around the golfer.

The golfer representation adapts appropriately to the user:

- junior golfer appears junior;
- adult woman is not represented by an adult man;
- age band influences representation without implying ability;
- handedness should affect golf stance/orientation where relevant;
- avoid stereotyped body or skill assumptions.

For juniors, physical measurements may require more frequent freshness prompts because growth can invalidate fitting inputs.

## You

The approved mobile direction includes graphical fitting measurements such as:

- height;
- wrist-to-floor;
- hand size;
- glove size;
- wrist-to-hand or other governed hand measurements where useful;
- handedness.

### Wrist-to-Floor Capture

Provide graphical instructions showing:

- natural standing posture;
- arms hanging naturally;
- level floor;
- normal golf shoes or similar footwear;
- measurement vertically from the appropriate wrist crease/landmark to the floor.

Allow unit selection where useful.

Camera-assisted measurement may be explored later, but it must not be treated as trusted until validated.

### Hand Size Capture

Use a graphical hand measurement screen with a clear measurement line/landmark and simple numeric entry.

## Your Game

The approved direction includes information such as:

- Handicap Index or typical scoring context;
- typical score;
- frequency of play;
- primary goal;
- ranked priorities such as consistency, distance, shot shaping, forgiveness, or other category-relevant objectives.

Use connected authoritative records when available, while preserving provenance and golfer override.

## Your Swing

The approved direction includes a concise swing snapshot rather than an overwhelming telemetry table.

Potential inputs, when available and relevant, include:

- club speed;
- ball speed;
- launch angle;
- spin rate;
- attack angle;
- club path;
- face angle;
- carry distance;
- strike location;
- dispersion;
- category-specific benchmark clubs such as Driver and 7-Iron.

The source and date/recency of measured data should be visible or accessible.

## Your Miss

The approved direction is graphical, not dropdown-first.

### Typical Shot Shape

Use a fairway/shot-trace visual where the golfer can select the typical curve/finish pattern and frequency.

Examples include:

- left;
- draw;
- straight;
- fade;
- slice;
- frequency such as rarely/sometimes/often.

### Strike Location

Use a clubface visual with tap/select capture for strike zones such as heel/center/toe and low/middle/high.

Category-specific miss capture may differ for Driver, woods, irons, wedges, and putter.

## Where You Play

Capture the golfer's typical playing environment separately from actual conditions for a specific fitting/test session.

The approved direction includes fields such as:

- elevation;
- typical temperature range;
- typical wind range;
- fairway firmness/condition;
- green speed/condition where relevant;
- general firmness or other governed environment attributes.

Do not silently treat home-environment values as exact conditions for every measured performance session.

## Connect Your Golf

The approved mobile UX includes a dedicated connection screen grouped around data sources such as:

- on-course data;
- launch monitors;
- scoring/handicap;
- wearables/activity where fitting-relevant;
- future weather/location or other evidence sources.

Examples shown in the concept are illustrative. Actual integrations require approved technical/commercial access.

Each connection should eventually show:

- connection status;
- last sync;
- what data it contributes;
- permission/control state;
- disconnect capability.

Connected data feeds the shared GAL Evidence Layer rather than defining the profile directly.

## Provenance / Data Quality

Every meaningful profile value should support provenance metadata such as:

`value + source + measured_at + imported_at + quality/confidence + golfer override + freshness`

The UI should distinguish measured, self-reported, inferred, and missing data where that distinction materially affects a fitting or insight.

## Progressive Completion

GAL must provide value before the entire profile is complete.

AI Fitting checks the profile/evidence layer and asks only for information still needed for the category-specific fit.

Example pattern:

`GAL already knows 14 of the 16 inputs needed for your Driver Fit. We just need 2 more.`

Different equipment categories may require different missing inputs.

## Trust / Control

The approved mobile direction visibly reinforces:

- privacy;
- golfer control;
- editable/overridable values;
- source/date context;
- progressive learning over time;
- data reuse without repetitive questioning.

Do not claim that data is never sold unless that statement is formally adopted in GAL's privacy/legal policy. Product copy should remain consistent with final approved privacy terms.

## Mobile Interaction Rules

- Mobile-first layout.
- Large, thumb-friendly primary actions.
- Practical minimum touch targets around 44x44 px.
- Readable body text and strong contrast.
- Short cards and graphical capture over long forms.
- Save progress automatically where appropriate.
- Allow the golfer to leave and resume without losing work.
- Progressive disclosure for advanced measurements and telemetry.
- Avoid forcing all sections to completion in one session.

## Relationship to GAL AI Fitting

The Golfer Profile is the shared golfer-data foundation for the locked fitting sequence:

`Golfer Profile + Connected Evidence -> Golfer Need -> Target Equipment Characteristics -> Compatible Configurations -> Ranked Options -> Explanation -> Outcome`

Characteristics Before Brands remains a governing editorial-integrity rule.

## Reference Status

The approved mobile mockup generated on 2026-09-03 is the current visual reference for this spec. Implementation must use the exact approved GAL Motion Arc brand assets rather than approximated/generated logo artwork.