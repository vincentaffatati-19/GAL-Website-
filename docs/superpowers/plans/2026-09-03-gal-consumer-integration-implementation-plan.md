# GAL Consumer Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect My GAL, My Bag, Buyers Guides, and GAL AI Fitting to one governed Equipment Knowledge consumer layer, activate Driver as the first complete vertical slice, and preserve the future privacy-safe B2B Industry Intelligence monetization path.

**Architecture:** Reconcile the existing My GAL shell onto the current integration branch, then add one browser-safe Supabase client, one shared equipment read model, and one category registry for all seven equipment categories. Driver is the only initially active fitter. My Bag, Buyers Guides, AI Fitting, Today, Insights, and Progress consume the same governed equipment truth. Commercial aggregate-data participation is explicit opt-in and extends the existing append-only consent and privacy-safe aggregate-learning architecture rather than creating a second data stack.

**Tech Stack:** Vite, TypeScript, `@supabase/supabase-js`, PostgreSQL/Supabase migrations and RPCs, existing GAL longitudinal consent/aggregate-learning structures, Vitest, SQL acceptance tests, GitHub Actions, Vercel preview/staging.

**Spec:** `docs/superpowers/specs/2026-09-03-gal-consumer-integration-design.md`

## Global Constraints

- Production deployment and production Supabase migration are NOT authorized by this plan.
- Use the exact approved GAL Motion Arc brand asset; do not recreate or approximate the logo.
- Browser configuration is limited to `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`; no service-role material may enter browser code.
- Public Buyers Guides use `public.gal_public_equipment_guide()`; authenticated fitting uses `public.gal_authenticated_equipment_ai_fit()`.
- No consumer surface may maintain an independent equipment-product truth or direct equipment-knowledge query path.
- Characteristics Before Brands is mandatory: `Golfer Evidence -> Golfer Need -> Required Equipment Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`.
- Unknown is not good fit; missing critical evidence narrows or blocks recommendations.
- `AI_FIT_LIMITED` remains visibly and behaviorally distinct from `AI_FIT_READY`.
- Unknown compatibility is not compatible; only governed eligible configurations may become fitting candidates.
- Registered and subscriber users use the same components and data contracts; entitlements add capability but never alter equipment truth or analytical rank.
- Commercial aggregate-data participation is explicit opt-in and separate from ordinary product-use consent.
- Industry customers never receive direct access to identifiable golfer operational data.
- Existing privacy-safe aggregate-learning governance remains the minimum privacy floor; future B2B products consume only governed aggregate outputs, reports, or approved exports.

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
- Reconcile tests: `portal/src/__tests__/branding.test.ts`
- Reconcile tests: `portal/src/__tests__/config.test.ts`
- Reconcile tests: `portal/src/__tests__/router.test.ts`
- Reconcile: `portal/tsconfig.json`
- Reconcile: `portal/vite.config.ts`

**Interfaces:**
- Produces `resolvePortalRoute(pathname: string): PortalRoute`.
- Produces `getPortalConfig(): { supabaseUrl: string; supabasePublishableKey: string }`.
- Preserves routes `today | bag | insights | guides | progress`.

- [ ] **Step 1: Create an implementation branch from the current integration head**

```bash
git switch portal-integration-plan
git pull --ff-only
git switch -c consumer-integration-implementation
```

- [ ] **Step 2: Reapply the PR #25 shell files without merging the stale branch wholesale**

Preserve this router contract:

```ts
export type PortalRoute = 'today' | 'bag' | 'insights' | 'guides' | 'progress';

const ROUTES = new Set<PortalRoute>(['today', 'bag', 'insights', 'guides', 'progress']);

export function resolvePortalRoute(pathname: string): PortalRoute {
  const normalized = pathname.replace(/\/+$/, '');
  const segment = normalized.split('/').filter(Boolean)[1]?.toLowerCase() as PortalRoute | undefined;
  return segment && ROUTES.has(segment) ? segment : 'today';
}
```

- [ ] **Step 3: Run shell tests and build**

```bash
cd portal
npm ci
npm test -- --run
npm run build
```

Expected: branding/config/router tests pass and Vite builds under `/portal/`.

- [ ] **Step 4: Verify no service-role material in the browser bundle**

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
- Modify: `portal/package-lock.json`

**Interfaces:**
- Produces `getSupabaseClient(): SupabaseClient`.
- Produces `getCurrentSession(): Promise<Session | null>`.
- Consumes `getPortalConfig()` from Task 1.

- [ ] **Step 1: Write failing tests for the client/session boundary**

```ts
import { describe, expect, it } from 'vitest';

describe('browser Supabase boundary', () => {
  it('contains no service-role API surface', async () => {
    const mod = await import('../supabase/client');
    expect(JSON.stringify(mod)).not.toMatch(/service[_-]?role/i);
  });
});
```

- [ ] **Step 2: Verify the tests fail before implementation**

```bash
npm test -- --run src/__tests__/supabaseClient.test.ts src/__tests__/session.test.ts
```

Expected: FAIL because the modules do not exist.

- [ ] **Step 3: Add `@supabase/supabase-js` and implement the browser singleton**

```ts
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

- [ ] **Step 4: Implement session lookup**

```ts
import type { Session } from '@supabase/supabase-js';
import { getSupabaseClient } from '../supabase/client';

export async function getCurrentSession(): Promise<Session | null> {
  const { data, error } = await getSupabaseClient().auth.getSession();
  if (error) throw error;
  return data.session;
}
```

- [ ] **Step 5: Run all portal tests/build and commit**

```bash
npm test -- --run
npm run build
git add portal/package.json portal/package-lock.json portal/src/supabase portal/src/auth portal/src/__tests__/supabaseClient.test.ts portal/src/__tests__/session.test.ts
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
- Produces `EquipmentItem`, `EquipmentConfiguration`, `EquipmentOpportunity`, and `EquipmentRecommendation`.
- Produces `EquipmentCategory = 'DRIVER' | 'FAIRWAY_WOOD' | 'HYBRID' | 'IRON' | 'WEDGE' | 'PUTTER' | 'GOLF_BALL'`.
- Produces `CATEGORY_REGISTRY` with Driver active and the other six categories inactive.
- Produces `normalizeGuideRows(rows)` and `normalizeAiFitRows(rows)`.

- [ ] **Step 1: Write the category activation test**

```ts
import { CATEGORY_REGISTRY } from '../equipment/categories';

it('declares seven categories and activates only Driver', () => {
  expect(Object.keys(CATEGORY_REGISTRY)).toHaveLength(7);
  expect(CATEGORY_REGISTRY.DRIVER.active).toBe(true);
  expect(Object.entries(CATEGORY_REGISTRY).filter(([, value]) => value.active).map(([key]) => key)).toEqual(['DRIVER']);
});
```

- [ ] **Step 2: Implement stable consumer types**

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

`normalizeAiFitRows()` maps `approved_characteristics`, `readiness_state`, `blocking_gap_count`, `configuration_id`, `equipment_configuration_id`, `configuration_key`, `configuration_name`, `support_state`, and `limited_evidence`. It must not synthesize fit scores, savings, confidence scores, or recommendations.

- [ ] **Step 5: Run tests and commit**

```bash
npm test -- --run src/__tests__/equipmentTypes.test.ts src/__tests__/equipmentCategories.test.ts src/__tests__/equipmentNormalize.test.ts src/__tests__/equipmentState.test.ts
git add portal/src/equipment portal/src/__tests__/equipmentTypes.test.ts portal/src/__tests__/equipmentCategories.test.ts portal/src/__tests__/equipmentNormalize.test.ts portal/src/__tests__/equipmentState.test.ts
git commit -m "feat: add shared equipment consumer model"
```

---

### Task 4: Add the Sole Browser Equipment Data Client

**Files:**
- Create: `portal/src/equipment/client.ts`
- Create: `portal/src/equipment/errors.ts`
- Create: `portal/src/__tests__/equipmentClient.test.ts`
- Create: `portal/src/__tests__/equipmentArchitecture.test.ts`

**Interfaces:**
- Produces `fetchGuideEquipment(): Promise<EquipmentItem[]>`.
- Produces `fetchAiFitEquipment(): Promise<Array<{ item: EquipmentItem; configuration: EquipmentConfiguration }>>`.
- No component may call the equipment RPCs directly.

- [ ] **Step 1: Write failing RPC-routing tests**

Verify the public client calls `gal_public_equipment_guide`; authenticated fitting calls `gal_authenticated_equipment_ai_fit`; unauthenticated fitting returns `AUTH_REQUIRED` and never falls back to product-first ranking.

- [ ] **Step 2: Implement the data boundary**

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

Scan `portal/src` and fail if either equipment RPC name appears outside `portal/src/equipment/client.ts` and `portal/src/__tests__/equipmentClient.test.ts`.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run
npm run build
git add portal/src/equipment portal/src/__tests__/equipmentClient.test.ts portal/src/__tests__/equipmentArchitecture.test.ts
git commit -m "feat: add governed equipment browser client"
```

---

### Task 5: Add Explicit Commercial Aggregate-Data Opt-In Groundwork

**Files:**
- Create: `supabase/migrations/20260904022000_consumer_commercial_consent.sql`
- Create: `supabase/tests/consumer_commercial_consent.sql`
- Create: `portal/src/privacy/commercialConsent.ts`
- Create: `portal/src/__tests__/commercialConsent.test.ts`
- Modify only if required by the existing consent vocabulary constraint: `supabase/migrations/20260904022000_consumer_commercial_consent.sql`

**Interfaces:**
- Reuses existing append-only `gal_consent_records` behavior and current-user RLS.
- Introduces consent purpose `COMMERCIAL_AGGREGATE` separately from ordinary product use and `ANALYTICS_OPTIONAL`.
- Produces `getCommercialAggregateConsent()` and `recordCommercialAggregateConsent(decision)`.
- Does not create a B2B dashboard or expose individual golfer records.

- [ ] **Step 1: Write the SQL acceptance test first**

The test proves:
1. latest `COMMERCIAL_AGGREGATE` decision controls commercial eligibility;
2. consent history is append-only;
3. authenticated golfers can only read/insert their own consent records;
4. ordinary product use still works without commercial opt-in;
5. commercial aggregate eligibility requires the existing analytics eligibility AND latest `COMMERCIAL_AGGREGATE=ACCEPTED`.

- [ ] **Step 2: Implement the additive migration**

Extend the current consent vocabulary to allow `COMMERCIAL_AGGREGATE` while retaining every currently allowed consent value. Preserve the existing append-only table and RLS policies. Create a non-browser-readable service/internal eligibility view named `gal_commercial_aggregate_eligible_users_v` whose rows contain only `user_id` and the effective consent timestamp; revoke browser-role access.

- [ ] **Step 3: Implement the browser preference helper against the actual current consent column names**

```ts
export type CommercialConsentDecision = 'ACCEPTED' | 'DECLINED' | 'WITHDRAWN';
```

The helper must resolve the signed-in user, insert a new consent event, and never update/delete prior consent rows.

- [ ] **Step 4: Run SQL acceptance in staging and portal unit tests**

Expected: explicit opt-in gates commercial eligibility; withdrawal removes future eligibility without deleting history.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260904022000_consumer_commercial_consent.sql supabase/tests/consumer_commercial_consent.sql portal/src/privacy/commercialConsent.ts portal/src/__tests__/commercialConsent.test.ts
git commit -m "feat: add commercial aggregate consent boundary"
```

---

### Task 6: Integrate My Bag with Governed Equipment Identity

**Files:**
- Create: `portal/src/bag/model.ts`
- Create: `portal/src/bag/client.ts`
- Create: `portal/src/bag/render.ts`
- Create: `portal/src/__tests__/bagModel.test.ts`
- Modify: `portal/src/main.ts`

**Interfaces:**
- Reads golfer-owned `gal_bags` / `gal_bag_items` through golfer-safe RLS.
- Uses `gal_bag_items.equipment_configuration_id` as governed configuration identity when present.
- Treats legacy `configuration` JSON as a migration bridge only.
- Produces `BagEquipmentView` with `KNOWN` and `MISSING_CONFIGURATION` states.

- [ ] **Step 1: Write tests proving unknown is not good fit**

A bag item without governed configuration identity must render `Configuration details needed`, never `Good fit` or an inferred configuration.

- [ ] **Step 2: Implement the bag projection**

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

- [ ] **Step 3: Route `/portal/bag` through the bag renderer**

Preserve the shell/navigation and replace only the route content.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/bagModel.test.ts
npm run build
git add portal/src/bag portal/src/main.ts portal/src/__tests__/bagModel.test.ts
git commit -m "feat: connect My Bag to governed equipment identity"
```

---

### Task 7: Implement the Driver-Only AI Fitting Vertical Slice

**Files:**
- Create: `portal/src/fitting/driver/model.ts`
- Create: `portal/src/fitting/driver/targets.ts`
- Create: `portal/src/fitting/driver/render.ts`
- Create: `portal/src/fitting/driver/actions.ts`
- Create: `portal/src/__tests__/driverFit.test.ts`
- Modify: `portal/src/main.ts`

**Interfaces:**
- Consumes shared equipment client and Driver category adapter.
- Produces fixed sequence `Need -> Target Characteristics -> Candidate Configurations -> Brands/Models -> Commerce`.
- Produces peer analytical actions `KEEP | ADJUST | RECONFIGURE | REPLACE` when evidence supports them.
- Commercial metadata cannot affect analytical ordering.

- [ ] **Step 1: Write ordering/trust tests**

Tests prove target characteristics render before any brand/model section; `AI_FIT_LIMITED` shows its limitation; unready/ineligible configurations never render; no fit score, Bag Health, or fabricated yardage is created; commerce cannot alter analytical ordering.

- [ ] **Step 2: Implement Driver target characteristics separately from candidates**

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

- [ ] **Step 3: Implement safe failure/resume behavior**

Unauthorized -> sign-in; limited -> missing-evidence explanation; service error -> retry; missing configuration -> return to My Bag configuration action.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/driverFit.test.ts
npm run build
git add portal/src/fitting portal/src/main.ts portal/src/__tests__/driverFit.test.ts
git commit -m "feat: add Driver-first governed AI fitting flow"
```

---

### Task 8: Integrate the Driver Buyers Guide with the Shared Model

**Files:**
- Modify: `drivers.html`
- Create: `portal/src/guides/model.ts`
- Create: `portal/src/guides/driver.ts`
- Create: `portal/src/guides/profileReuse.ts`
- Create: `portal/src/__tests__/guideIntegration.test.ts`
- Modify: `portal/src/main.ts`

**Interfaces:**
- `drivers.html` is the current public Driver category foundation; it becomes the public entry point to the governed Driver Guide experience rather than maintaining a separate product dataset.
- Anonymous Guide uses `fetchGuideEquipment()` only.
- Logged-in Guide may reuse semantically compatible golfer profile facts.
- Reused values are visible/editable and retain source/freshness semantics.
- Guide shortlist remains a lightweight guide result, not a full AI Fit.

- [ ] **Step 1: Write anonymous/logged-in parity tests**

Both states must use the same canonical equipment identity/current governed characteristics; only logged-in state receives Tell GAL Once reuse.

- [ ] **Step 2: Implement visible profile reuse**

Use copy `Using what GAL already knows about you.` with `Looks right` and `Update` actions for reused material inputs.

- [ ] **Step 3: Add a contradiction guard test**

For the same family returned by Guide and AI Fit contracts, canonical identity and current governed characteristics must match exactly.

- [ ] **Step 4: Update `drivers.html` to launch/link the governed Driver Guide experience**

Retain educational content and public accessibility; do not embed a second static Driver product truth dataset in the page.

- [ ] **Step 5: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/guideIntegration.test.ts
npm run build
git add drivers.html portal/src/guides portal/src/main.ts portal/src/__tests__/guideIntegration.test.ts
git commit -m "feat: connect Driver Buyers Guide to shared equipment truth"
```

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

- [ ] **Step 1: Lock insight-language mappings in tests**

```text
ACTIVE -> Needs Attention
ACKNOWLEDGED -> Watching
RESOLVED -> Solved
REGRESSED -> Came Back
EVIDENCE_PENDING -> Checking Progress
INEFFECTIVE -> Still Needs Attention
```

`SUPPRESSED` and `EXPIRED` do not become prominent golfer labels.

- [ ] **Step 2: Implement the Today Driver opportunity card**

Preferred headline: `GAL Sees a Driver Opportunity`. Do not show it merely because evidence is missing.

- [ ] **Step 3: Implement Progress continuity**

Render recommendation/change -> outcome -> resolution only when governed longitudinal data exists. No invented savings, yards, or score improvement.

- [ ] **Step 4: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/portalSurfaces.test.ts
npm run build
git add portal/src/surfaces portal/src/main.ts portal/src/__tests__/portalSurfaces.test.ts
git commit -m "feat: connect Driver intelligence to My GAL surfaces"
```

---

### Task 10: Enforce Registered/Subscriber Component and Truth Invariants

**Files:**
- Create: `portal/src/entitlements/model.ts`
- Create: `portal/src/__tests__/entitlements.test.ts`

**Interfaces:**
- Produces capability flags only.
- Same My Bag/Guide/Fit components receive entitlements.
- Equipment facts and analytical ordering remain invariant across entitlement levels.

- [ ] **Step 1: Write invariant tests**

For identical golfer/equipment inputs, registered and subscriber fixtures must produce identical canonical identity, readiness, characteristics, compatibility, and candidate analytical order.

- [ ] **Step 2: Implement capability-only entitlements**

```ts
export interface Entitlements {
  extendedHistory: boolean;
  advancedExplanations: boolean;
  premiumFittingWorkflows: boolean;
}
```

No subscriber rank boost, alternate equipment source, or duplicate portal route is allowed.

- [ ] **Step 3: Run tests/build and commit**

```bash
npm test -- --run src/__tests__/entitlements.test.ts
npm run build
git add portal/src/entitlements portal/src/__tests__/entitlements.test.ts
git commit -m "test: enforce registered subscriber equipment invariants"
```

---

### Task 11: Full Staging Acceptance and Release Gate

**Files:**
- Create: `docs/superpowers/reviews/2026-09-04-consumer-integration-staging-acceptance.md`
- Modify only if required by new test coverage: `.github/workflows/my-gal-portal-ci.yml`

**Interfaces:**
- Produces auditable staging acceptance evidence.
- Does not promote production.

- [ ] **Step 1: Run all portal tests/build**

```bash
cd portal
npm ci
npm test -- --run
npm run build
```

- [ ] **Step 2: Run SQL contract/privacy tests against staging**

Run existing Equipment Knowledge tests plus `supabase/tests/consumer_commercial_consent.sql`. Verify public/authenticated RPC privileges, non-browser internal view access, append-only consent, explicit commercial opt-in, and minimum-cohort aggregate governance.

- [ ] **Step 3: Execute two-user RLS acceptance**

Each test golfer sees only their own bag/profile/consent data; neither sees internal governance tables or the other golfer's consent history.

- [ ] **Step 4: Execute four surface/E2E scenarios**

1. Anonymous Driver Guide.
2. Registered golfer with incomplete Driver configuration.
3. Registered golfer with `AI_FIT_LIMITED` Driver evidence.
4. Subscriber golfer with `AI_FIT_READY` Driver evidence.

For authenticated flows verify My Bag -> Driver opportunity -> AI Driver Fit -> target characteristics -> governed candidates -> explanation -> next action -> outcome/progress continuity.

- [ ] **Step 5: Verify the commercial/editorial firewall**

Vary commerce/affiliate metadata in fixtures and prove analytical candidate ordering is unchanged.

- [ ] **Step 6: Run staging security/performance advisors and record findings**

The known leaked-password protection warning remains a separate account-plan blocker; do not enable paid features without approval.

- [ ] **Step 7: Record acceptance evidence**

The review includes branch SHA, tests, CI run, staging environment, advisor findings, Vercel preview URL, known issues, rollback path, and the explicit statement `PRODUCTION NOT PROMOTED`.

- [ ] **Step 8: Commit the acceptance record**

```bash
git add docs/superpowers/reviews/2026-09-04-consumer-integration-staging-acceptance.md .github/workflows/my-gal-portal-ci.yml
git commit -m "docs: record consumer integration staging acceptance"
```

---

### Task 12: Driver Acceptance Gate and Category Expansion Handoff

**Files:**
- Create: `docs/superpowers/reviews/2026-09-04-driver-consumer-gate.md`

**Interfaces:**
- Produces a binary Driver gate decision.
- PASS makes the shared architecture the baseline for category-by-category activation.
- FAIL requires fixing Driver/shared architecture before another category is activated.

- [ ] **Step 1: Evaluate Driver acceptance**

PASS only if all are true:
- governed Driver/configuration is correct in My Bag;
- unknown/missing data is never represented as good fit;
- `AI_FIT_LIMITED` and `AI_FIT_READY` are distinct;
- target characteristics appear before brands/models;
- only eligibility/readiness-valid configurations appear;
- Keep/Adjust/Reconfigure/Replace remain peer analytical actions where supported;
- public/logged-in Guide and AI Fit share canonical equipment truth;
- registered/subscriber equipment truth and analytical order are invariant;
- commercial opt-in does not affect recommendation/ranking;
- no B2B surface exposes golfer-level data because no B2B consumer surface is built in this phase.

- [ ] **Step 2: Record the post-Driver category order**

```text
Fairway Wood -> Hybrid -> Irons -> Wedges -> Putter -> Golf Ball
```

A later category requiring a new shared concept triggers shared-architecture review rather than a silent adapter change.

- [ ] **Step 3: Commit the gate record**

```bash
git add docs/superpowers/reviews/2026-09-04-driver-consumer-gate.md
git commit -m "docs: record Driver consumer integration gate"
```

---

## Self-Review Result

- Spec coverage: all approved consumer-integration sections are assigned to implementation tasks.
- B2B monetization boundary: explicit commercial opt-in is implemented now; B2B dashboards/direct datasets are intentionally deferred.
- One-equipment-truth rule: enforced by shared client plus architecture guard tests.
- Category compromise: all seven categories exist structurally; Driver alone is activated initially.
- Registered/subscriber synchronization: enforced through shared components and invariant tests.
- Editorial integrity: commerce cannot influence analytical ordering.
- Privacy: commercial eligibility reuses existing append-only consent and aggregate governance; no direct industry access to golfer records.
- Placeholder scan: no placeholder migration name, no placeholder guide file, no `TODO`, and no `TBD` remain.
- Production gate: explicit throughout; staging acceptance does not authorize promotion.
