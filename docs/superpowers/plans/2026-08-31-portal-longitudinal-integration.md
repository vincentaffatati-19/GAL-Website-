# GAL Authenticated Portal Longitudinal Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first authenticated GAL portal release at `/portal/`, showing each golfer only their governed longitudinal insights and sending all longitudinal mutations through narrow Supabase Edge Functions.

**Architecture:** Preserve the existing flat public website. Add a Vite + TypeScript single-page application under `portal/` that uses Supabase Auth and RLS-protected browser reads with the publishable key only. Implement one shared authenticated mutation Edge Function with an internal action router that exposes only named portal actions and calls the existing service-only longitudinal RPCs; keep the service-role key only in the Edge Function runtime. Registered-user and subscriber experiences share the same components and data contract, with an entitlement resolver controlling additive subscriber UI.

**Tech Stack:** Vite, TypeScript, `@supabase/supabase-js`, Vitest, Testing Library DOM, Playwright, Supabase Edge Functions/Deno, existing PostgreSQL/RLS/RPC contract.

**Spec:** `docs/superpowers/specs/2026-08-31-portal-longitudinal-integration-design.md`

## Global Constraints

- Preserve the existing public flat-file website; do not migrate the public site to a framework.
- Portal route is `/portal/`.
- Browser receives only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
- `SUPABASE_SERVICE_ROLE_KEY` must never be included in browser code, built assets, or committed configuration.
- Golfer-safe reads rely on production RLS and `gal_current_user_id()`; JavaScript filtering is presentation-only.
- Longitudinal mutations must use narrow Supabase Edge Function actions; never add a generic table/RPC proxy.
- Server authorization must derive the golfer from the authenticated Supabase access token and must ignore/reject browser-supplied `user_id` authority.
- Registered-user and subscriber portal states use the same components and contracts.
- Subscriber behavior uses staging/test entitlements until a production billing/entitlement source is explicitly integrated.
- Staging verification is mandatory before production release.
- Do not copy production golfer data into development or staging unless explicitly anonymized/sanitized.
- Keep GAL branding on the locked Option 7 system: Navy `#0B245F`, Orange `#FF5A1F`, white/light gray, current header/footer treatment.
- Existing Supabase leaked-password-protection warning remains a separate launch blocker until the plan tier supports it.

---

## File Structure

Create a focused portal package rather than adding authenticated logic to root static pages.

```text
portal/
  index.html                         # SPA entry document, GAL shell mount point
  package.json                       # portal-only build/test dependencies and scripts
  tsconfig.json
  vite.config.ts                     # base: /portal/
  src/
    main.ts                          # app bootstrap only
    config.ts                        # validated public Supabase runtime config
    supabase.ts                      # browser Supabase client singleton
    auth.ts                          # session load, auth-state observer, sign-in/out helpers
    types.ts                         # normalized golfer-safe portal domain types
    data/
      insights.ts                    # RLS-protected read queries + presentation model assembly
      entitlements.ts                # shared base/subscriber entitlement resolver
    api/
      insightActions.ts              # typed client wrapper for Edge Function actions
    ui/
      appShell.ts                    # authenticated/unauthenticated shell renderer
      insightFeed.ts                 # feed renderer and sorting
      insightDetail.ts               # detail renderer
      insightActions.ts              # acknowledge/dismiss/snooze/action controls
      status.ts                      # lifecycle/resolution labels and accessibility text
      states.ts                      # loading/empty/error/session-expired views
    styles/
      portal.css                     # GAL-branded responsive portal styles
    __tests__/
      auth.test.ts
      insights.test.ts
      entitlements.test.ts
      insightActions.test.ts
      ui.test.ts
  e2e/
    portal.spec.ts                   # browser staging acceptance scenarios
  playwright.config.ts

supabase/functions/portal-insight-action/
  index.ts                           # HTTP/auth boundary + action dispatch only
  auth.ts                            # access-token -> auth user -> active gal_users resolver
  actions.ts                         # allowlisted action handlers
  errors.ts                          # safe error normalization
  types.ts                           # request/response action contracts
  index.test.ts                      # Deno tests for auth/action routing

supabase/tests/
  portal_rls_acceptance.sql          # two-user RLS and direct-RPC denial test

docs/data/longitudinal/
  portal-staging-acceptance.md       # executable release checklist and expected evidence

index.html and selected public pages # add only a portal/sign-in entry link after portal staging passes
```

---

### Task 1: Portal Build Skeleton and Public Runtime Configuration

**Files:**
- Create: `portal/package.json`
- Create: `portal/tsconfig.json`
- Create: `portal/vite.config.ts`
- Create: `portal/index.html`
- Create: `portal/src/config.ts`
- Create: `portal/src/main.ts`
- Create: `portal/src/styles/portal.css`
- Test: `portal/src/__tests__/config.test.ts`

**Interfaces:**
- Produces: `getPortalConfig(): { supabaseUrl: string; supabasePublishableKey: string }`
- Produces: Vite build output rooted at `/portal/`.

- [ ] **Step 1: Write the failing runtime-config tests**

```ts
import { describe, expect, it, vi } from 'vitest';
import { getPortalConfig } from '../config';

describe('getPortalConfig', () => {
  it('returns only public Supabase settings', () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://example.supabase.co');
    vi.stubEnv('VITE_SUPABASE_PUBLISHABLE_KEY', 'publishable');
    expect(getPortalConfig()).toEqual({
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'publishable',
    });
  });

  it('fails closed when configuration is missing', () => {
    vi.stubEnv('VITE_SUPABASE_URL', '');
    vi.stubEnv('VITE_SUPABASE_PUBLISHABLE_KEY', '');
    expect(() => getPortalConfig()).toThrow('Portal Supabase configuration is incomplete');
  });
});
```

- [ ] **Step 2: Run the test and verify failure**

Run: `cd portal && npm test -- --run src/__tests__/config.test.ts`

Expected: FAIL because `../config` does not exist.

- [ ] **Step 3: Add the portal package and minimal config implementation**

`portal/package.json` must include scripts:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "test": "vitest",
    "test:run": "vitest run",
    "e2e": "playwright test"
  }
}
```

Use dependencies `@supabase/supabase-js` and dev dependencies `vite`, `typescript`, `vitest`, `@testing-library/dom`, `jsdom`, `@playwright/test`.

`portal/src/config.ts`:

```ts
export type PortalConfig = {
  supabaseUrl: string;
  supabasePublishableKey: string;
};

export function getPortalConfig(): PortalConfig {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL?.trim();
  const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.trim();
  if (!supabaseUrl || !supabasePublishableKey) {
    throw new Error('Portal Supabase configuration is incomplete');
  }
  return { supabaseUrl, supabasePublishableKey };
}
```

Set `base: '/portal/'` in `vite.config.ts`.

- [ ] **Step 4: Add initial GAL shell HTML/CSS**

`portal/index.html` must contain a single `#app` mount, GAL logo alt text, viewport meta, and no inline secrets. `portal.css` should define brand CSS variables using the locked values and responsive shell primitives only; no feature-specific styling yet.

- [ ] **Step 5: Run config tests and production build**

Run:

```bash
cd portal
npm test -- --run src/__tests__/config.test.ts
npm run build
```

Expected: tests PASS and Vite emits a `/portal/` build without service-role strings.

- [ ] **Step 6: Commit**

```bash
git add portal
 git commit -m "feat(portal): scaffold authenticated portal build"
```

---

### Task 2: Supabase Browser Client and Authentication State

**Files:**
- Create: `portal/src/supabase.ts`
- Create: `portal/src/auth.ts`
- Modify: `portal/src/main.ts`
- Test: `portal/src/__tests__/auth.test.ts`

**Interfaces:**
- Produces: `getSupabaseClient(): SupabaseClient`
- Produces: `getCurrentSession(): Promise<Session | null>`
- Produces: `signInWithPassword(email: string, password: string): Promise<void>`
- Produces: `signOut(): Promise<void>`
- Produces: `subscribeToAuth(callback: (session: Session | null) => void): () => void`

- [ ] **Step 1: Write failing auth tests using a mocked Supabase client**

Verify session load, successful sign-in, sign-out, and auth subscription cleanup. Explicitly assert no helper accepts a `user_id` parameter.

- [ ] **Step 2: Run the tests and verify failure**

Run: `cd portal && npm test -- --run src/__tests__/auth.test.ts`

Expected: FAIL because auth helpers do not exist.

- [ ] **Step 3: Implement the singleton client**

```ts
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { getPortalConfig } from './config';

let client: SupabaseClient | undefined;

export function getSupabaseClient(): SupabaseClient {
  if (!client) {
    const config = getPortalConfig();
    client = createClient(config.supabaseUrl, config.supabasePublishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
    });
  }
  return client;
}
```

- [ ] **Step 4: Implement auth helpers around Supabase Auth only**

Return normalized errors to the UI, but do not map auth users to GAL users in browser code.

- [ ] **Step 5: Run tests**

Run: `cd portal && npm test -- --run src/__tests__/auth.test.ts`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add portal/src/supabase.ts portal/src/auth.ts portal/src/main.ts portal/src/__tests__/auth.test.ts
 git commit -m "feat(portal): add Supabase authentication state"
```

---

### Task 3: Golfer-Safe Longitudinal Read Model

**Files:**
- Create: `portal/src/types.ts`
- Create: `portal/src/data/insights.ts`
- Test: `portal/src/__tests__/insights.test.ts`

**Interfaces:**
- Produces type `PortalInsight` with fields:

```ts
export type PortalInsight = {
  insightId: string;
  domain: string;
  code: string;
  headline: string;
  message: string;
  severity: 'INFO' | 'MATERIAL' | 'HIGH';
  insightStatus: string;
  deliveryStatus: string | null;
  resolutionStatus: 'OPEN' | 'EVIDENCE_PENDING' | 'RESOLVED' | 'INEFFECTIVE' | 'REGRESSED' | null;
  updatedAt: string;
};
```

- Produces: `loadPortalInsights(): Promise<PortalInsight[]>`

- [ ] **Step 1: Write failing read-model tests**

Mock `.from()` calls and assert the browser reads only these golfer-safe relations: `gal_insights`, `gal_insight_delivery_state`, `gal_insight_resolution_state`. Do not query raw signals, exposure events, learning tables, governance actors, or resolution events.

- [ ] **Step 2: Verify test failure**

Run: `cd portal && npm test -- --run src/__tests__/insights.test.ts`

Expected: FAIL because the reader is missing.

- [ ] **Step 3: Implement the minimal RLS-protected reader**

Do not pass a user ID filter from the browser. Query golfer-safe data under the authenticated session and merge by `insight_id` locally.

The `gal_insights` select must request only golfer-facing fields required by the UI, including `insight_id`, `insight_domain`, `insight_code`, `headline`, `golfer_message`, `severity`, `status`, `updated_at`.

- [ ] **Step 4: Implement sorting**

Sort ACTIVE/ACKNOWLEDGED before RESOLVED/SUPPRESSED/EXPIRED; within state groups sort HIGH before MATERIAL before INFO, then newest `updatedAt` first.

- [ ] **Step 5: Run tests**

Run: `cd portal && npm test -- --run src/__tests__/insights.test.ts`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add portal/src/types.ts portal/src/data/insights.ts portal/src/__tests__/insights.test.ts
 git commit -m "feat(portal): add governed insight read model"
```

---

### Task 4: Shared Registered-User and Subscriber Entitlement Resolver

**Files:**
- Create: `portal/src/data/entitlements.ts`
- Test: `portal/src/__tests__/entitlements.test.ts`

**Interfaces:**
- Produces:

```ts
export type PortalEntitlements = {
  tier: 'REGISTERED' | 'SUBSCRIBER';
  advancedHistory: boolean;
  enhancedExplanation: boolean;
};

export function resolveEntitlements(claims: Record<string, unknown>): PortalEntitlements;
```

- [ ] **Step 1: Write failing tests**

Base behavior must always resolve safely to REGISTERED. Staging/test claims containing `gal_portal_tier: 'SUBSCRIBER'` enable additive UI flags. Unknown or malformed claims must never expand access.

- [ ] **Step 2: Run tests and verify failure**

Run: `cd portal && npm test -- --run src/__tests__/entitlements.test.ts`

- [ ] **Step 3: Implement the resolver**

```ts
export function resolveEntitlements(claims: Record<string, unknown>): PortalEntitlements {
  const subscriber = claims.gal_portal_tier === 'SUBSCRIBER';
  return {
    tier: subscriber ? 'SUBSCRIBER' : 'REGISTERED',
    advancedHistory: subscriber,
    enhancedExplanation: subscriber,
  };
}
```

Document in code that these claims are staging/test fixtures until a governed production entitlement source is connected; they affect UI capability only, never RLS.

- [ ] **Step 4: Run tests and commit**

```bash
cd portal && npm test -- --run src/__tests__/entitlements.test.ts
git add src/data/entitlements.ts src/__tests__/entitlements.test.ts
git commit -m "feat(portal): add shared entitlement resolver"
```

---

### Task 5: Edge Function Authentication and Safe Action Contract

**Files:**
- Create: `supabase/functions/portal-insight-action/types.ts`
- Create: `supabase/functions/portal-insight-action/errors.ts`
- Create: `supabase/functions/portal-insight-action/auth.ts`
- Create: `supabase/functions/portal-insight-action/index.test.ts`

**Interfaces:**
- Consumes: `Authorization: Bearer <access_token>`
- Produces `resolvePortalActor(req: Request): Promise<{ authUserId: string; galUserId: string }>`
- Produces action union:

```ts
export type PortalInsightAction =
  | { action: 'present'; insightId: string; surface: 'portal' }
  | { action: 'acknowledge'; insightId: string; surface: 'portal' }
  | { action: 'dismiss'; insightId: string; surface: 'portal' }
  | { action: 'snooze'; insightId: string; surface: 'portal'; snoozedUntil: string }
  | { action: 'act'; insightId: string; surface: 'portal' };
```

- [ ] **Step 1: Write failing Deno tests for auth boundary**

Tests must prove: missing Authorization => 401; invalid token => 401; mapped active user => resolved GAL user; caller-supplied `user_id` is rejected from payload parsing.

- [ ] **Step 2: Run tests and verify failure**

Run: `deno test supabase/functions/portal-insight-action/index.test.ts --allow-env`

- [ ] **Step 3: Implement separate user-token and service-role clients**

`auth.ts` must validate the access token using a Supabase client scoped to the bearer token, obtain `auth.users.id`, then use the service client to query exactly one active `gal_users` row by `auth_user_id`.

Never return the service client to browser-facing code.

- [ ] **Step 4: Add safe error normalization**

Define only these external codes initially: `UNAUTHENTICATED`, `ACCOUNT_NOT_READY`, `NOT_FOUND`, `NOT_ALLOWED`, `STALE_ACTION`, `TEMPORARY_FAILURE`.

- [ ] **Step 5: Run Deno tests and commit**

```bash
deno test supabase/functions/portal-insight-action/index.test.ts --allow-env
git add supabase/functions/portal-insight-action
git commit -m "feat(portal-api): add authenticated mutation boundary"
```

---

### Task 6: Allowlisted Longitudinal Mutation Handlers

**Files:**
- Create: `supabase/functions/portal-insight-action/actions.ts`
- Create: `supabase/functions/portal-insight-action/index.ts`
- Modify: `supabase/functions/portal-insight-action/index.test.ts`

**Interfaces:**
- Produces: `handlePortalInsightAction(actor, payload)`
- Calls only: `gal_record_insight_presentation` and `gal_record_insight_response` for this first slice.
- Does not expose generic outcome, resolution, learning, governance, or arbitrary-RPC invocation to the browser.

- [ ] **Step 1: Add failing tests for all five allowlisted actions**

For each action assert the exact RPC invoked and exact server-derived `p_user_id`. Add negative tests for unknown action, wrong-owner insight, malformed snooze timestamp, and client `user_id` field.

- [ ] **Step 2: Run tests to verify failure**

Run: `deno test supabase/functions/portal-insight-action/index.test.ts --allow-env`

- [ ] **Step 3: Implement ownership verification**

Before any mutation, service client must fetch `gal_insights.id` where `insight_id = payload.insightId` and `user_id = actor.galUserId`. Missing row returns `NOT_FOUND` without revealing whether another golfer owns the insight ID.

- [ ] **Step 4: Implement action-to-RPC mapping**

Mapping:

```text
present     -> gal_record_insight_presentation(surface='portal')
acknowledge -> gal_record_insight_response(response_type='ACKNOWLEDGED')
dismiss     -> gal_record_insight_response(response_type='DISMISSED')
snooze      -> gal_record_insight_response(response_type='SNOOZED', snoozed_until validated future timestamp)
act         -> gal_record_insight_response(response_type='ACTED')
```

Generate `source_event_key` server-side using action + insight + crypto UUID. Use `source_system = 'gal_portal'`.

- [ ] **Step 5: Ensure trusted outcomes/resolution are not browser actions**

Add tests that `outcome`, `resolve`, `regress`, `publish_learning`, `promote`, and arbitrary `rpc` action names return 400 `NOT_ALLOWED`.

- [ ] **Step 6: Run Deno tests and commit**

```bash
deno test supabase/functions/portal-insight-action/index.test.ts --allow-env
git add supabase/functions/portal-insight-action
git commit -m "feat(portal-api): add allowlisted insight actions"
```

---

### Task 7: Browser Mutation Client

**Files:**
- Create: `portal/src/api/insightActions.ts`
- Test: `portal/src/__tests__/insightActions.test.ts`

**Interfaces:**
- Produces functions:

```ts
presentInsight(insightId: string): Promise<ActionResult>
acknowledgeInsight(insightId: string): Promise<ActionResult>
dismissInsight(insightId: string): Promise<ActionResult>
snoozeInsight(insightId: string, snoozedUntil: string): Promise<ActionResult>
actOnInsight(insightId: string): Promise<ActionResult>
```

- [ ] **Step 1: Write failing tests**

Assert calls go only through `supabase.functions.invoke('portal-insight-action', { body })`; assert no function accepts or adds `user_id`, actor IDs, RPC names, rule codes, or table names.

- [ ] **Step 2: Run tests to verify failure**

Run: `cd portal && npm test -- --run src/__tests__/insightActions.test.ts`

- [ ] **Step 3: Implement typed wrappers**

Normalize Edge Function error codes into a stable `ActionResult` discriminated union; never surface raw PostgreSQL/schema errors.

- [ ] **Step 4: Run tests and commit**

```bash
cd portal && npm test -- --run src/__tests__/insightActions.test.ts
git add src/api/insightActions.ts src/__tests__/insightActions.test.ts
git commit -m "feat(portal): add typed insight action client"
```

---

### Task 8: Shared Portal Shell, Feed, Detail, and Response Controls

**Files:**
- Create: `portal/src/ui/appShell.ts`
- Create: `portal/src/ui/insightFeed.ts`
- Create: `portal/src/ui/insightDetail.ts`
- Create: `portal/src/ui/insightActions.ts`
- Create: `portal/src/ui/status.ts`
- Create: `portal/src/ui/states.ts`
- Modify: `portal/src/main.ts`
- Modify: `portal/src/styles/portal.css`
- Test: `portal/src/__tests__/ui.test.ts`

**Interfaces:**
- Consumes: `PortalInsight[]`, `PortalEntitlements`, typed mutation functions.
- Produces: one shared registered/subscriber portal UI.

- [ ] **Step 1: Write failing DOM tests**

Cover: unauthenticated sign-in state; loading; empty insights; active insight card; resolved history card; HIGH status text not color-only; subscriber enhancement rendered only with entitlement; Acknowledge/Dismiss/Snooze/Take Action controls; duplicate-submit disabled state; safe error rendering.

- [ ] **Step 2: Run tests and verify failure**

Run: `cd portal && npm test -- --run src/__tests__/ui.test.ts`

- [ ] **Step 3: Implement status semantics**

Use native headings/buttons/details where possible. Resolution labels must include Open, Evidence pending, Resolved, Ineffective, Regressed. Dismissed delivery state must never render as analytically “Resolved.”

- [ ] **Step 4: Implement feed and detail rendering**

Render only golfer-facing fields. Do not render detector source keys, raw evidence JSON, governance actor IDs, learning policy IDs, contributor information, or internal event IDs.

- [ ] **Step 5: Implement action controls**

On successful action, reload `loadPortalInsights()` rather than fabricating local analytical state. `Take Action` records ACTED then routes to a configured GAL workflow URL only when one exists; otherwise show a safe “Action recorded” state without inventing a recommendation destination.

- [ ] **Step 6: Add mobile/accessibility CSS**

Require 44px minimum interactive target height where practical, visible focus outline, no horizontal scrolling at 320px, status icon/text pairing, and locked brand colors.

- [ ] **Step 7: Run tests and production build**

```bash
cd portal
npm test -- --run src/__tests__/ui.test.ts
npm run build
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add portal/src
 git commit -m "feat(portal): build shared longitudinal insight experience"
```

---

### Task 9: Database RLS and Direct-RPC Acceptance Test

**Files:**
- Create: `supabase/tests/portal_rls_acceptance.sql`

**Interfaces:**
- Validates the production/staging schema contract; does not alter schema.

- [ ] **Step 1: Write the SQL test inside a transaction**

Create two synthetic `auth.users` identities and their GAL mappings using staging-safe fixture patterns. Seed one governed insight per user. Use `set local role authenticated` plus JWT claims to prove:

1. User A reads only User A `gal_insights`.
2. User A reads only User A delivery/response/outcome/resolution state.
3. User A reads zero rows from internal-only tables.
4. User A cannot execute `gal_record_insight_presentation`, `gal_record_insight_response`, `gal_record_insight_outcome`, or learning-governance service RPCs directly.
5. User B cannot discover User A insight rows.

End with `rollback;`.

- [ ] **Step 2: Run against GAL Longitudinal Staging**

Expected: every assertion passes and synthetic counts return to baseline after rollback.

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/portal_rls_acceptance.sql
git commit -m "test(portal): prove golfer isolation and RPC denial"
```

---

### Task 10: Deploy Edge Function and Portal to Staging

**Files:**
- Create: `docs/data/longitudinal/portal-staging-acceptance.md`
- Create: `portal/playwright.config.ts`
- Create: `portal/e2e/portal.spec.ts`

**Interfaces:**
- Consumes staging Supabase project `GAL Longitudinal Staging` only.
- Produces repeatable staging evidence for the release gate.

- [ ] **Step 1: Write the acceptance checklist before deployment**

Checklist must record environment, Git commit, Edge Function version, portal build version, two synthetic user IDs/public IDs, and PASS/FAIL evidence for every scenario below.

- [ ] **Step 2: Add Playwright tests**

Use staging-only synthetic credentials supplied through CI/runtime secrets. Scenarios:

```text
A signs in -> sees A insight
B signs in -> does not see A insight
A presentation -> accepted once
A duplicate/replay -> safe
A acknowledge -> portal refresh reflects new state
A snooze -> delivery state reflects cooldown
A dismiss -> delivery changes without resolution claim
subscriber fixture -> same feed components plus entitlement enhancement
logout -> protected portal returns to sign-in state
320px viewport -> no horizontal overflow
keyboard -> all action controls reachable and visibly focused
```

- [ ] **Step 3: Deploy Edge Function to staging**

Set staging secrets only in Supabase function secret storage: project URL, publishable/anon verification settings as required by Supabase runtime, and service-role key. Do not commit any secret values.

- [ ] **Step 4: Deploy portal preview/staging build**

Build with staging `VITE_SUPABASE_URL` and staging publishable key. Verify built JS contains no service-role secret name/value and no production Supabase project URL.

- [ ] **Step 5: Run SQL acceptance + unit tests + Playwright**

```bash
cd portal && npm run test:run && npm run build && npm run e2e
```

Also run `supabase/tests/portal_rls_acceptance.sql` against staging.

Expected: all PASS.

- [ ] **Step 6: Manual synchronized registered/subscriber review**

Using the same portal build, verify registered and subscriber fixture experiences share navigation, card structure, action behavior, mobile layout, and error handling. Subscriber-only differences must be additive and entitlement-driven.

- [ ] **Step 7: Commit acceptance artifacts**

Do not commit passwords, tokens, user emails, or secret values. Commit only sanitized IDs/results/checklist evidence.

```bash
git add portal/e2e portal/playwright.config.ts docs/data/longitudinal/portal-staging-acceptance.md
git commit -m "test(portal): add staging acceptance gate"
```

---

### Task 11: Public-Site Portal Entry Points

**Files:**
- Modify: `index.html`
- Modify: `assets__styles.css` only if required for existing shared nav styling
- Test: manual/static link validation plus portal E2E navigation assertion

**Interfaces:**
- Produces: public-site navigation into `/portal/` only after staging portal is GREEN.

- [ ] **Step 1: Add a failing Playwright assertion for public-site entry**

From staged home page, clicking the account/portal entry must navigate to `/portal/` and render sign-in or authenticated portal shell.

- [ ] **Step 2: Verify failure before adding the link**

Run the specific Playwright test; expected FAIL because no portal entry exists.

- [ ] **Step 3: Add one consistent portal entry point**

Use existing GAL header/nav conventions. Do not duplicate separate “user portal” and “subscriber portal” links; both go to the same `/portal/` application.

- [ ] **Step 4: Run static-site smoke checks and Playwright**

Verify existing Buyers Guides, Build a Better Bag navigation, footer/legal links, and public pages remain functional.

- [ ] **Step 5: Commit**

```bash
git add index.html assets__styles.css portal/e2e/portal.spec.ts
git commit -m "feat(site): add shared authenticated portal entry"
```

---

### Task 12: Release Review and Production Promotion Gate

**Files:**
- Modify: `docs/data/longitudinal/portal-staging-acceptance.md`
- Modify: `VERSION.txt` only when the portal RC is approved for production.

**Interfaces:**
- Produces: production promotion decision; no automatic production deployment.

- [ ] **Step 1: Run complete verification from a clean checkout/worktree**

Run portal unit tests, portal build, Deno Edge Function tests, SQL RLS acceptance against staging, and Playwright staging acceptance.

- [ ] **Step 2: Security review built artifacts**

Search generated portal assets for `service_role`, `SUPABASE_SERVICE_ROLE_KEY`, production secret values, internal table names that the browser must never query, and generic RPC passthrough strings. Any hit requires review before release.

- [ ] **Step 3: Supabase staging advisors**

Run Security and Performance Advisors after Edge Function/database acceptance. No new WARN/ERROR database finding may be introduced. Existing leaked-password-protection warning remains separately tracked.

- [ ] **Step 4: Create release-candidate PR**

PR description must include test evidence, staging URL, sanitized acceptance results, explicit statement that registered/subscriber experiences use shared components, and confirmation that service-role credentials are server-only.

- [ ] **Step 5: Production promotion only after review approval**

Deploy the reviewed portal assets and Edge Function using production runtime secrets. Do not copy staging users/data. Do not alter Tasks 8–13 schema unless a separately reviewed migration is required.

- [ ] **Step 6: Production smoke test with admin-controlled/synthetic account**

Verify sign-in, own-insight read, another-user isolation, one presentation, one response, logout, and public-site navigation. Remove any explicitly persistent synthetic records immediately after smoke verification; prefer rollback/admin-controlled fixtures where possible.

- [ ] **Step 7: Final advisors and release record**

Re-run production Security/Performance Advisors and record results in the release PR/checklist. Do not remove useful indexes based only on pre-launch `unused_index` INFO notices.

- [ ] **Step 8: Commit version/release documentation**

```bash
git add VERSION.txt docs/data/longitudinal/portal-staging-acceptance.md
git commit -m "release(portal): record authenticated portal production candidate"
```

---

## Plan Self-Review Results

- **Spec coverage:** Authentication, RLS reads, trusted mutation boundary, insight feed/detail/actions, resolution semantics, shared entitlements, privacy, mobile/accessibility, two-user isolation, staging gate, synchronized registered/subscriber verification, and public-site preservation all map to explicit tasks.
- **Scope:** The plan intentionally excludes payment checkout, notification delivery, My Bag redesign, generic AI chat, external Equipment Migration Intelligence, and legacy PR #3 extraction.
- **Security boundary:** No task grants browser execution of service-only RPCs; browser mutation API is allowlisted and derives user identity server-side.
- **Type consistency:** Portal action names and `PortalInsight`/`PortalEntitlements` contracts are defined once and consumed consistently by later tasks.
- **Placeholder scan:** No TBD/TODO/“implement later” placeholders are part of execution instructions.
