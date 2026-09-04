# GAL Consumer Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect My GAL, My Bag, Buyers Guides, and GAL AI Fitting to one governed Equipment Knowledge consumer layer, activate Driver as the first full vertical slice, and preserve the future privacy-safe B2B Industry Intelligence monetization path.

**Architecture:** Reconcile the existing My GAL shell onto the current integration branch, then add one browser-safe Supabase client, one shared equipment read model, and one category-adapter registry for all seven equipment categories. Driver is the only initially active fitter. Consumer surfaces share the same governed read contracts; commercial-data participation is explicit opt-in and contributes only through the existing privacy-safe aggregate-learning boundary.

**Tech Stack:** Vite, TypeScript, browser Supabase client, PostgreSQL/Supabase migrations and RPCs, existing GAL longitudinal privacy/consent tables, Vitest, SQL acceptance tests, GitHub Actions, Vercel preview/staging.

**Spec:** `docs/superpowers/specs/2026-09-03-gal-consumer-integration-design.md`

## Global Constraints

- Production deployment and production Supabase migration are NOT authorized by this plan.
- Exact approved GAL Motion Arc brand asset only; do not recreate or approximate the logo.
- Browser configuration is limited to `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`; no service-role material may enter browser code.
- Public Buyers Guides use `public.gal_public_equipment_guide()`; authenticated fitting uses `public.gal_authenticated_equipment_ai_fit()`.
- My Bag, Guides, Today, Insights, Progress, and AI Fitting must not maintain independent equipment-product truth or direct equipment-knowledge query paths.
- Characteristics Before Brands is mandatory: `Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`.
- Unknown is not good fit; missing critical evidence narrows or blocks recommendations.
- `AI_FIT_LIMITED` must remain distinct from `AI_FIT_READY`.
- Unknown compatibility is not compatible; only governed eligible configurations may become fitting candidates.
- Registered and subscriber users use the same components and contracts; entitlements add capability but never alter equipment truth or ranking.
- Commercial aggregate-data participation is explicit opt-in, separate from ordinary product-use consent.
- Industry customers never receive direct access to identifiable golfer operational data.
- Existing minimum-cohort aggregate-learning governance remains the privacy floor; future B2B products consume only governed aggregates, reports, or approved exports.

---

## File Structure

Implementation should converge on these responsibilities:

- `portal/src/supabase/client.ts` — browser-safe Supabase client singleton.
- `portal/src/auth/session.ts` — authenticated-session resolution only.
- `portal/src/equipment/types.ts` — stable consumer equipment types.
- `portal/src/equipment/categories.ts` — seven-category registry and activation flags.
- `portal/src/equipment/normalize.ts` — governed RPC row -> consumer read model transformation.
- `portal/src/equipment/client.ts` — sole browser equipment read boundary.
- `portal/src/equipment/state.ts` — explicit ready/limited/missing/stale/error state mapping.
- `portal/src/bag/*` — My Bag consumer presentation; no independent fitting logic.
- `portal/src/fitting/driver/*` — Driver-only active fitting workflow.
- `portal/src/guides/*` — public/logged-in guide integration using shared model.
- `portal/src/surfaces/*` — Today, Insights, Progress views consuming shared state.
- `portal/src/privacy/commercialConsent.ts` — explicit commercial aggregate-data opt-in UI/data boundary.
- `supabase/migrations/<timestamp>_consumer_commercial_consent.sql` — extend existing append-only consent model for commercial aggregate participation.
- `supabase/tests/consumer_commercial_consent.sql` — consent/RLS/withdrawal eligibility acceptance.
- `portal/src/__tests__/*` — unit tests for auth, normalization, categories, state, and surfaces.
- `.github/workflows/my-gal-portal-ci.yml` — portal tests/build/service-role scan.

---

### Task 1: Reconcile the My GAL Shell onto Current `portal-integration-plan`

**Files:**
- Reconcile from PR #25: `.github/workflows/my-gal-portal-ci.yml`
- Reconcile from PR #25: `portal/index.html`
- Reconcile from PR #25: `portal/package.json`
- Reconcile from PR #25: `portal/public/gal-option7a-motion.jpg`
- Reconcile from PR #25: `portal/src/branding.ts`
- Reconcile from PR #25: `portal/src/config.ts`
- Reconcile from PR #25: `portal/src/main.ts`
- Reconcile from PR #25: `portal/src/router.ts`
- Reconcile from PR #25: `portal/src/styles/portal.css`
- Reconcile tests: `portal/src/__tests__/branding.test.ts`, `config.test.ts`, `router.test.ts`

**Interfaces:**
- Produces `resolvePortalRoute(pathname: string): PortalRoute`.
- Produces `getPortalConfig(): { supabaseUrl: string; supabasePublishableKey: string }`.
- Preserves routes `today | bag | insights | guides | progress`.

- [ ] **Step 1: Branch from current integration head**

Create the implementation branch from current `portal-integration-plan` head, not from PR #25:

```bash
git switch portal-integration-plan
git pull --ff-only
git switch -c consumer-integration-implementation
```

- [ ] **Step 2: Reapply the PR #25 shell files without merging the stale branch wholesale**

Preserve the existing router contract:

```ts
export type PortalRoute = 'today' | 'bag' | 'insights' | 'guides' | 'progress';

export function resolvePortalRoute(pathname: string): PortalRoute {
  const normalized = pathname.replace(/\/+$/, '');
  const segment = normalized.split('/').filter(Boolean)[1]?.toLowerCase() as PortalRoute | undefined;
  return segment && new Set<PortalRoute>(['today', 'bag', 'insights', 'guides', 'progress']).has(segment)
    ? segment
    : 'today';
}
```

- [ ] **Step 3: Run shell tests and build**

```bash
cd portal
npm ci
npm test -- --run
npm run build
```

Expected: branding/config/router tests pass; Vite build succeeds under `/portal/`.

- [ ] **Step 4: Verify browser bundle contains no service-role material**

```bash
grep -RniE 'service[_-]?role|SUPABASE_SERVICE_ROLE|service_role' dist && exit 1 || true
```

Expected: no matches.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/my-gal-portal-ci.yml portal
git commit -m "feat: reconcile My GAL shell onto consumer integration"
```

---

### Task 2: Add the Browser Supabase Client and Session Boundary

**Files:**
- Create: `portal/src/supabase/client.ts`
- Create: `portal/src/auth/session.ts`
- Create: `portal/src/__tests__/supabaseClient.test.ts`
- Create: `portal/src/__tests__/session.test.ts`
- Modify: `portal/package.json`

**Interfaces:**
- Produces `getSupabaseClient(): SupabaseClient`.
- Produces `getCurrentSession(): Promise<Session | null>`.
- Consumes `getPortalConfig()` from Task 1.

- [ ] **Step 1: Write failing client tests**

```ts
import { describe, expect, it, vi } from 'vitest';

describe('browser Supabase boundary', () => {
  it('does not expose service-role configuration', async () => {
    const mod = await import('../supabase/client');
    expect(JSON.stringify(mod)).not.toMatch(/service[_-]?role/i);
  });
});
```

- [ ] **Step 2: Run the focused tests and confirm failure**

```bash
npm test -- --run src/__tests__/supabaseClient.test.ts src/__tests__/session.test.ts
```

Expected: FAIL because the modules do not yet exist.

- [ ] **Step 3: Add `@supabase/supabase-js` and implement the singleton**

```ts
// portal/src/supabase/client.ts
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { getPortalConfig } from '../config';

let client: SupabaseClient | undefined;

export function getSupabaseClient(): SupabaseClient {
  if (!client) {
    const { supabaseUrl, supabasePublishableKey } = getPortalConfig();
    client = createClient(supabaseUrl, supabasePublishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
    });
  }
  return client;
}
```

```ts
// portal/src/auth/session.ts
import type { Session } from '@supabase/supabase-js';
import { getSupabaseClient } from '../supabase/client';

export async function getCurrentSession(): Promise<Session | null> {
  const { data, error } = await getSupabaseClient().auth.getSession();
  if (error) throw error;
  return data.session;
}
```

- [ ] **Step 4: Run unit tests and build**

```bash
npm test -- --run
npm run build
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add portal/package.json portal/package-lock.json portal/src/supabase portal/src/auth portal/src/__tests__
git commit -m "feat: add browser Supabase and session boundary"
```

---

### Task 3: Define the Shared Equipment Read Model and Seven-Category Registry

**Files:**
- Create: `portal/src/equipment/types.ts`
- Create: `portal/src/equipment/categories.ts`
- Create: `portal/src/equipment/normalize.ts`
- Create: `portal/src/equipment/state.ts`
- Create: `portal/src/__tests__/equipmentTypes.test.ts`
- Create: `portal/src/__tests__/equipmentCategories.test.ts`
- Create: `portal/src/__tests__/equipmentNormalize.test.ts`
- Create: `portal/src/__tests__/equipmentState.test.ts`

**Interfaces:**
- Produces `EquipmentItem`, `EquipmentConfiguration`, `EquipmentOpportunity`, `EquipmentRecommendation`.
- Produces `EquipmentCategory = 'DRIVER' | 'FAIRWAY_WOOD' | 'HYBRID' | 'IRON' | 'WEDGE' | 'PUTTER' | 'GOLF_BALL'`.
- Produces `CATEGORY_REGISTRY` with Driver active and all six other categories inactive.
- Produces `normalizeGuideRows(rows)` and `normalizeAiFitRows(rows)`.

- [ ] **Step 1: Write failing registry/state tests**

```ts
import { CATEGORY_REGISTRY } from '../equipment/categories';

it('declares every GAL equipment category and activates only Driver', () => {
  expect(Object.keys(CATEGORY_REGISTRY)).toHaveLength(7);
  expect(CATEGORY_REGISTRY.DRIVER.active).toBe(true);
  expect(Object.entries(CATEGORY_REGISTRY).filter(([, v]) => v.active).map(([k]) => k)).toEqual(['DRIVER']);
});
```

- [ ] **Step 2: Implement stable types**

```ts
export type EquipmentReadiness = 'GUIDE_READY' | 'AI_FIT_LIMITED' | 'AI_FIT_READY';
export type EquipmentSupportState = 'FACTORY_STANDARD' | 'FACTORY_CUSTOM' | 'AFTERMARKET_VALID';

export interface EquipmentItem {
  familyId: string;
  equipmentFamilyId: string;
  canonicalProductId: string | null;
  canonicalBrandId: string | null;
  category: EquipmentCategory;
  familyName: string;
  lifecycleState: string;
  characteristics: Array<{
    attributeKey: string;
    value: unknown;
    unit: string | null;
    claimState: string;
    methodologyVersion: string | null;
  }>;
}

export interface EquipmentConfiguration {
  configurationId: string;
  equipmentConfigurationId: string;
  configurationKey: string;
  name: string;
  supportState: EquipmentSupportState;
  readiness: 'AI_FIT_LIMITED' | 'AI_FIT_READY';
  limitedEvidence: boolean;
  blockingGapCount: number;
}
```

- [ ] **Step 3: Implement explicit consumer state mapping**

Use a discriminated union rather than booleans:

```ts
export type ConsumerEquipmentState =
  | { kind: 'ready' }
  | { kind: 'limited'; blockingGapCount: number }
  | { kind: 'missing-profile'; fields: string[] }
  | { kind: 'missing-configuration' }
  | { kind: 'stale'; reason: string }
  | { kind: 'compatibility-unresolved' }
  | { kind: 'not-ready'; useCase: 'GUIDE' | 'AI_FIT' }
  | { kind: 'disconnected-source'; source: string }
  | { kind: 'unauthorized' }
  | { kind: 'error'; message: string };
```

- [ ] **Step 4: Implement normalizers using only governed RPC fields**

`normalizeAiFitRows()` must map `approved_characteristics`, `readiness_state`, `blocking_gap_count`, `configuration_id`, `equipment_configuration_id`, `configuration_key`, `configuration_name`, `support_state`, and `limited_evidence`. It must not synthesize a fit score, savings value, confidence score, or recommendation.

- [ ] **Step 5: Run tests**

```bash
npm test -- --run src/__tests__/equipmentTypes.test.ts src/__tests__/equipmentCategories.test.ts src/__tests__/equipmentNormalize.test.ts src/__tests__/equipmentState.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add portal/src/equipment portal/src/__tests__
git commit -m "feat: add shared equipment consumer model"
```

---

### Task 4: Add the Sole Browser Equipment Data Client

**Files:**
- Create: `portal/src/equipment/client.ts`
- Create: `portal/src/__tests__/equipmentClient.test.ts`

**Interfaces:**
- Produces `fetchGuideEquipment(): Promise<EquipmentItem[]>`.
- Produces `fetchAiFitEquipment(): Promise<Array<{ item: EquipmentItem; configuration: EquipmentConfiguration }>>`.
- No component may call the equipment RPCs directly.

- [ ] **Step 1: Write failing RPC-routing tests**

Test that public guide calls `gal_public_equipment_guide` and AI Fit calls `gal_authenticated_equipment_ai_fit`, and that an auth failure maps to `unauthorized` rather than falling back to public product ranking.

- [ ] **Step 2: Implement the shared data boundary**

```ts
export async function fetchGuideEquipment() {
  const { data, error } = await getSupabaseClient().rpc('gal_public_equipment_guide');
  if (error) throw new EquipmentClientError('GUIDE_RPC_FAILED', error.message);
  return normalizeGuideRows(data ?? []);
}

export async function fetchAiFitEquipment() {
  const session = await getCurrentSession();
  if (!session) throw new EquipmentClientError('AUTH_REQUIRED', 'Authenticated fitting requires a signed-in golfer');
  const { data, error } = await getSupabaseClient().rpc('gal_authenticated_equipment_ai_fit');
  if (error) throw new EquipmentClientError('AI_FIT_RPC_FAILED', error.message);
  return normalizeAiFitRows(data ?? []);
}
```

- [ ] **Step 3: Add an architecture guard test**

Scan `portal/src` and fail if either equipment RPC name appears outside `portal/src/equipment/client.ts` and its tests.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run
npm run build
git add portal/src/equipment portal/src/__tests__
git commit -m "feat: add governed equipment browser client"
```

---

### Task 5: Add Explicit Commercial Aggregate-Data Opt-In Groundwork

**Files:**
- Create: `supabase/migrations/<timestamp>_consumer_commercial_consent.sql`
- Create: `supabase/tests/consumer_commercial_consent.sql`
- Create: `portal/src/privacy/commercialConsent.ts`
- Create: `portal/src/__tests__/commercialConsent.test.ts`

**Interfaces:**
- Reuses existing append-only `gal_consent_records` behavior and current-user RLS.
- Introduces consent purpose `COMMERCIAL_AGGREGATE` as separate from ordinary product-use and `ANALYTICS_OPTIONAL` consent.
- Produces `getCommercialAggregateConsent()` and `recordCommercialAggregateConsent(decision)`.
- Does NOT create a B2B dashboard or expose individual golfer records.

- [ ] **Step 1: Write a SQL acceptance test first**

The test must prove:
1. latest `COMMERCIAL_AGGREGATE` decision controls commercial eligibility;
2. `ACCEPTED` and `DECLINED/WITHDRAWN` remain append-only events;
3. authenticated users can only read/insert their own consent records;
4. ordinary product use still works without `COMMERCIAL_AGGREGATE=ACCEPTED`;
5. commercial aggregate eligibility requires BOTH the existing privacy-safe analytics eligibility and latest `COMMERCIAL_AGGREGATE=ACCEPTED`.

- [ ] **Step 2: Extend the existing consent vocabulary in an additive migration**

Do not create a parallel consent table. Preserve existing history and policies. If the purpose is constrained by a CHECK constraint or enum, replace/extend that constraint additively to allow `COMMERCIAL_AGGREGATE` while retaining every existing allowed value.

Create a service/internal eligibility view or function that returns only eligible user IDs for aggregate builders; do not grant browser roles direct select on it.

- [ ] **Step 3: Add the browser preference helper**

```ts
export type CommercialConsentDecision = 'ACCEPTED' | 'DECLINED' | 'WITHDRAWN';

export async function recordCommercialAggregateConsent(decision: CommercialConsentDecision): Promise<void> {
  const session = await getCurrentSession();
  if (!session) throw new Error('Authentication required');
  const { error } = await getSupabaseClient().from('gal_consent_records').insert({
    user_id: session.user.id,
    consent_type: 'COMMERCIAL_AGGREGATE',
    consent_status: decision,
  });
  if (error) throw error;
}
```

During implementation, bind the field names to the actual existing `gal_consent_records` schema before committing; do not alter the append-only model.

- [ ] **Step 4: Run SQL tests in staging and portal unit tests**

Expected: explicit opt-in gates commercial eligibility; withdrawal removes future aggregate eligibility without deleting consent history.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations supabase/tests portal/src/privacy portal/src/__tests__/commercialConsent.test.ts
git commit -m "feat: add commercial aggregate consent boundary"
```

---

### Task 6: Integrate My Bag with Governed Equipment Identity

**Files:**
- Create: `portal/src/bag/model.ts`
- Create: `portal/src/bag/render.ts`
- Create: `portal/src/__tests__/bagModel.test.ts`
- Modify: `portal/src/main.ts`

**Interfaces:**
- Consumes existing golfer-owned `gal_bags` / `gal_bag_items` through an approved golfer-safe read path.
- Uses `gal_bag_items.equipment_configuration_id` as governed configuration identity when present.
- Treats legacy `configuration` JSON as a migration bridge only.
- Produces `BagEquipmentView` with known, missing-configuration, and opportunity-link states.

- [ ] **Step 1: Write tests proving unknown is not good fit**

A bag item with no governed configuration reference must render `Configuration details needed`, not `Good fit` or an inferred configuration.

- [ ] **Step 2: Implement bag projection**

```ts
export interface BagEquipmentView {
  bagItemId: string;
  category: EquipmentCategory;
  equipmentName: string;
  configuration?: EquipmentConfiguration;
  state: 'KNOWN' | 'MISSING_CONFIGURATION';
  fittingHref?: string;
}
```

- [ ] **Step 3: Route `/portal/bag` to the bag renderer**

Keep the shell/nav unchanged; replace only the main-content body for the `bag` route.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/bagModel.test.ts
npm run build
git add portal/src/bag portal/src/main.ts portal/src/__tests__/bagModel.test.ts
git commit -m "feat: connect My Bag to governed equipment identity"
```

---

### Task 7: Implement Driver-Only AI Fitting Vertical Slice

**Files:**
- Create: `portal/src/fitting/driver/model.ts`
- Create: `portal/src/fitting/driver/targets.ts`
- Create: `portal/src/fitting/driver/render.ts`
- Create: `portal/src/fitting/driver/actions.ts`
- Create: `portal/src/__tests__/driverFit.test.ts`
- Modify: `portal/src/main.ts`

**Interfaces:**
- Consumes shared equipment client and Driver category adapter.
- Produces ordered phases: Need -> Target Characteristics -> Candidate Configurations -> Brand/Model -> Commerce.
- Produces peer actions `KEEP | ADJUST | RECONFIGURE | REPLACE` only when supported.
- Must never create candidate rank from affiliate/commercial metadata.

- [ ] **Step 1: Write ordering and trust tests**

Tests must prove:
- target characteristics render before any brand/model section;
- `AI_FIT_LIMITED` displays a limitation banner and blocking-gap count;
- unready/ineligible configurations never render as candidates;
- no `fit score`, `bag health`, or fabricated yardage is created;
- commercial fields cannot alter analytical ordering.

- [ ] **Step 2: Implement a Driver target model separate from product candidates**

```ts
export interface DriverTargetProfile {
  characteristics: Array<{
    key: string;
    direction: 'LOWER' | 'NEUTRAL' | 'HIGHER' | 'MATCH';
    rationale: string;
    evidenceState: 'KNOWN' | 'LIMITED' | 'MISSING';
  }>;
}
```

- [ ] **Step 3: Implement Driver render flow**

The UI order must be fixed in code and tested. A missing target profile blocks candidate recommendations rather than skipping directly to brands.

- [ ] **Step 4: Add safe failure/resume states**

Unauthorized -> sign-in action; limited -> explain missing evidence; service error -> retry; missing configuration -> return to My Bag configuration action.

- [ ] **Step 5: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/driverFit.test.ts
npm run build
git add portal/src/fitting portal/src/main.ts portal/src/__tests__/driverFit.test.ts
git commit -m "feat: add Driver-first governed AI fitting flow"
```

---

### Task 8: Integrate Public and Logged-In Driver Buyers Guide with the Shared Model

**Files:**
- Create: `portal/src/guides/model.ts`
- Create: `portal/src/guides/driver.ts`
- Create: `portal/src/guides/profileReuse.ts`
- Create: `portal/src/__tests__/guideIntegration.test.ts`
- Modify the current Driver Buyers Guide entry point(s) identified during execution.

**Interfaces:**
- Anonymous guide uses `fetchGuideEquipment()` only.
- Logged-in guide may reuse semantically compatible golfer profile facts.
- Reused values are visible/editable and retain source/freshness semantics.
- Guide shortlist remains a lightweight guide result, not a full AI Fit.

- [ ] **Step 1: Write anonymous/logged-in parity tests**

Prove both states use the same canonical family/characteristic truth, while only the logged-in state reuses profile data.

- [ ] **Step 2: Implement visible Tell GAL Once reuse**

Use copy:

```text
Using what GAL already knows about you.
```

Provide `Looks right` and `Update` actions for material reused answers.

- [ ] **Step 3: Add contradiction test**

Given the same product family returned by Guide and AI Fit contracts, canonical identity and current governed characteristics must match exactly.

- [ ] **Step 4: Run guide acceptance and commit**

```bash
npm test -- --run src/__tests__/guideIntegration.test.ts
npm run build
git add portal/src/guides portal/src/__tests__/guideIntegration.test.ts <driver-guide-files>
git commit -m "feat: connect Driver Buyers Guide to shared equipment truth"
```

Before committing, replace `<driver-guide-files>` with the exact current guide files discovered in the implementation worktree; do not commit a placeholder path.

---

### Task 9: Connect Driver State to Today, Insights, and Progress

**Files:**
- Create: `portal/src/surfaces/today.ts`
- Create: `portal/src/surfaces/insights.ts`
- Create: `portal/src/surfaces/progress.ts`
- Create: `portal/src/__tests__/portalSurfaces.test.ts`
- Modify: `portal/src/main.ts`

**Interfaces:**
- Today consumes equipment opportunity state and links to Driver Fit.
- Insights translates governed lifecycle state into golfer-safe labels.
- Progress consumes longitudinal outcome/resolution state; it does not invent golf-score activity.

- [ ] **Step 1: Write translation tests**

Lock mappings:

```ts
ACTIVE -> 'Needs Attention'
ACKNOWLEDGED -> 'Watching'
RESOLVED -> 'Solved'
REGRESSED -> 'Came Back'
EVIDENCE_PENDING -> 'Checking Progress'
INEFFECTIVE -> 'Still Needs Attention'
```

SUPPRESSED/EXPIRED must not become prominent golfer labels.

- [ ] **Step 2: Implement Today Driver opportunity card**

Preferred headline: `GAL Sees a Driver Opportunity`.

Do not show it when the system merely lacks evidence; missing evidence gets a separate completion/action state.

- [ ] **Step 3: Implement progress connection**

Render recommendation/change -> outcome -> resolution state when governed longitudinal data exists. No invented savings, yards, or score improvement.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/portalSurfaces.test.ts
npm run build
git add portal/src/surfaces portal/src/main.ts portal/src/__tests__/portalSurfaces.test.ts
git commit -m "feat: connect Driver intelligence to My GAL surfaces"
```

---

### Task 10: Add Registered/Subscriber Entitlement Tests Without Duplicating Components

**Files:**
- Create: `portal/src/entitlements/model.ts`
- Create: `portal/src/__tests__/entitlements.test.ts`
- Modify shared renderers only where premium depth is actually needed.

**Interfaces:**
- Produces `Entitlements` capability flags.
- Same My Bag/Guide/Fit components receive entitlement props/context.
- Equipment facts and analytical ordering remain invariant across entitlement levels.

- [ ] **Step 1: Write invariant tests**

For the same golfer/equipment data, registered and subscriber fixtures must produce identical canonical equipment identity, readiness, characteristics, compatibility, and candidate analytical order.

- [ ] **Step 2: Implement capability-only entitlement model**

```ts
export interface Entitlements {
  extendedHistory: boolean;
  advancedExplanations: boolean;
  premiumFittingWorkflows: boolean;
}
```

No `subscriberRankBoost`, alternate product source, or separate portal route is allowed.

- [ ] **Step 3: Run tests and commit**

```bash
npm test -- --run src/__tests__/entitlements.test.ts
npm run build
git add portal/src/entitlements portal/src/__tests__/entitlements.test.ts
git commit -m "test: enforce registered subscriber equipment invariants"
```

---

### Task 11: Full Staging Acceptance and Release Gate

**Files:**
- Create/update: `docs/superpowers/reviews/2026-09-04-consumer-integration-staging-acceptance.md`
- Modify: `.github/workflows/my-gal-portal-ci.yml` only if needed to execute the full suite.

**Interfaces:**
- Produces auditable acceptance evidence; does not promote production.

- [ ] **Step 1: Run all portal unit tests and build**

```bash
cd portal
npm ci
npm test -- --run
npm run build
```

Expected: all pass.

- [ ] **Step 2: Run SQL contract/privacy tests against staging**

Run the existing Equipment Knowledge tests plus `consumer_commercial_consent.sql`. Verify:
- anon can execute only the public Guide contract;
- authenticated can execute Guide + AI Fit contracts;
- underlying equipment views remain non-browser-readable;
- commercial consent remains append-only and explicit opt-in;
- non-opted-in golfers are excluded from commercial eligibility;
- minimum-cohort aggregate governance still holds.

- [ ] **Step 3: Execute two-user RLS acceptance**

Use two test golfers. Each may see only their own bag/profile/consent data. Neither may read internal equipment-governance tables or another golfer's consent history.

- [ ] **Step 4: Execute surface/E2E acceptance**

Verify four scenarios:
1. anonymous Driver Guide;
2. registered golfer with incomplete Driver configuration;
3. registered golfer with `AI_FIT_LIMITED` Driver data;
4. subscriber golfer with `AI_FIT_READY` Driver data.

Across all authenticated scenarios verify My Bag -> Driver opportunity -> AI Driver Fit -> target characteristics -> governed candidates -> explanation -> next action -> outcome/progress continuity.

- [ ] **Step 5: Verify editorial/commercial firewall**

Inject differing commerce/affiliate metadata into test fixtures and prove candidate analytical order does not change.

- [ ] **Step 6: Run staging security/performance advisors and record results**

Known leaked-password protection warning remains a separate account-plan blocker; do not enable paid features without approval.

- [ ] **Step 7: Document acceptance evidence**

The review file must include branch SHA, test commands, CI run, staging environment, Supabase advisor findings, Vercel preview URL, known issues, rollback path, and explicit statement `PRODUCTION NOT PROMOTED`.

- [ ] **Step 8: Commit acceptance record**

```bash
git add docs/superpowers/reviews/2026-09-04-consumer-integration-staging-acceptance.md .github/workflows/my-gal-portal-ci.yml
git commit -m "docs: record consumer integration staging acceptance"
```

---

### Task 12: Driver Acceptance Gate and Category Expansion Handoff

**Files:**
- Create: `docs/superpowers/reviews/2026-09-04-driver-consumer-gate.md`
- No category activation changes in this task.

**Interfaces:**
- Produces a binary Driver gate decision.
- If PASS, the shared architecture becomes the baseline for category-by-category activation.
- If FAIL, fix Driver/shared architecture before activating another category.

- [ ] **Step 1: Evaluate the locked Driver acceptance criteria**

PASS only if all are true:
- governed current Driver/configuration appears correctly in My Bag;
- unknown/missing data is not represented as good fit;
- `AI_FIT_LIMITED` and `AI_FIT_READY` are distinct;
- target characteristics appear before brands/models;
- only compatibility-eligible/readiness-eligible configurations appear;
- Keep/Adjust/Reconfigure/Replace remain peer actions where supported;
- public/logged-in Guide and AI Fit share canonical equipment truth;
- registered/subscriber equipment truth and analytical order are invariant;
- commercial opt-in does not affect consumer recommendation/ranking;
- no individual golfer data is exposed to any B2B surface because no B2B consumer surface is built in this phase.

- [ ] **Step 2: Record next category order**

After Driver PASS, activate through separate review gates:

```text
Fairway Wood -> Hybrid -> Irons -> Wedges -> Putter -> Golf Ball
```

A later category that requires a new shared concept must trigger shared-architecture review rather than silently changing an adapter.

- [ ] **Step 3: Commit gate record**

```bash
git add docs/superpowers/reviews/2026-09-04-driver-consumer-gate.md
git commit -m "docs: record Driver consumer integration gate"
```

---

## Self-Review Checklist

Before execution begins, confirm:

- Every consumer surface uses the shared equipment client rather than direct equipment-knowledge queries.
- Driver is the only active category; all seven categories exist in the registry.
- No task creates a second equipment truth store.
- No task makes affiliate/commerce fields part of analytical ranking.
- No task treats lack of evidence as good fit.
- Commercial aggregate participation is explicit opt-in and separate from product use.
- Existing append-only consent and privacy-safe aggregate-learning governance are reused rather than replaced.
- No B2B dashboard or direct row-level industry export is built in this phase.
- Production remains a separate explicit release decision.
- The plan contains no implementation placeholders in code or committed file paths; runtime-discovered current guide files must be replaced with exact paths before any commit command is executed.
