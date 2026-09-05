# GAL UX10.02 — Golfer Profile Experience

**Status:** USER-APPROVED / LOCKED  
**Date:** 2026-09-04  
**UX family:** `GAL-UX10`  
**UX version:** `GAL-UX10.02`  
**First implementation candidate:** `GAL-UX10.02-RC1`  
**Product surface:** Authenticated Golfer Profile across desktop and mobile

## 1. Decision

The user-approved mobile Golfer Profile reference supplied on 2026-09-04 becomes the governing Profile interaction reference within the UX10 family.

UX10.02 does not replace the UX10.01 tee-box and bag-personalization architecture. It extends the same My GAL product system with a governed, progressive Golfer Profile experience.

The governing product principle is:

`Tell GAL Once. Connect It Once. Use It Everywhere.`

The Profile must reuse known, valid golfer information across GAL and ask again only when a value is missing, stale, context-specific, or requires explicit user confirmation.

## 2. Authoritative visual reference

- file: `Profile Mobile Screen(1).png`
- dimensions: 1606 × 979
- SHA-256: `36e3e9d606534cc7af4dd35f1aae81fe7f86fdc4515b90d741c8da2b909c24e8`

The reference is authoritative for the mobile information architecture, progressive-disclosure model, visual density, major controls, profile areas, data-quality semantics, and connected-golf presentation.

The large numbered headings and the bottom design-principle strip belong to the presentation board and are not literal app UI. Their behaviors are governing requirements.

## 3. Locked Profile architecture

The mobile Profile flow is:

`Profile Home -> You / Measurements -> Your Swing -> Your Miss -> Connected Golf`

`Where You Play` remains a sixth Profile Home area and is accessible from Profile Home without becoming a sixth mandatory mobile progression step.

Desktop uses the same information model with more room for side-by-side presentation. Desktop must not invent a second navigation model.

Golfer Profile remains separate from the five primary My GAL navigation items:

`Today | My Bag | Insights | Guides | Progress`

## 4. Profile Home

Profile Home must show:

- golfer identity block with avatar/photo when available;
- golfer display name;
- handedness;
- concise golfer descriptor when supported by governed data;
- profile-completion indicator;
- `Tell GAL Once` trust/personalization message;
- six summary areas:
  - You
  - Your Game
  - Your Swing
  - Your Miss
  - Where You Play
  - Connected Golf
- per-area completion/state indicator;
- concise known-data summary per area;
- clear affordance to open each area.

### 4.1 Profile completion

Profile completion must reflect governed profile-field coverage, not golfer skill, fit confidence, or analytics quality.

A percentage may be shown only when the denominator and required-field policy are explicitly defined. Until then, use truthful coverage language such as `4 of 6 areas started` or equivalent.

## 5. You / Measurements

The You workspace must include, when available:

- height;
- wrist-to-floor;
- hand size;
- handedness;
- measurement source/provenance;
- observed/updated date;
- freshness state;
- clear `Update Measurements` action;
- `How to measure` guidance.

The presentation should be visual-first. A golfer/body measurement illustration may be used only as an approved/generic explanatory visual; it must not imply that GAL has an exact physical scan when it does not.

Missing values must show an honest incomplete state.

## 6. Your Game

Your Game remains a first-class Profile Home area and should include governed facts such as:

- handicap/scoring context;
- goals;
- priorities;
- play frequency;
- skill/experience descriptors when user-provided or governed.

It does not need to be one of the five mandatory mobile progression screens from the reference; it is accessible from Profile Home.

## 7. Your Swing

Your Swing must use a focused workspace with a club selector beginning with:

`Driver | 7-Iron`

When governed data exists, the workspace can show:

- club speed / driver speed;
- ball speed;
- launch;
- spin rate;
- carry;
- attack angle;
- club path;
- source system;
- observation date;
- data-quality state.

A clear `View All Swing Data` action is required.

If relevant swing data is missing, the workspace must show a useful next action, for example connecting/importing launch-monitor data, without fabricating metrics.

## 8. Your Miss

Your Miss is a guided capture experience and must preserve three separate concepts:

1. typical finish direction;
2. typical shot shape;
3. typical strike location.

### 8.1 Finish direction

Provide a visual target/dispersion control for left, straight, right, short, and long tendencies or an equivalent governed representation.

### 8.2 Shot shape

The locked option set is:

`Hook | Pull | Straight | Push | Slice`

Do not substitute the older `Left | Draw | Straight | Fade | Slice` model.

### 8.3 Strike location

Provide a visual clubface strike-location selector with heel/toe/high/low context.

The experience ends with a clear `Save My Miss Profile` action.

Selections are user-reported profile facts unless connected/measured evidence explicitly provides them.

## 9. Where You Play

Where You Play must remain available from Profile Home and include usual playing context such as:

- location/course context;
- elevation;
- temperature;
- wind;
- firmness/green conditions where governed.

Usual playing context must remain distinct from the conditions of a specific fitting/test session.

## 10. Connected Golf

Connected Golf must be a real source-status workspace, not a generic illustrative grid.

The UX must support explicit source cards for the approved/integrated source set. The reference establishes the desired model for:

- GHIN;
- Arccos;
- TrackMan;
- Garmin Golf;
- Other Launch Monitor / import path.

Each source card must support truthful states such as:

- Connected;
- Not connected;
- Connection unavailable;
- Reconnect required;
- Last sync time/date where known.

Do not label a provider `Connected` unless GAL has a valid connection state.

Provider names/logos must only be shown where use is approved and technically supported. Otherwise use a generic source label until approval/integration is complete.

## 11. What GAL Learned

Connected Golf includes a summary module describing what profile knowledge GAL has derived or updated from approved connected sources.

This module must:

- distinguish source data from derived facts;
- show the number/type of profile items updated where useful;
- never imply an automatic inference that was not actually performed;
- preserve provenance and freshness.

## 12. Data quality legend

The Profile experience must expose a consistent data-quality language.

Initial visible categories:

- Measured — high-confidence instrument/source measurement;
- Observed — on-course or session evidence;
- Self-Reported — golfer-entered value;
- Inferred / Estimated — model-derived or estimated value, only when governance allows.

The exact label/color system must be consistent across Profile, Driver intelligence, fitting, and future GAL surfaces.

Confidence, freshness, and provenance remain separate attributes even when the UI summarizes them compactly.

## 13. Progressive disclosure

The mobile Profile must not render the entire profile as one long page.

Required behavior:

- Profile Home is the hub;
- selecting an area opens a focused screen/workspace;
- one primary task per screen;
- back/close preserves context;
- important actions are placed at the end of the focused flow;
- the five-part bottom navigation stays viewport anchored on mobile;
- the golfer does not lose where they are within My GAL.

Desktop may use a persistent Profile sidebar/section rail or master-detail layout as long as it preserves the same Profile Home + focused-area model.

## 14. Visual principles

The visual behavior from the reference is locked:

- Visual First — important concepts use clear visuals rather than dense lists;
- Progressive Disclosure — summary first, deeper detail on demand;
- Always Contextual — information is tied to the golfer's game and goals;
- Fresh and Useful — source/date/freshness remain visible when relevant;
- One Source of Truth — Profile facts are shared across GAL rather than duplicated.

Use the locked Option 7A GAL brand system and UX10 navy/orange visual language.

Crude cartoon/schematic substitutes are not acceptable for high-value golfer/swing/clubface visuals.

## 15. Data model and truthfulness

Existing `gal_profile_facts` remains the golfer-safe profile fact source unless a later data-governance change explicitly replaces it.

Profile facts preserve, where available:

- `fact_key`;
- `fact_value`;
- source;
- source category;
- confidence;
- user-confirmed state;
- scope;
- stale-after policy;
- observed date;
- updated date;
- source reference.

UX10.02 must not create sample production facts to make screens look complete.

If data is unavailable, the UX shows the incomplete state and the correct next action.

## 16. Required implementation corrections from current UX10.01

The current Profile implementation must be corrected in the following ways:

1. Replace the current long-page Profile renderer with Profile Home + focused workspaces.
2. Add the golfer identity block and governed completion treatment.
3. Preserve all six Profile Home areas, including Your Game and Where You Play.
4. Build a dedicated You/Measurements workspace.
5. Build a dedicated Your Swing workspace with Driver / 7-Iron selection.
6. Build the locked Your Miss model: finish direction + Hook/Pull/Straight/Push/Slice + strike location + save action.
7. Replace generic illustrative connection cards with truthful Connected Golf source states.
8. Add last-sync/freshness presentation where data exists.
9. Add the `What GAL Learned` summary.
10. Add a visible data-quality legend/system.
11. Preserve the five-part mobile bottom navigation.
12. Remove or retire older Profile visual primitives that conflict with the approved reference.
13. Keep existing source/freshness/data-governance logic wherever valid.

## 17. Testing requirements

Before `GAL-UX10.02-RC1` is reviewable, automated verification must prove:

- Profile route still remains outside the five primary navigation items;
- six Profile Home areas render from governed data/state;
- mobile Profile uses focused screens rather than one long page;
- Your Miss uses `Hook | Pull | Straight | Push | Slice`;
- no unsupported sample golfer metrics appear in built JS/HTML;
- missing facts show incomplete states;
- source/freshness metadata remains available;
- Connected Golf never claims `Connected` without valid connection state;
- bottom mobile navigation remains viewport anchored;
- accessibility keyboard/focus behavior works for Profile area navigation and selectors;
- production remains untouched until explicit approval.

## 18. Relationship to UX10.01

UX10.02 supersedes UX10.01 only for the Golfer Profile experience and current UX version pointer.

The following UX10.01 rules remain locked and unchanged:

- tee-box and bag visuals are independent;
- presentation preferences do not affect analytics;
- combined course+bag scene is forbidden;
- My GAL primary navigation remains Today | My Bag | Insights | Guides | Progress;
- governed-data truthfulness rules remain in force;
- production promotion still requires explicit user approval.
