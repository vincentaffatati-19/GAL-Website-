# GAL Portal Longitudinal Integration Design

Status: Proposed for implementation review  
Date: 2026-08-31  
Scope: Registered-user and subscriber/customer portal integration with the governed longitudinal backend

## 1. Purpose

Add an authenticated GAL portal layer that exposes governed golfer intelligence without rebuilding the existing public flat-file website and without weakening the production Supabase security model.

The portal will become the authenticated product surface for longitudinal golfer intelligence while the existing public website remains the editorial, education, buyer-guide, and acquisition surface.

The same portal components and data contract must serve both registered users and subscribers. Subscriber differences are entitlement-driven enhancements, not separate portal implementations.

## 2. Design Principles

1. Keep the public GAL website static unless a page specifically requires authenticated functionality.
2. Use Supabase Auth for identity and session management.
3. Browser code may use only the Supabase publishable key and authenticated user session.
4. Browser code may read only golfer-safe tables protected by RLS.
5. Browser code must never receive or embed the Supabase service-role key.
6. Longitudinal mutations must pass through Supabase Edge Functions that invoke existing service-only RPCs.
7. Registered-user and subscriber/customer portal changes must be implemented from shared components and shared contracts so the experiences cannot drift.
8. Staging verification is required before production release.
9. No production golfer data may be copied into development or staging unless explicitly anonymized/sanitized.

## 3. Current-State Constraints

The repository currently implements a flat/static website. It has a public/runtime configuration template for `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, with `SUPABASE_SERVICE_ROLE_KEY` explicitly reserved for server-only deployment secrets.

There is no existing registered-user/customer portal implementation in the current repository and no frontend integration with the new longitudinal tables or service RPCs.

The production longitudinal database is already deployed and governed. The portal must consume that contract rather than create a competing feedback architecture.

## 4. Recommended Architecture

### 4.1 Public site

Preserve the current static website for:

- home and brand pages;
- educational content;
- Build a Better Bag category pages;
- buyers guides and tools that do not require authentication;
- editorial, privacy, terms, disclosure, and contact content.

Authenticated entry points should link users into the portal without requiring the rest of the public site to migrate frameworks.

### 4.2 Authenticated portal

Create a dedicated authenticated single-page application under the existing GAL site at `/portal/`.

The portal owns:

- sign-in/session handling;
- golfer account context;
- longitudinal insight feed;
- insight detail/state;
- golfer response actions;
- account-level preferences relevant to portal delivery;
- subscriber-only enhancements controlled by entitlements;
- future My Bag, guide history, saved recommendations, and longitudinal personalization surfaces.

The portal must not duplicate static editorial pages unless authenticated context adds material value.

Keeping the portal at `/portal/` preserves the existing public-site deployment model, avoids a framework rewrite, and gives GAL one canonical authenticated entry point.

### 4.3 Trusted mutation boundary

Use Supabase Edge Functions for every browser-initiated longitudinal mutation.

Edge Functions may hold the service-role key in Supabase-managed server secrets and call only the governed RPCs required for the requested user action.

Initial operations:

- record insight presentation;
- record ACKNOWLEDGED response;
- record DISMISSED response;
- record SNOOZED response;
- record ACTED response;
- record downstream outcome when a qualifying application event occurs;
- trigger resolution/reconciliation only from governed application logic, not arbitrary browser payloads.

Each Edge Function must validate the caller's Supabase access token, resolve the authenticated GAL user server-side, and must not trust a browser-supplied `user_id` as authority.

## 5. Browser Read Contract

The browser may read only the current authenticated golfer's governed rows through RLS.

Initial golfer-safe read surfaces:

- `gal_insights`;
- `gal_insight_delivery_state`;
- `gal_insight_exposures`;
- `gal_insight_responses`;
- `gal_insight_outcomes`;
- `gal_insight_resolution_state`.

Internal-only data must remain inaccessible from the browser, including:

- `gal_insight_signals`;
- `gal_insight_exposure_events`;
- `gal_insight_resolution_events`;
- `gal_insight_resolution_rules`;
- `gal_learning_snapshots`;
- `gal_learning_snapshot_contributors`;
- `gal_learning_consent_reconciliations`;
- `gal_learning_candidates`;
- `gal_learning_evaluation_policies`;
- `gal_governance_actors`.

Portal code must not attempt to query internal tables even if a developer session has elevated local privileges.

## 6. Portal Product Model

### 6.1 Shared shell

Registered users and subscribers use one authenticated shell with:

- GAL branded header/navigation;
- account/session controls;
- responsive primary navigation;
- main content region;
- shared insight components;
- consistent empty, loading, error, and unauthorized states.

### 6.2 Insight feed

The initial portal home experience is a governed insight feed.

Each card displays only golfer-facing fields required to understand the issue:

- headline;
- golfer message;
- domain/category;
- severity/materiality presentation;
- lifecycle state;
- last meaningful update;
- applicable next action.

Raw detector evidence and internal governance metadata are not shown directly.

Default ordering should favor currently actionable `ACTIVE` or `ACKNOWLEDGED` insights, then recency/materiality. Resolved items remain accessible in history but should not dominate the active feed.

### 6.3 Insight detail

Insight detail includes:

- current golfer-facing explanation;
- current status;
- resolution status if available;
- relevant governed evidence summary suitable for the golfer;
- response history useful to the golfer;
- outcome/status history useful to the golfer;
- next recommended action;
- available response controls.

It must never expose raw source-system keys, service provenance, contributor information, governance actors, evaluation policies, or aggregate-learning internals.

### 6.4 Response controls

Initial controls:

- Acknowledge;
- Dismiss;
- Snooze;
- Take Action.

`Take Action` should navigate to the relevant GAL workflow or recommendation surface and record the response through the trusted mutation boundary.

The UI must distinguish delivery preference from analytical truth. Dismissal means stop/reduce delivery; it must not claim the underlying insight is analytically resolved.

### 6.5 Resolution presentation

Resolution is evidence-driven.

The portal may display:

- Open;
- Evidence pending;
- Resolved;
- Ineffective;
- Regressed.

A user click, recommendation view, or purchase intent alone must not be presented as problem resolution unless the governed resolution rule qualifies the outcome.

### 6.6 Subscriber entitlements

Use a shared entitlement resolver rather than separate subscriber pages.

Registered users receive the base insight experience.

Subscriber entitlements may later unlock additional longitudinal value such as:

- richer historical comparisons;
- deeper fitting context;
- enhanced recommendation explanations;
- saved scenario comparisons;
- longitudinal bag-change analysis;
- priority notifications or advanced personalization.

The first implementation slice defines the entitlement interface and shared component behavior but does not build billing. Until a production subscription source is connected, production defaults to the registered-user/base entitlement set; subscriber-specific behavior is validated with staging fixtures only. A later billing/subscription integration will supply the authoritative entitlement source without changing portal component contracts.

Entitlement state must not alter ownership/RLS boundaries. A subscriber may receive more features but never access another golfer's data.

## 7. Identity and Authorization

### 7.1 Identity chain

The authoritative identity chain is:

`auth.users.id -> gal_users.auth_user_id -> gal_users.id`

Portal Edge Functions must derive the GAL user from the authenticated Supabase identity.

### 7.2 Read authorization

All golfer-owned reads rely on existing production RLS using `gal_current_user_id()`.

The portal should not reproduce row-ownership filters solely in JavaScript as a security mechanism. UI filtering may improve presentation, but RLS remains authoritative.

### 7.3 Mutation authorization

Every mutation Edge Function must:

1. require a valid authenticated access token/session;
2. resolve the matching active `gal_users` record server-side;
3. verify that the target insight belongs to that GAL user;
4. validate the requested action against an allowlist;
5. generate/validate idempotency event keys server-side or from a constrained client token;
6. invoke the governed service RPC;
7. return only golfer-safe output.

Arbitrary service RPC names, actor IDs, rule codes, user IDs, or table names must never be accepted from a generic browser-to-server proxy.

## 8. Edge Function Contract

Prefer narrow action-specific functions rather than a generic RPC passthrough.

Initial logical interface:

- `insight-present`
- `insight-acknowledge`
- `insight-dismiss`
- `insight-snooze`
- `insight-action`

The portal invokes these through the Supabase Functions client using the authenticated access token. Future application-owned functions may record outcomes as business workflows complete.

Each function returns a small normalized result:

- success/failure;
- resulting golfer-facing insight/delivery state where needed;
- idempotent replay indicator where relevant;
- safe error code/message.

Do not return service-role errors verbatim when they could expose internal schema or governance details.

## 9. State and Data Flow

### 9.1 Feed load

1. User authenticates through Supabase Auth.
2. Browser obtains user session.
3. Browser reads RLS-protected golfer-safe longitudinal rows.
4. Portal assembles a presentation model client-side.
5. When an insight is actually presented according to product rules, portal invokes `insight-present`.
6. Edge Function resolves the golfer and invokes `gal_record_insight_presentation`.
7. UI reflects any cooldown or terminal delivery state returned by the function.

### 9.2 Golfer response

1. User selects an allowed response.
2. Browser invokes the corresponding narrow Edge Function with insight ID plus action-specific fields only.
3. Edge Function validates session, user ownership, and action.
4. Edge Function calls `gal_record_insight_response`.
5. UI refreshes the affected insight/delivery state.

### 9.3 Downstream outcome

Outcomes should be generated by trusted GAL workflows, not by a generic portal button.

Example:

`Take Action -> buyer/recommendation workflow -> qualifying event -> trusted Edge Function records outcome -> governed resolution logic may later resolve or regress insight.`

## 10. Error Handling

The portal must provide deliberate states for:

- unauthenticated session;
- expired session;
- no GAL user mapping;
- no insights yet;
- RLS-denied access;
- insight no longer actionable;
- cooldown conflict;
- idempotent replay;
- temporary network/server failure;
- invalid or stale portal action.

Actions should be retry-safe. UI should disable duplicate submits while an action is in flight, but database idempotency remains the final safety control.

## 11. Privacy and Consent

The portal must honor existing consent records and the longitudinal consent-withdrawal policy.

The portal may display optional analytics consent controls later, but any withdrawal flow must append a new consent record rather than mutate history and must trigger the governed learning reconciliation path through a trusted Edge Function.

No aggregate-learning contributor identity, cohort membership, or internal analytics eligibility state is displayed to the golfer.

## 12. Mobile and Accessibility

The portal is mobile-first because buyers guides and golfer workflows will commonly be used on phones.

Minimum requirements:

- no horizontal scrolling at supported widths;
- touch targets at least 44x44 CSS pixels where practical;
- keyboard-operable controls;
- visible focus states;
- semantic headings and landmarks;
- ARIA only where native HTML semantics are insufficient;
- sufficient color contrast using locked GAL brand colors;
- insight status not communicated by color alone;
- loading/error states announced appropriately to assistive technology.

## 13. Security Requirements

The implementation is unacceptable if any of the following are true:

- service-role key appears in browser-delivered code or repository client configuration;
- authenticated browser can execute service-only longitudinal RPCs directly;
- browser can read internal learning/governance/event tables;
- Edge Function trusts browser-supplied `user_id` for authorization;
- one authenticated golfer can read or mutate another golfer's insight data;
- subscriber entitlement logic bypasses RLS;
- generic Edge Function forwards arbitrary RPC/table requests.

## 14. Testing Strategy

### 14.1 Unit/component tests

Test:

- feed sorting and state presentation;
- response control availability by lifecycle state;
- entitlement-gated rendering;
- error and loading states;
- mobile interaction behavior.

### 14.2 Edge Function tests

For every mutation function verify:

- unauthenticated request rejected;
- wrong-owner insight rejected;
- supported action succeeds;
- unsupported payload rejected;
- duplicate/replayed event is safe;
- safe error shape returned;
- service-only RPC never exposed as a generic passthrough.

### 14.3 RLS/security tests

Using two synthetic users in staging:

- User A can read User A golfer-safe rows.
- User A cannot read User B golfer-safe rows.
- User A cannot select internal tables.
- User A cannot execute service-only RPCs directly.
- Edge Function can mutate only the authenticated user's valid target insight.

### 14.4 End-to-end staging acceptance

Required acceptance journey:

1. create two synthetic authenticated golfers;
2. seed/govern one actionable insight for User A;
3. User A signs in and sees the insight;
4. User B does not see it;
5. presentation event is recorded once;
6. immediate cross-surface repeat respects cooldown;
7. User A acknowledges or acts;
8. portal state updates correctly;
9. qualifying trusted outcome can progress resolution when rule requirements are met;
10. logout/session-expiry returns to authenticated entry state;
11. registered-user and staging-subscriber render from the same components and data contract;
12. no production data is used.

## 15. Deployment Model

Environments:

- local/development: development credentials only;
- staging: `GAL Longitudinal Staging` Supabase project plus preview/staging frontend deployment;
- production: production Supabase project plus reviewed production frontend deployment.

Production promotion requires:

1. tests passing against staging;
2. portal security/RLS acceptance passing;
3. manual mobile/desktop UX review;
4. synchronized registered-user/subscriber portal verification;
5. no unresolved high-severity release blocker;
6. reviewed Git PR merged to `main`;
7. production smoke test after deployment.

The existing leaked-password-protection warning remains a separate registered-golfer launch blocker until the Supabase plan supports that control and it is enabled.

## 16. First Implementation Slice

The first implementation slice deliberately excludes broader account/profile redesign and future advanced personalization.

Deliver:

1. `/portal/` authenticated SPA shell;
2. Supabase client/session integration using publishable credentials only;
3. shared insight feed;
4. insight detail view;
5. acknowledge/dismiss/snooze/action controls;
6. five narrow Supabase Edge Functions forming the trusted mutation boundary;
7. shared entitlement interface with base registered-user behavior and staging-only subscriber fixture;
8. staging fixtures and two-user isolation tests;
9. responsive/mobile accessibility baseline;
10. staging deployment and acceptance checklist.

## 17. Out of Scope for This Slice

Do not include yet:

- public-site framework rewrite;
- native mobile app;
- payment/subscription checkout implementation;
- production subscriber billing/entitlement source integration;
- email/push notification delivery engine;
- externally published Equipment Migration Intelligence;
- automatic learning-candidate promotion;
- arbitrary AI chat assistant inside the portal;
- full My Bag/profile redesign;
- wholesale extraction of legacy PR #3 features.

These may be layered onto the shared portal architecture in later reviewed increments.

## 18. Success Criteria

The design is successful when:

- a registered golfer can securely sign in and view only their governed insights;
- a staging subscriber uses the same portal components and contract with entitlement-driven enhancements;
- golfer responses are recorded only through the trusted Edge Function boundary;
- no service-role secret or service-only RPC is exposed to the browser;
- insight delivery, response, outcome, and resolution state remain consistent with the production longitudinal model;
- cross-user isolation is demonstrated with synthetic staging users;
- mobile and desktop experiences pass the staging acceptance checklist;
- public static-site functionality remains unchanged unless explicitly integrated with authenticated entry points.
