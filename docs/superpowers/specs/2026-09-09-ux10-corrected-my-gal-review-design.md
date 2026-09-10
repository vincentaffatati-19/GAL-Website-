# UX10 Corrected My GAL Review Design

## Goal
Restore the previously approved UX10 My GAL visual experience for review without regressing the newer governed Profile, Bag, recommendation, media, and authentication architecture.

## Recovered UX contract
The recovered UX10.01 review preview is the visual baseline for My GAL. My Bag is not a generic list-first page: it is a visual tee-box/course scene with the golf bag as the focal point, status/need controls surrounding the bag, and a tee-box selector that changes environmental context. The My GAL navigation exposes Today, My Bag, Insights, Guides, Progress, and Golfer Profile.

## Corrected review flow
My GAL -> Tee-Box My Bag -> Golfer Profile -> Bag Needs -> Recommendations -> Compare -> Bag Health / Bag Value.

## Architecture
- Keep the merged UX10 integrated RC as the base.
- Keep `gal_profile_snapshot()` and `gal_profile_apply_patch()` as the authoritative Profile service contract.
- Keep Supabase authentication/RLS and canonical GAL user identity provisioning.
- Keep `GAL-REC-1.0` as the recommendation contract; recommendation output carries canonical product IDs and scoring/explanations, while product truth is hydrated from governed equipment projections.
- Keep existing bag persistence through `GALBagAdapter` where available, with the current review-safe local fallback when the remote bag contract is unavailable.
- Restore the tee-box presentation as a view over bag/profile/recommendation state; do not duplicate or fork product/profile truth into the UI.

## My Bag tee-box view
- Primary surface is the course/tee-box scene.
- Central bag stage visualizes the current bag and club composition.
- Left-side status rail summarizes Driver, Fairway/Hybrid, Irons, Wedges, Putter, and Ball states.
- Right-side intelligence rail shows club count, open gaps, current recommendation need, and Bag Health/Value entry points.
- Tee-box selector is retained as a contextual visual control and records the selected tee context locally for review; it must not mutate governed Profile facts unless the golfer explicitly saves a play-context fact.
- Empty bag remains a valid state and routes to Buyer Guides/recommendations rather than fabricating equipment.
- Mobile retains the scene-first experience with the bag still visually dominant.

## Golfer Profile view
- `profile.html` is a visible My GAL destination, not a hidden backend capability.
- Signed-out state offers passwordless email sign-in using the existing publishable-key Supabase client.
- Signed-in state loads `gal_profile_snapshot()`.
- Editable launch fields: handicap/skill band, driver swing speed, handedness, primary driver miss, preferred trajectory/launch, top-of-bag target distance, and home/play location text context where governed location selection is not yet available.
- Saving calls `gal_profile_apply_patch()` by profile area using `SELF_REPORTED`, `profile_form`, global scope, and explicit units.
- After save, reload the snapshot and make revised Profile data immediately available to recommendations.
- Empty Profile is shown honestly and never replaced by demo facts.

## Recommendation integration
- My Bag links directly to `recommendations.html` as Bag Needs.
- Profile changes invalidate stale in-memory recommendation state by forcing a fresh Profile snapshot on the recommendation page.
- Existing compare, canonical Add to Bag, duplicate warning, 14-club guard, missing-price behavior, and governed media remain unchanged.

## Review navigation
Create a simple My GAL subnavigation shared by `my-gal.html`, `profile.html`, and `recommendations.html`: My Bag, Golfer Profile, Bag Needs / Recommendations. Existing global GAL header/footer remains intact.

## Error handling
- Auth unavailable: show a recoverable sign-in/client message.
- Snapshot/RPC failure: show the returned error without substituting fake data.
- Profile save failure: retain typed form values and show the error.
- Bag load failure: fall back only to the existing review/local bag adapter and label it as browser-local.
- Missing governed product image: keep the governed placeholder behavior.

## Testing
- Contract test for Profile form field -> `gal_profile_apply_patch()` payload mapping.
- Contract test that Profile reload follows a successful save.
- Contract test that My Bag renders category state from canonical bag records and enforces 14-club count semantics.
- DOM/static contract that the tee-box scene, bag stage, Profile destination, recommendations destination, and mobile scene CSS exist.
- Regression: existing recommendation engine/runtime/auth and Driver/Fairway-Hybrid image contracts remain green.

## Scope exclusions
- Do not merge to production.
- Do not redesign the Buyer Guides.
- Do not invent new equipment scoring or Profile facts beyond the launch fields above.
- Do not replace remaining Mizuno image holds with ungoverned imagery.
