# My GAL Equipment Intelligence — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first authenticated **My GAL — Your Equipment Intelligence Center** release at `/portal/`, helping a golfer immediately understand what GAL knows about their equipment, what deserves attention, why it matters, what to do next, and what has changed over time.

**Architecture:** Preserve the existing flat public site. Add a Vite + TypeScript SPA at `/portal/` using Supabase Auth and golfer-safe RLS reads. The customer-facing architecture is `Today -> My Bag -> Insights -> Guides -> Progress`; Today is the default Equipment Brief, while the governed longitudinal engine remains underneath the experience. All longitudinal mutations pass through a narrow authenticated Supabase Edge Function and service-role credentials remain server-only.

**Tech Stack:** Vite, TypeScript, `@supabase/supabase-js`, Vitest, Testing Library DOM, Playwright, Supabase Edge Functions/Deno, existing PostgreSQL/RLS/RPC contract.

**Specs:**
- `docs/superpowers/specs/2026-08-31-portal-longitudinal-integration-design.md`
- `docs/superpowers/specs/2026-08-31-my-gal-equipment-intelligence-product-design.md`

## Global Constraints

- Product name: **My GAL**; descriptor: **Your Equipment Intelligence Center**.
- Product loop: `My Bag -> What GAL sees -> What matters -> What I should do -> What happened afterward`.
- Primary navigation: **Today, My Bag, Insights, Guides, Progress**; Today is default.
- Do not present the product as a generic customer portal/dashboard in golfer-facing copy.
- Never fabricate Bag Health, dollar savings, fit labels, confidence, recommendations, or other intelligence when governed evidence is absent.
- Preserve the public flat-file website; portal route remains `/portal/`.
- Browser receives only public Supabase configuration and authenticated session state.
- Service-role credentials must never appear in browser code, built assets, or committed configuration.
- Golfer-safe reads rely on RLS; JavaScript filtering is presentation-only.
- Mutations use an allowlisted Supabase Edge Function; no generic table/RPC proxy.
- Server derives golfer identity from the authenticated access token; client `user_id` is never authority.
- Registered and subscriber experiences use the same components/contracts; subscriber features are additive only.
- Production subscriber behavior remains base-only until an authoritative entitlement source is integrated; staging fixtures may exercise subscriber UI.
- Staging verification is mandatory before production release; no production golfer data is copied to staging unless sanitized/anonymized.
- Locked GAL brand: Option 7, Navy `#0B245F`, Orange `#FF5A1F`, white/light gray, current header/footer treatment.
- Existing leaked-password-protection warning remains a separate registered-golfer launch blocker until the Supabase plan supports it.

---

## File Structure

```text
portal/
  index.html
  package.json
  tsconfig.json
  vite.config.ts
  src/
    main.ts                       # bootstrap/router orchestration only
    config.ts                     # public Supabase config validation
    supabase.ts                   # browser client singleton
    auth.ts                       # session/sign-in/sign-out helpers
    router.ts                     # Today/My Bag/Insights/Guides/Progress routes
    types.ts                      # golfer-safe product models
    data/
      insights.ts                 # RLS insight/delivery/resolution reads
      bag.ts                      # golfer-safe bag summary reads when available
      progress.ts                 # evidence-backed longitudinal timeline assembly
      entitlements.ts             # registered/subscriber capability resolver
    api/
      insightActions.ts           # typed Edge Function client
    ui/
      appShell.ts                 # My GAL shell/navigation/session state
      today.ts                    # Equipment Brief composition
      bag.ts                      # My Bag summary + honest incomplete state
      insightFeed.ts              # prioritized insight list
      insightDetail.ts            # explanation/history/action detail
      guides.ts                   # authenticated guide entry/personalization-ready shell
      progress.ts                 # evidence-backed optimization history
      insightActions.ts           # response controls
      status.ts                   # backend -> golfer-language state translation
      states.ts                   # loading/empty/error/session states
    styles/portal.css
    __tests__/
      config.test.ts
      auth.test.ts
      router.test.ts
      insights.test.ts
      entitlements.test.ts
      productLanguage.test.ts
      insightActions.test.ts
      ui.test.ts
  e2e/portal.spec.ts
  playwright.config.ts

supabase/functions/portal-insight-action/
  index.ts
  auth.ts
  actions.ts
  errors.ts
  types.ts
  index.test.ts

supabase/tests/portal_rls_acceptance.sql
docs/data/longitudinal/portal-staging-acceptance.md
```

---

### Task 1: My GAL Build Skeleton, Branding, and Product Router

**Files:** Create `portal/package.json`, `portal/tsconfig.json`, `portal/vite.config.ts`, `portal/index.html`, `portal/src/config.ts`, `portal/src/router.ts`, `portal/src/main.ts`, `portal/src/styles/portal.css`; test `portal/src/__tests__/config.test.ts`, `portal/src/__tests__/router.test.ts`.

**Produces:** `getPortalConfig()`, route union `'today' | 'bag' | 'insights' | 'guides' | 'progress'`, Today default, `/portal/` build.

- [ ] Write failing tests proving missing public Supabase config fails closed, `/portal/` resolves to Today, and each primary navigation destination resolves deterministically.
- [ ] Run `cd portal && npm test -- --run src/__tests__/config.test.ts src/__tests__/router.test.ts`; expect failure because modules do not exist.
- [ ] Create Vite/TypeScript/Vitest/Playwright package; set Vite `base: '/portal/'`; implement config using only `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`.
- [ ] Implement router with exactly Today, My Bag, Insights, Guides, Progress and Today as fallback/default.
- [ ] Add shell CSS variables for GAL Navy/Orange and responsive primitives; do not add a numeric Bag Health placeholder.
- [ ] Run tests and `npm run build`; inspect built assets for `service_role` and `SUPABASE_SERVICE_ROLE_KEY`; expected zero secret exposure.
- [ ] Commit: `feat(my-gal): scaffold equipment intelligence experience`.

### Task 2: Supabase Browser Client and Authentication

**Files:** Create `portal/src/supabase.ts`, `portal/src/auth.ts`; modify `portal/src/main.ts`; test `portal/src/__tests__/auth.test.ts`.

**Produces:** singleton public client; `getCurrentSession`, `signInWithPassword`, `signOut`, `subscribeToAuth`.

- [ ] Write failing mocked-client tests for session load, sign-in, sign-out, auth subscription cleanup, and absence of any `user_id` argument.
- [ ] Run auth tests; expect missing implementation failure.
- [ ] Implement singleton client with persisted/auto-refreshed Supabase Auth session using public config only.
- [ ] Implement auth helpers; browser must not map auth user to `gal_users` for authorization.
- [ ] Run auth tests; expect PASS.
- [ ] Commit: `feat(my-gal): add authenticated session state`.

### Task 3: Golfer-Safe Equipment Intelligence Read Model

**Files:** Create `portal/src/types.ts`, `portal/src/data/insights.ts`, `portal/src/data/bag.ts`, `portal/src/data/progress.ts`; test `portal/src/__tests__/insights.test.ts`.

**Produces:** `PortalInsight`, `BagSummary`, `ProgressEvent`, `loadPortalInsights()`, `loadBagSummary()`, `loadProgressHistory()`.

- [ ] Write failing tests asserting browser queries only golfer-safe relations and never signals, exposure events, learning tables, governance actors, resolution rules/events, or contributors.
- [ ] Define `PortalInsight` with ID/domain/code/headline/message/severity/backend status/delivery status/resolution status/updated timestamp; define bag/progress models with nullable/unknown states rather than inferred fit claims.
- [ ] Implement insight read using RLS with no client user-id filter; merge delivery/resolution state by insight ID.
- [ ] Implement bag summary only from currently available golfer-safe bag data; when data is unavailable return an explicit incomplete/empty state, never `Good fit` by inference.
- [ ] Implement progress history from evidence-backed response/outcome/resolution timestamps only; do not calculate dollar savings.
- [ ] Sort actionable material insights first, then severity and recency.
- [ ] Run tests; expect PASS.
- [ ] Commit: `feat(my-gal): add golfer-safe equipment intelligence model`.

### Task 4: Golfer-Language Translation and Subscriber Entitlements

**Files:** Create `portal/src/ui/status.ts`, `portal/src/data/entitlements.ts`; test `portal/src/__tests__/productLanguage.test.ts`, `portal/src/__tests__/entitlements.test.ts`.

**Produces:** `toGolferStatus(insightStatus, resolutionStatus)` and `resolveEntitlements(claims)`.

- [ ] Write failing tests for mappings: ACTIVE→Needs Attention; ACKNOWLEDGED→Watching; RESOLVED→Solved; REGRESSED→Came Back; EVIDENCE_PENDING→Checking Progress; INEFFECTIVE→Still Needs Attention.
- [ ] Add negative copy tests proving primary UI does not render `ACTIVE`, `ACKNOWLEDGED`, `REGRESSED`, `EVIDENCE_PENDING`, `SUPPRESSED`, or `EXPIRED` as unexplained golfer-facing labels.
- [ ] Write entitlement tests: malformed/unknown claims default REGISTERED; staging `gal_portal_tier='SUBSCRIBER'` enables only additive presentation capabilities.
- [ ] Implement translations and entitlement resolver; entitlements must never affect RLS ownership.
- [ ] Run tests; expect PASS.
- [ ] Commit: `feat(my-gal): add golfer language and shared entitlements`.

### Task 5: Edge Function Authentication and Safe Contract

**Files:** Create `supabase/functions/portal-insight-action/{types.ts,errors.ts,auth.ts,index.test.ts}`.

**Produces:** authenticated actor resolution and allowlisted payload union for `present`, `acknowledge`, `dismiss`, `snooze`, `act`.

- [ ] Write failing Deno tests: missing/invalid Authorization→401; active mapped user resolves; client `user_id` rejected.
- [ ] Run Deno tests; expect failure.
- [ ] Implement bearer-token validation using caller-scoped Supabase client, then server-side active `gal_users` lookup using service client.
- [ ] Normalize external errors to `UNAUTHENTICATED`, `ACCOUNT_NOT_READY`, `NOT_FOUND`, `NOT_ALLOWED`, `STALE_ACTION`, `TEMPORARY_FAILURE`.
- [ ] Run tests; expect PASS.
- [ ] Commit: `feat(my-gal-api): add authenticated action boundary`.

### Task 6: Allowlisted Insight Mutation Handlers

**Files:** Create `supabase/functions/portal-insight-action/actions.ts`, `index.ts`; modify `index.test.ts`.

**Produces:** server-derived ownership check and exact mapping to `gal_record_insight_presentation` / `gal_record_insight_response`.

- [ ] Add failing tests for five allowed actions plus rejection of `outcome`, `resolve`, `regress`, `publish_learning`, `promote`, arbitrary `rpc`, wrong owner, malformed snooze, client user ID.
- [ ] Run tests; expect failure.
- [ ] Verify target insight belongs to server-derived GAL user without revealing other-user existence.
- [ ] Map present→presentation RPC; acknowledge/dismiss/snooze/act→response RPC; set `source_system='gal_portal'`; generate source event keys server-side.
- [ ] Ensure no browser action can create an outcome or claim resolution.
- [ ] Run tests; expect PASS.
- [ ] Commit: `feat(my-gal-api): add governed insight actions`.

### Task 7: Typed Browser Mutation Client

**Files:** Create `portal/src/api/insightActions.ts`; test `portal/src/__tests__/insightActions.test.ts`.

**Produces:** `presentInsight`, `acknowledgeInsight`, `dismissInsight`, `snoozeInsight`, `actOnInsight`.

- [ ] Write failing tests proving calls go only through `functions.invoke('portal-insight-action')` and never send user IDs, actor IDs, RPC names, rule codes, or table names.
- [ ] Implement typed wrappers and safe discriminated `ActionResult`; never surface raw Postgres/schema errors.
- [ ] Run tests; expect PASS.
- [ ] Commit: `feat(my-gal): add typed equipment insight actions`.

### Task 8: My GAL Shared Shell and Five Product Surfaces

**Files:** Create `portal/src/ui/{appShell.ts,today.ts,bag.ts,insightFeed.ts,insightDetail.ts,guides.ts,progress.ts,insightActions.ts,states.ts}`; modify `main.ts`, `portal.css`; test `portal/src/__tests__/ui.test.ts`.

**Produces:** shared registered/subscriber UI with Today default.

- [ ] Write failing DOM tests for My GAL name/descriptor, five navigation labels, Today default, Equipment Brief, prioritized material insight, honest My Bag incomplete state, Insights status translation, Guides authenticated entry, Progress evidence timeline, subscriber additive content, loading/empty/error/session states, and action controls.
- [ ] Add tests proving no fabricated `Bag Health`, `$ saved`, `Good fit`, or personalized recommendation appears when its governed source is absent.
- [ ] Implement My GAL shell and Today Equipment Brief. Today leads with what deserves attention and next action; it is not a raw chart dashboard.
- [ ] Implement My Bag summary. Render only supported equipment/status data; unknown remains unknown.
- [ ] Implement Insights detail with progressive disclosure: what GAL sees → why → golfer-safe context → next action → history. Never expose detector/source/governance internals.
- [ ] Implement Guides entry designed to accept known-data prefills later; do not silently skip questions in Phase 1 unless current guide semantics and editable prefill support are explicitly wired.
- [ ] Implement Progress from evidence-backed longitudinal events; no golf-score tracking or invented savings.
- [ ] Wire actions; after mutation reload governed data instead of fabricating local analytical state.
- [ ] Add mobile-first CSS: 44px practical touch targets, visible focus, status text not color-only, no 320px horizontal overflow, familiar mobile bottom nav when accessible.
- [ ] Run UI tests and production build; expect PASS.
- [ ] Commit: `feat(my-gal): build equipment intelligence product surfaces`.

### Task 9: Two-User RLS and Direct-RPC Acceptance

**Files:** Create `supabase/tests/portal_rls_acceptance.sql`.

- [ ] Write transaction-wrapped staging test with two synthetic users and one governed insight each.
- [ ] Assert User A sees only A golfer-safe data; A cannot read internal tables; A cannot execute service-only presentation/response/outcome/learning RPCs directly; B cannot discover A rows.
- [ ] End with `ROLLBACK` and verify synthetic row counts return to baseline.
- [ ] Run against GAL Longitudinal Staging; all assertions must pass.
- [ ] Commit: `test(my-gal): prove golfer isolation and RPC denial`.

### Task 10: Staging Deployment and End-to-End Product Acceptance

**Files:** Create `portal/playwright.config.ts`, `portal/e2e/portal.spec.ts`, `docs/data/longitudinal/portal-staging-acceptance.md`.

- [ ] Write checklist recording environment, Git SHA, function/build version, sanitized fixture IDs, and PASS/FAIL evidence.
- [ ] Add Playwright scenarios: A sees A insight; B cannot see A; presentation/replay safe; acknowledge/snooze/dismiss update correctly; My GAL Today default; all five nav destinations work; subscriber fixture uses same components plus additive enhancement; logout protects portal; 320px no overflow; keyboard focus reaches controls.
- [ ] Add product-language assertions: no raw lifecycle jargon and no fabricated Bag Health/savings/fit claims.
- [ ] Deploy Edge Function to staging with secrets in Supabase secret storage only.
- [ ] Deploy portal staging build with staging URL/publishable key; verify no service-role value/name and no production project URL in built JS.
- [ ] Run unit, Deno, SQL RLS, Playwright, mobile/accessibility acceptance; record evidence.
- [ ] Commit: `test(my-gal): record staging acceptance`.

### Task 11: Public-Site Entry and Guide Continuity

**Files:** Modify only the shared public navigation/header files actually used by current site; modify E2E tests.

- [ ] First verify staging is GREEN; do not expose public My GAL entry before that gate.
- [ ] Add one consistent **My GAL** sign-in/account entry across public and buyer-guide navigation using the existing locked header treatment.
- [ ] Verify public Buyers Guides remain available anonymously and existing guide/navigation/footer/legal behavior is unchanged.
- [ ] Verify authenticated guide entry can route into My GAL Guides without creating a second portal implementation.
- [ ] Run regression/E2E suite; expect PASS.
- [ ] Commit: `feat(site): add My GAL authenticated entry`.

### Task 12: Release Review and Production Gate

**Files:** Update `docs/data/longitudinal/portal-staging-acceptance.md`; update `VERSION.txt` only for an approved RC.

- [ ] Run complete verification from clean checkout/worktree: unit, build, Deno, SQL staging RLS, Playwright.
- [ ] Search built assets for service-role material, production secrets, forbidden internal-table browser queries, generic RPC passthroughs, and fabricated placeholder intelligence.
- [ ] Run staging Supabase Security/Performance Advisors; no new WARN/ERROR introduced. Track existing leaked-password warning separately.
- [ ] Create RC PR with staging URL, sanitized evidence, shared registered/subscriber confirmation, server-only service-role confirmation, and screenshots/manual review evidence for Today/My Bag/Insights/Guides/Progress on mobile/desktop.
- [ ] Production promotion requires explicit RC approval; do not automatically deploy from this plan.
- [ ] After approval, deploy reviewed assets/function with production secrets; no staging users/data copied.
- [ ] Run production smoke: sign-in, own data, cross-user isolation, presentation, response, five navigation surfaces, logout, public-site navigation; remove persistent synthetic records if any.
- [ ] Re-run production advisors and record release evidence; do not remove useful indexes because of pre-launch `unused_index` INFO.
- [ ] Commit approved version/release record: `release(my-gal): record equipment intelligence production candidate`.

---

## Plan Self-Review Results

- **Product-model coverage:** Today Equipment Brief, My Bag, golfer-language Insights, personalized-ready Guides, and equipment Progress all have explicit tasks and acceptance criteria.
- **No invented metrics:** Bag Health, dollar savings, unsupported fit labels, and recommendations are explicitly prohibited until governed sources/policies exist.
- **Architecture preservation:** Existing Supabase Auth/RLS/service-only RPC security boundaries remain unchanged.
- **Shared user/subscriber rule:** One component/data model with additive entitlements is tested in unit and E2E acceptance.
- **Scope:** Full visual bag intelligence, governed Bag Health formula, production billing, advanced guide prefilling, notification delivery, and Equipment Migration Intelligence remain later increments rather than hidden Phase 1 work.
- **Placeholder scan:** No TBD/TODO execution placeholders.
