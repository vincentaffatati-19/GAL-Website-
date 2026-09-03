# GAL Mobile Golfer Profile UX — Locked

Status: USER-APPROVED / LOCKED UX DIRECTION  
Date: 2026-09-03  
Product surface: My GAL authenticated Golfer Profile on mobile

## Decision

The user-approved five-screen **GAL Mobile Golfer Profile Experience** mockup from the 2026-09-03 design review is the authoritative mobile UX composition reference for the Golfer Profile.

The locked storyboard is:

1. **Profile Home** — golfer identity and profile summary at a glance.
2. **You / Measurements** — graphical body measurements, including height, wrist-to-floor, hand size, measurement provenance/date, and measurement guidance.
3. **Your Swing** — visual swing presentation with available measured/observed/self-reported performance data and progressive disclosure.
4. **Your Miss** — graphical capture of finish direction, shot shape, and clubface strike location.
5. **Connected Golf** — connection/status surface for approved external golf data sources and a summary of what GAL learned from those sources.

This visual and interaction direction is locked unless the user explicitly approves a later change.

## Core Product Rule

**Tell GAL Once. Connect It Once. Use It Everywhere.**

A valid, semantically compatible golfer datum already known to GAL must be reused across My GAL, My Bag, Buyers Guides, fittings, recommendations, insights, comparisons, and future GAL products. GAL does not ask the golfer to re-enter the same information merely because the golfer entered another workflow.

Known values remain reviewable and editable. Reuse must respect context: for example, a driver miss must not automatically be treated as an iron miss.

## Profile Home

Profile Home should communicate what GAL knows without becoming a database form. It includes:

- age/gender-appropriate golfer representation;
- golfer name/display identity and handedness;
- a secondary profile-completeness/data-readiness indicator;
- visible Tell GAL Once reinforcement;
- tappable sections for You, Your Game, Your Swing, Your Miss, Where You Play, and Connected Golf;
- concise known/missing counts or equivalent readiness language;
- honest attention states for useful missing information.

Profile completion is not a golfer-performance score. The more important message is whether GAL has enough appropriate data for a particular analysis and what additional information would materially improve it.

The persistent primary navigation remains **Today | My Bag | Insights | Guides | Progress**. Profile is accessed through golfer/avatar/account context and does not become a sixth primary tab.

## Adaptive Golfer Representation

The graphical golfer must appropriately reflect the golfer rather than always using the same adult male model.

Presentation may adapt using relevant profile information such as:

- age band;
- gender/presentation choice where provided;
- junior vs adult status;
- handedness;
- appropriate non-stereotyped visual proportions where supported.

A junior golfer must not be represented as an adult. Gender or age must not be used as a shortcut for fitting conclusions when direct measurements/performance evidence is available.

Growth-sensitive measurements for juniors require more frequent freshness checks than stable adult measurements.

## You / Measurements

Body measurement capture is visual first. The approved mobile pattern uses a golfer illustration with measurement lines/callouts rather than a conventional list of text fields.

Initial fitting-relevant measurements include:

- height;
- wrist-to-floor;
- hand size;
- longest-finger measurement where required by fitting methodology;
- handedness.

Wrist-to-floor receives an illustrated measurement guide showing the correct measurement relationship from wrist crease to floor. User-entered measurements retain source and date rather than becoming context-free values.

The system should support freshness prompts such as confirming or remeasuring an old wrist-to-floor value. Camera-assisted measurement is deferred until accuracy is validated.

## Your Game

Your Game includes golfer context such as:

- Handicap Index or typical scoring range;
- rounds/frequency where useful;
- golfer goals;
- ranked equipment/performance priorities such as consistency, accuracy, distance, forgiveness, feel, and lower scores.

Authoritative connected values such as Handicap Index should be distinguishable from self-reported values.

## Your Swing

Swing data uses the same visual-first/progressive-disclosure philosophy as the locked mobile Driver experience.

Possible data includes, when actually available:

- driver club speed;
- ball speed;
- carry;
- launch;
- spin;
- attack angle;
- club path;
- face data;
- dispersion;
- strike/contact information;
- representative iron carry or other fitting-relevant club metrics.

The summary screen shows only the most useful known metrics. Deeper data is available through progressive disclosure.

Every value retains provenance and freshness. Example labels include Measured, Observed, Self-Reported, and Inferred/Estimated where governed. Missing data should explain why adding it matters and offer appropriate capture/connection paths instead of displaying unexplained N/A fields.

## Your Miss

The approved mobile miss workflow is graphical and separates distinct concepts rather than reducing the golfer to one miss label.

Capture independently:

1. where the shot usually finishes;
2. typical curvature/shape;
3. typical strike location on the clubface;
4. frequency/context where useful.

The interface uses a visual hole/fairway for finish tendency, graphical shot shapes, and a tappable clubface for strike location.

Miss profiles are equipment/context aware. Driver miss data is not automatically substituted for iron miss data.

## Where You Play

The environment profile may combine golfer-selected location with governed derived context such as elevation and appropriate environmental information.

The UI must distinguish derived/observed information from golfer-entered course-condition preferences or descriptions. Environmental information can inform fitting/performance interpretation but must not create unsupported precision.

## Connected Golf

Connected Golf is a first-class Profile surface supporting **Connect It Once**.

The approved visual pattern shows connection status, the type of information supplied, freshness/last synchronization where appropriate, and what GAL learned or updated.

Candidate sources include handicap/scoring systems, on-course shot tracking, launch monitors, and golf-device ecosystems. Specific vendors such as GHIN, Arccos, TrackMan, Garmin Golf, or others may only be represented as live integrations when GAL has approved technical/commercial access. A mockup logo is not evidence that an integration exists.

External systems feed the **GAL Evidence Layer**; they do not become GAL's canonical profile model.

## Evidence and Provenance

Golfer profile values should conceptually retain:

`value + semantic context + source + source type + observed/measured date + imported date + freshness + quality/confidence classification + golfer override/history where applicable`

GAL preserves relevant observations rather than destructively overwriting conflicting evidence. The best evidence is selected for the question being answered, not through one universal source ranking.

For example, launch-monitor data may be superior for spin/launch while on-course observations may be superior for real-world playing distance.

## Data Quality Visual Language

The mobile experience uses a consistent, accessible visual language for evidence quality/source. Color alone must not communicate meaning.

Candidate classes include:

- Measured / Verified;
- Observed / On-Course;
- Self-Reported;
- Inferred / Estimated;
- Missing.

Exact confidence claims require a governed methodology. Do not label data high confidence merely because it came from a named external source.

## Freshness

The Profile is a living record. GAL should prompt for updates when information becomes meaningfully stale rather than routinely asking the same questions again.

Examples:

- growth-sensitive junior body measurements;
- old wrist-to-floor or hand measurements;
- updated handicap from a connected authoritative source;
- changed equipment;
- old self-reported swing-speed estimates superseded by measured data.

Freshness thresholds must be defined by data type and use case.

## Mobile Interaction Principles — Locked

The approved Profile storyboard uses the same broader GAL mobile principles as the Driver flow:

- **Visual first** — large, meaningful golf/body graphics before dense tables.
- **Progressive disclosure** — summary first, deeper detail only when requested.
- **Always contextual** — explain why a piece of information matters to the golfer/equipment decision.
- **Fresh and useful** — show age/source where it affects trust or relevance.
- **One source of GAL truth** — the shared Profile/Evidence Layer feeds all GAL experiences.
- **One obvious next action** — capture, confirm, connect, update, or continue.
- practical mobile touch targets and accessible text/contrast;
- no desktop-dashboard shrinking.

## Universal Known-Data Pattern

When another GAL workflow needs a value already present in the Profile, the interface should show the existing value rather than ask the question again.

Example:

**Driver Swing Speed**  
`94 mph` — GAL knows this  
`Use 94 mph | Change`

The exact wording can be refined, but the behavior is mandatory.

## Relationship to Driver and Other Equipment Experiences

The locked Driver mobile experience consumes this shared Profile/Evidence Layer. Woods, Hybrids, Irons, Wedges, Putter, Ball, Buyers Guides, comparison tools, and future fitting products must follow the same rule.

A product-specific workflow may request genuinely missing or semantically different information, but it must never recreate a siloed golfer profile.

## Truthfulness / Mockup Guardrail

The visual storyboard contains illustrative golfer names, measurements, percentages, swing values, miss percentages, vendor connection states, dates, and other example content. These are design examples only.

Production must not fabricate:

- profile completion values;
- measurements;
- swing metrics;
- miss distributions;
- connected-service status;
- synchronization timestamps;
- confidence levels;
- environmental values;
- fitting conclusions.

All production values must come from governed sources or be presented as missing/unknown.

## Acceptance Criteria

The mobile Golfer Profile is UX-complete when:

1. the approved five-screen visual hierarchy is preserved;
2. the exact approved GAL Option 7A Motion Arc brand assets are used in implementation;
3. adaptive golfer representation works appropriately for adults, juniors, gender/presentation and handedness without stereotyping fitting logic;
4. body measurement capture is graphical and wrist-to-floor guidance is clear;
5. swing data exposes provenance and progressive detail;
6. miss capture separates finish, shape and strike;
7. Connected Golf feeds the GAL Evidence Layer rather than vendor-specific profile silos;
8. Tell GAL Once / Connect It Once is enforced across products;
9. stale/missing data receives useful contextual prompts;
10. no illustrative mockup metric becomes a production claim without real evidence;
11. mobile accessibility and touch behavior are verified;
12. the golfer can always review/change appropriate profile data.

## Locked Reference

The user explicitly approved and locked the 2026-09-03 five-phone **GAL Mobile Golfer Profile Experience** mockup showing Profile Home, You / Measurements, Your Swing, Your Miss, and Connected Golf. Preserve this UX direction as the implementation reference unless a later user-approved design explicitly supersedes it.