# GAL Golfer Profile and Connected Data Design

Status: APPROVED / LOCKED  
Date: 2026-09-03  
Product surface: Golfer Profile, My GAL, Buyers Guides, fitting workflows, recommendation and longitudinal intelligence

## 1. Governing Rule — Tell GAL Once

GAL operates under a permanent product rule: **Tell GAL Once.**

When a golfer provides information to GAL, GAL remembers it and responsibly reuses it across all applicable GAL tools, Buyers Guides, My Bag, fitting workflows, recommendations, longitudinal intelligence, and future products.

GAL must not ask the golfer for the same information again when a valid, semantically compatible value already exists.

Existing values must remain visible and editable when they materially affect a recommendation. GAL must track source, date/freshness, and data quality so stale or context-incompatible values are not silently reused.

Examples:

- handedness may be reused broadly;
- height and wrist-to-floor may be reused for club-length/lie workflows while fresh enough;
- a typical driver miss must not automatically be treated as the golfer's iron miss;
- a measured value may coexist with a golfer estimate rather than blindly overwrite it.

The extended operating principle is: **Tell GAL Once — or Connect It Once.**

## 2. Golfer Profile Purpose

The Golfer Profile is the persistent golfer-data foundation that powers GAL products. It is not a one-time onboarding form.

The profile separates:

- who the golfer is;
- how the golfer physically sets up;
- how the golfer plays;
- how the golfer swings;
- what the golfer commonly misses;
- where the golfer normally plays;
- what evidence GAL has for each conclusion.

The profile feeds My GAL, My Bag, Buyers Guides, equipment fitting, recommendations, longitudinal insights, and future analytics.

## 3. Graphical and Interactive UX

The Golfer Profile must be primarily graphical and interactive rather than a long conventional form.

The approved conceptual structure contains five visual profile areas:

1. **You** — physical measurements and setup.
2. **Your Game** — ability, scoring context, goals and preferences.
3. **Your Swing** — swing speed, carry, launch-monitor and related performance data.
4. **Your Miss** — directional, curvature, contact and strike-pattern visualization.
5. **Where You Play** — location, altitude and playing-environment context.

The preferred persistent identity direction is **My Golfer Digital Profile**, which presents the golfer and the major fitting inputs at a glance while allowing each section to be tapped for review/update.

Profile completion should feel progressive and useful. Missing information should be framed as an opportunity to improve fitting quality, not as a failure.

## 4. Adaptive Golfer Representation

The graphical golfer representation must adapt to the golfer rather than showing one generic adult male.

The visual system should consider:

- age band;
- gender/presentation preference where supplied;
- handedness;
- general body proportion cues from measured height where useful and appropriate.

A junior golfer must be represented as a junior, not as an adult. An adult woman must not be represented by a default male golfer. Older golfers should not automatically receive a young-adult visual identity.

The visual adaptation must avoid stereotypes about skill, athletic ability, body shape, strength, or equipment preference.

For junior golfers, measurements such as height and wrist-to-floor should have shorter freshness expectations because growth can make measurements stale quickly. GAL should prompt for remeasurement when appropriate.

Any minor-account capability requires a separate privacy, consent and parental-control review before production launch.

## 5. Core Fitting Inputs

GAL should prioritize direct measurements and observed golf data over demographic proxies.

Strongly encouraged fitting inputs include:

- handedness;
- height;
- wrist-to-floor distance;
- handicap or typical scoring range;
- driver swing speed or driver carry;
- 7-iron carry or comparable reference-club distance;
- common directional miss;
- common strike/contact miss;
- equipment goals and performance priorities;
- home/typical playing environment.

Recommended additional inputs include:

- hand size;
- longest-finger measurement;
- driver swing speed when available;
- ball-flight height;
- tempo/transition description;
- current club specifications;
- rounds played per year.

Advanced measured inputs may include:

- club speed;
- ball speed;
- launch angle;
- spin rate;
- attack angle;
- club path;
- face angle;
- impact location;
- carry distance;
- dispersion.

Age and gender may be retained as contextual/profile attributes, but they must not independently determine an equipment recommendation when more relevant measured data exists. Weight is not a default required fitting field unless GAL establishes a specific evidence-backed use case.

## 6. Wrist-to-Floor Measurement UX

Wrist-to-floor is a core club-sizing input and must have a dedicated graphical measurement experience.

The UX should instruct the golfer to:

- stand naturally on a level surface;
- use normal golf footwear or equivalent footwear consistent with the fitting method;
- let the arms hang naturally;
- measure vertically from the defined wrist reference point to the floor;
- enter the measurement in the golfer's preferred units.

The screen should visually show the measurement path from wrist to floor.

Camera-assisted measurement may be explored later but must not be treated as production-grade fitting data until validated for accuracy.

## 7. Miss Pattern UX

GAL should not reduce miss capture to a single dropdown.

Directional miss capture should use an interactive fairway or target visualization. The golfer can indicate common finish direction and curvature, for example:

- pull;
- hook;
- straight;
- push;
- slice.

Frequency should be captured separately so GAL can distinguish an occasional miss from the primary miss.

Impact/strike should use a graphical clubface or relevant club-specific contact view, allowing indications such as:

- heel;
- center;
- toe;
- high;
- low.

For irons and wedges, additional common outcomes may include fat/behind-ball and thin contact.

Self-described miss patterns and measured/connected observations must be retained separately. GAL may later compare perceived versus observed patterns when sufficient evidence exists.

## 8. Playing Environment

GAL should capture where the golfer normally plays and should distinguish a home/default environment from conditions attached to a particular fitting or performance observation.

Relevant environmental context may include:

- location;
- altitude/elevation;
- temperature;
- humidity where useful;
- wind context;
- course firmness/conditions where useful.

Environment-derived normalization is a future intelligence capability. GAL must not present normalized distances or environmental adjustments as factual until the methodology is defined and validated.

## 9. Connected Golf Data

The Golfer Profile must support external authorized data sources so golfers do not repeatedly re-enter information that trusted systems already know.

Target connection categories include:

- launch monitors;
- on-course shot tracking and GPS systems;
- scoring and handicap systems;
- equipment/fitting systems where partner access exists;
- fitness/body-measurement sources only where clearly relevant and consented;
- weather/location services for contextual normalization.

Candidate ecosystems include products such as Arccos, Garmin, GHIN/USGA systems, TrackMan, Foresight, FlightScope and similar platforms. GAL must evaluate each provider's current API, export, licensing, OAuth and commercial-access terms individually before implementation. The existence of a consumer-facing app does not imply public API access.

No vendor is allowed to become the GAL source-of-truth data model.

## 10. GAL Evidence Layer

Connected systems feed a GAL-controlled evidence layer rather than becoming the golfer profile directly.

Conceptual architecture:

`Golfer Input + Connected Apps + Launch Monitors + GAL Testing + Environment -> GAL Evidence Layer -> Golfer Profile -> My Bag -> Guides -> Fitting -> Insights`

Each material observation should preserve provenance metadata sufficient to answer:

- what is the value;
- what does it mean;
- where did it come from;
- when was it measured/observed;
- when was it imported;
- whether it was measured, observed, inferred or self-reported;
- whether it remains fresh enough for the current use;
- whether the golfer has corrected/overridden it.

A conceptual record therefore includes:

`value + semantic context + source + measured_at/observed_at + imported_at + data quality + freshness + golfer correction/override`

## 11. Data Quality / Provenance Labels

Golfer-facing data should use understandable provenance states such as:

- **Measured / Verified**;
- **Observed**;
- **Self-Reported**;
- **Inferred**;
- **Missing**.

Exact labels and eligibility rules must be governed before implementation. GAL must not imply that a third-party imported value has been GAL-verified unless GAL has actually validated it under an approved process.

## 12. Context-Specific Evidence Selection

GAL must not blindly overwrite one source with another when values disagree.

Different evidence can be best for different questions. For example:

- launch-monitor data may be best for launch, spin, face/path and controlled carry;
- on-course shot tracking may be best for real-world playing distance and dispersion;
- an authoritative handicap source may be best for current Handicap Index;
- a GAL-controlled fitting/test may be best for the conditions it directly measured.

GAL should preserve observations and select/derive the most relevant value for the question being answered using a governed context-specific evidence policy.

No universal source hierarchy should be assumed until the specific data domain and use case are defined.

## 13. Connected Apps UX

Golfer Profile should include a **Connections / Connect Your Golf** area.

The experience should group sources by category such as:

- Launch Monitors;
- On-Course / GPS / Shot Tracking;
- Handicap / Scoring;
- Other approved data sources.

Each connection should clearly show:

- connection status;
- last successful synchronization;
- categories of information being supplied;
- any current synchronization error;
- golfer controls to disconnect or manage the connection.

Connection should be permission-based. GAL should request only the data needed for disclosed product purposes.

## 14. Progressive Onboarding

New-profile onboarding should offer at least two paths:

- **Connect My Golf Apps** — use authorized external data to prefill what GAL can reliably understand;
- **Build It With Me** — interactive graphical profile setup.

These paths can be combined. Connecting sources should reduce the number of questions GAL subsequently asks.

Example product behavior:

`GAL already knows 14 of the things we need for your equipment profile. We need 6 more to improve your fitting.`

GAL must not force a golfer to know technical values such as driver swing speed. Unknown values remain missing, may be estimated only under a separately approved method, and can be supplied later.

## 15. Profile Completeness vs. Fitting Confidence

GAL may show a factual **Profile Completeness** / **Data Completeness** indicator based on whether expected profile inputs exist.

Completeness describes GAL's information, not the golfer's skill and not the quality of the golfer's equipment.

A future **Fitting Confidence** score would require a separately governed methodology defining input importance, provenance, freshness, compatibility and uncertainty. Do not equate profile completion percentage with fitting confidence.

## 16. Reuse Across GAL Products

All GAL surfaces must consume the shared profile/evidence foundation rather than maintaining isolated questionnaires.

This includes:

- My GAL;
- My Bag;
- Driver, woods, hybrid, iron, wedge, putter and ball fitting experiences;
- Buyers Guides;
- comparisons;
- recommendations;
- longitudinal insights;
- future commerce-routing and equipment-intelligence products.

When a surface requires an existing value, the default behavior is to reuse it, clearly show it where decision-relevant, and allow the golfer to update it.

When a surface needs a semantically different value, GAL may ask a new question even if it appears similar. That exception must be explainable and must not become an excuse for duplicate data capture.

## 17. Privacy and Trust

Golfer profile and connected-data collection must follow GAL's first-party data strategy: permission-based collection tied to clear user value, transparent reuse, least-necessary access and user control.

GAL should not collect profile data merely because it might be useful someday. Each field and connection should have a defined product purpose.

Disconnecting a third-party source must stop future synchronization. Retention/deletion behavior for already imported observations must be defined under the broader GAL privacy/data-retention policy.

## 18. Design Consequence for Driver and Other Fittings

The future Driver detail/fitting screen should assume this shared profile/evidence architecture exists.

It should therefore be able to distinguish:

- data GAL already knows;
- new data required specifically for Driver fitting;
- self-reported versus measured/observed evidence;
- stale data that should be refreshed;
- context-specific evidence such as launch-monitor versus on-course performance.

Driver UX must comply with Tell GAL Once and must never restart a generic fitting questionnaire when relevant compatible profile data already exists.

## Decision

The Golfer Profile, Tell GAL Once / Connect It Once principle, adaptive golfer representation, connected golf-data strategy, provenance-aware GAL Evidence Layer, progressive onboarding and context-specific evidence reuse are **locked architectural and UX requirements** for GAL.

These requirements apply to all future GAL tools and products unless explicitly superseded through a governed design decision.