# GAL UX10.01 Tee Box Personalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the UX5 composited course+bag scene with the locked `GAL-UX10.01` architecture: independently selectable tee-box background, independently selectable personalized bag visual, governed equipment status, and contextual club intelligence.

**Architecture:** Keep existing Supabase/auth/equipment/insight contracts unchanged. Introduce a presentation-only UX10 preference model and layered scene renderer; tee-box and bag choices persist locally for RC1 but never enter analytical inputs. Today and My Bag share the same UX10 scene component, while Driver detail adds the locked five-tab progressive-disclosure model.

**Tech Stack:** TypeScript 7, Vite 8, Vitest 4, existing HTML-string renderers, CSS, browser `localStorage`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-04-gal-ux10-01-tee-box-personalization-design.md`

## Global Constraints

- Current UX family is `GAL-UX10`; current locked version is `GAL-UX10.01`; first candidate is `GAL-UX10.01-RC1`.
- Primary navigation remains exactly `Today | My Bag | Insights | Guides | Progress`.
- Tee-box choice and bag visual choice are independent presentation-only state.
- Presentation preferences must never alter equipment identity, scoring, insights, recommendations, or outcomes.
- A combined course+bag image is forbidden as the active UX10 scene.
- Mockup metrics, valuations, yardage gains, product recommendations, and real-world-results claims must not ship as golfer facts without governed evidence.
- Option 7A Motion Arc remains the locked GAL identity.
- Production remains untouched until explicit user approval.

---

### Task 1: Establish UX10 presentation-state contracts and failing separation tests

**Files:**
- Create: `portal/src/ux10/personalization.ts`
- Create: `portal/src/__tests__/ux10Personalization.test.ts`
- Replace: `portal/src/__tests__/ux5MidIntegrated.test.ts` with `portal/src/__tests__/ux10Integrated.test.ts`
- Modify: `portal/src/__tests__/candidateVisuals.test.ts`

**Interfaces:**
- Produces: `TeeBoxThemeId`, `BagVisualId`, `Ux10PresentationPreferences`, `UX10_TEE_BOX_THEMES`, `UX10_BAG_VISUALS`, `loadUx10PresentationPreferences()`, `saveUx10PresentationPreferences()`.
- Later tasks consume these exact names.

- [ ] **Step 1: Write failing preference-isolation tests**

```ts
import { describe, expect, it } from 'vitest';
import {
  DEFAULT_UX10_PREFERENCES,
  loadUx10PresentationPreferences,
  saveUx10PresentationPreferences,
} from '../ux10/personalization';

function memoryStorage(initial: Record<string, string> = {}) {
  const values = new Map(Object.entries(initial));
  return {
    getItem: (key: string) => values.get(key) ?? null,
    setItem: (key: string, value: string) => void values.set(key, value),
  };
}

describe('UX10 presentation-only preferences', () => {
  it('loads safe defaults when no preference exists', () => {
    expect(loadUx10PresentationPreferences(memoryStorage())).toEqual(DEFAULT_UX10_PREFERENCES);
  });

  it('persists tee box and bag visual independently', () => {
    const storage = memoryStorage();
    saveUx10PresentationPreferences({ teeBoxThemeId: 'cliffs', bagVisualId: 'tour' }, storage);
    expect(loadUx10PresentationPreferences(storage)).toEqual({ teeBoxThemeId: 'cliffs', bagVisualId: 'tour' });
    saveUx10PresentationPreferences({ teeBoxThemeId: 'coastal', bagVisualId: 'tour' }, storage);
    expect(loadUx10PresentationPreferences(storage).bagVisualId).toBe('tour');
  });
});
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `cd portal && pnpm vitest run src/__tests__/ux10Personalization.test.ts`

Expected: FAIL because `../ux10/personalization` does not exist.

- [ ] **Step 3: Implement the minimal preference model**

```ts
export type TeeBoxThemeId = 'coastal' | 'cliffs';
export type BagVisualId = 'tour' | 'stand';
export type Ux10PresentationPreferences = { teeBoxThemeId: TeeBoxThemeId; bagVisualId: BagVisualId };
export type Ux10Storage = Pick<Storage, 'getItem' | 'setItem'>;

export const UX10_TEE_BOX_THEMES = [
  { id: 'coastal' as const, label: 'Spyglass-inspired Coastal', src: '/portal/ux10/tee-boxes/coastal-01.webp' },
  { id: 'cliffs' as const, label: 'Torrey-inspired Cliffs', src: '/portal/ux10/tee-boxes/cliffs-01.webp' },
];

export const UX10_BAG_VISUALS = [
  { id: 'tour' as const, label: 'GAL Tour Bag', src: '/portal/ux10/bags/gal-tour-bag.png' },
  { id: 'stand' as const, label: 'GAL Stand Bag', src: '/portal/ux10/bags/gal-stand-bag.png' },
];

export const DEFAULT_UX10_PREFERENCES: Ux10PresentationPreferences = { teeBoxThemeId: 'coastal', bagVisualId: 'tour' };
const STORAGE_KEY = 'gal.ux10.presentation';

export function loadUx10PresentationPreferences(storage?: Ux10Storage): Ux10PresentationPreferences {
  const source = storage ?? (typeof window === 'undefined' ? undefined : window.localStorage);
  if (!source) return DEFAULT_UX10_PREFERENCES;
  try {
    const parsed = JSON.parse(source.getItem(STORAGE_KEY) ?? '{}') as Partial<Ux10PresentationPreferences>;
    return {
      teeBoxThemeId: UX10_TEE_BOX_THEMES.some((item) => item.id === parsed.teeBoxThemeId) ? parsed.teeBoxThemeId! : 'coastal',
      bagVisualId: UX10_BAG_VISUALS.some((item) => item.id === parsed.bagVisualId) ? parsed.bagVisualId! : 'tour',
    };
  } catch {
    return DEFAULT_UX10_PREFERENCES;
  }
}

export function saveUx10PresentationPreferences(preferences: Ux10PresentationPreferences, storage?: Ux10Storage): void {
  const target = storage ?? (typeof window === 'undefined' ? undefined : window.localStorage);
  target?.setItem(STORAGE_KEY, JSON.stringify(preferences));
}
```

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `cd portal && pnpm vitest run src/__tests__/ux10Personalization.test.ts`

Expected: PASS.

- [ ] **Step 5: Replace UX5 authority tests with UX10 authority tests**

The new integration test must assert `GAL_UX_MANIFEST.json` contains `GAL-UX10.01`, the candidate is `GAL-UX10.01-RC1`, main contains `data-ux-version="GAL-UX10.01-RC1"`, and active source contains no `/portal/ux5/reference-bag.webp`.

- [ ] **Step 6: Commit**

Commit message: `test: establish GAL UX10.01 presentation isolation contract`

---

### Task 2: Build the independent tee-box + bag scene renderer and interaction binder

**Files:**
- Create: `portal/src/ux10/scene.ts`
- Create: `portal/src/ux10/bind.ts`
- Delete after migration: `portal/src/ux5/bagEnvironment.ts`
- Test: `portal/src/__tests__/ux10Personalization.test.ts`

**Interfaces:**
- `renderUx10BagEnvironment(options: Ux10BagEnvironmentOptions): string`
- `bindUx10Personalization(root?: ParentNode): void`
- `Ux10BagCategory` retains keys `driver | fairway | hybrid | irons | wedges | putter | ball` and governed statuses `NEEDS_ATTENTION | GOOD | WATCHING | NOT_EVALUATED`.

- [ ] **Step 1: Add failing DOM-contract source tests**

Assert the scene source contains separate elements/classes `ux10-tee-box-background` and `ux10-bag-image`, separate `data-tee-box-theme-id` and `data-bag-visual-id` controls, and does not contain `reference-bag.webp`.

- [ ] **Step 2: Verify RED**

Run: `cd portal && pnpm vitest run src/__tests__/ux10Personalization.test.ts`

Expected: FAIL because scene/binder do not exist.

- [ ] **Step 3: Implement the renderer**

The renderer reads `loadUx10PresentationPreferences()`, resolves the selected catalog entries, and emits this hierarchy:

```html
<section class="ux10-bag-environment">
  <img class="ux10-tee-box-background" data-current-tee-box="coastal" src="/portal/ux10/tee-boxes/coastal-01.webp" alt="">
  <div class="ux10-scene-overlay"></div>
  <nav class="ux10-status-rail">…governed category links…</nav>
  <div class="ux10-bag-stage">
    <img class="ux10-bag-image" data-current-bag-visual="tour" src="/portal/ux10/bags/gal-tour-bag.png" alt="Personalized golf bag visual">
    <img class="ux10-bag-brand" src="/portal/gal-option7a-motion.jpg" alt="">
  </div>
  <section class="ux10-tee-box-selector" aria-label="Choose My Tee Box">…theme buttons…</section>
  <section class="ux10-bag-selector" aria-label="Bag Visual">…bag buttons…</section>
</section>
```

- [ ] **Step 4: Implement binder behavior**

`bindUx10Personalization()` attaches click listeners to `[data-tee-box-theme-id]` and `[data-bag-visual-id]`. A tee-box click changes only `.ux10-tee-box-background`, selected tee-box state, and `teeBoxThemeId`; a bag click changes only `.ux10-bag-image`, selected bag state, and `bagVisualId`. Neither handler imports equipment, fitting, insight, recommendation, or analytics modules.

- [ ] **Step 5: Verify GREEN**

Run: `cd portal && pnpm vitest run src/__tests__/ux10Personalization.test.ts`

Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: separate UX10 tee box and bag presentation layers`

---

### Task 3: Move Today and My Bag onto the shared UX10 renderer

**Files:**
- Modify: `portal/src/surfaces/today.ts`
- Modify: `portal/src/bag/render.ts`
- Modify: `portal/src/__tests__/ux10Integrated.test.ts`
- Modify: `portal/src/__tests__/myBagUx.test.ts`
- Modify: `portal/src/__tests__/teeBoxToday.test.ts`

**Interfaces:**
- Both surfaces import `renderUx10BagEnvironment` and `Ux10BagCategory` from `../ux10/scene`.
- Existing `fetchGolferInsights()` and `fetchMyBag()` contracts remain unchanged.

- [ ] **Step 1: Write failing migration assertions**

Assert Today and My Bag import `renderUx10BagEnvironment`, neither imports `../ux5/bagEnvironment`, the Today dashboard contains `Bag Visual`, and My Bag keeps the truthfulness copy separating appearance from equipment truth.

- [ ] **Step 2: Verify RED**

Run: `cd portal && pnpm vitest run src/__tests__/ux10Integrated.test.ts src/__tests__/myBagUx.test.ts src/__tests__/teeBoxToday.test.ts`

- [ ] **Step 3: Migrate Today**

Keep governed category construction and insight behavior. Rename visual classes to UX10 equivalents and add a Bag Visual summary stating that the foreground bag can be changed independently from the selected course.

- [ ] **Step 4: Migrate My Bag**

Keep equipment identity/configuration logic unchanged. Use the same UX10 scene and maintain honest `NOT_EVALUATED/WATCHING` behavior.

- [ ] **Step 5: Verify GREEN**

Run the focused tests above; expected PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: share UX10 personalized scene across Today and My Bag`

---

### Task 4: Align Driver intelligence with the locked five-tab model

**Files:**
- Modify: `portal/src/fitting/driver/render.ts`
- Modify: `portal/src/__tests__/driverFitUx.test.ts`
- Modify: `portal/src/__tests__/ux10Integrated.test.ts`

**Interfaces:**
- Existing target-profile and candidate-ranking functions remain unchanged.
- Adds DOM section `#driver-what-to-do` and tab label `What To Do`.

- [ ] **Step 1: Write failing tab test**

Assert Driver source contains exactly the progressive-disclosure labels `Overview`, `Why It Matters`, `What To Do`, `Recommendations`, `Compare` and a `driver-what-to-do` section.

- [ ] **Step 2: Verify RED**

Run: `cd portal && pnpm vitest run src/__tests__/driverFitUx.test.ts src/__tests__/ux10Integrated.test.ts`

- [ ] **Step 3: Add What To Do**

Insert the tab between Why It Matters and Recommendations. The section copy must remain evidence-safe: `Keep, adjust, test, reconfigure, or replace only when governed evidence supports that action.` No purchase is assumed.

- [ ] **Step 4: Verify GREEN and commit**

Commit message: `feat: add UX10 What To Do driver step`

---

### Task 5: Replace the UX5 presentation layer with UX10 styling and shell versioning

**Files:**
- Create: `portal/src/styles/ux10.css`
- Modify: `portal/src/main.ts`
- Modify: `portal/src/__tests__/candidateVisuals.test.ts`

**Interfaces:**
- Main imports `./styles/ux10.css` and `./ux10/bind`.
- Shell root becomes `class="my-gal-shell ux10-shell" data-ux-version="GAL-UX10.01-RC1"`.

- [ ] **Step 1: Write failing visual-layer tests**

Assert main imports `ux10.css`, does not import `ux5-mid.css`, `ux5-scene.css`, `ux5-driver.css`, or `ux5-polish.css`, and the UX10 stylesheet contains `.ux10-tee-box-background`, `.ux10-bag-stage`, `.ux10-status-rail`, `.ux10-primary-nav`, `.ux10-club-panel`, and mobile `position: fixed; bottom: 0` navigation.

- [ ] **Step 2: Verify RED**

Run: `cd portal && pnpm vitest run src/__tests__/candidateVisuals.test.ts`

- [ ] **Step 3: Implement UX10 visual layer**

Use GAL Navy `#0B245F`, GAL Orange `#FF5A1F`, dark translucent panels, full-bleed hero background, foreground bag depth/shadow, readable scrims, selector chips, 44px minimum targets, responsive two-column desktop composition, and mobile bottom navigation. The bag must remain visually prominent on mobile rather than shrinking into a generic card thumbnail.

- [ ] **Step 4: Bind interactions after route render**

After `routeMount.innerHTML = await routeContent(currentRoute);`, call `bindUx10Personalization(routeMount);` so Today/My Bag selector controls are active.

- [ ] **Step 5: Verify GREEN and commit**

Commit message: `feat: apply locked GAL UX10.01 visual system`

---

### Task 6: Add governed independent visual assets and CI verification

**Files:**
- Create binaries: `portal/public/ux10/tee-boxes/coastal-01.webp`, `portal/public/ux10/tee-boxes/cliffs-01.webp`, `portal/public/ux10/bags/gal-tour-bag.png`, `portal/public/ux10/bags/gal-stand-bag.png`
- Create: `portal/public/ux10/README.md`
- Create: `portal/public/ux10/SHA256SUMS`
- Modify: `.github/workflows/ux-preview-publish.yml`
- Modify: `portal/src/__tests__/candidateVisuals.test.ts`

**Interfaces:**
- Catalog source paths from Task 1 must exactly match these four asset paths.

- [ ] **Step 1: Produce two course-style backgrounds and two separate transparent bag visuals**

Backgrounds contain no bag. Bag files have transparent backgrounds and contain no scenic course layer. Do not embed illustrative golfer metrics or product facts in any image.

- [ ] **Step 2: Generate deterministic checksums**

Run:

```bash
cd portal/public/ux10
sha256sum tee-boxes/coastal-01.webp tee-boxes/cliffs-01.webp bags/gal-tour-bag.png bags/gal-stand-bag.png > SHA256SUMS
```

- [ ] **Step 3: Document provenance and usage**

`README.md` must state that tee-box themes and bag visuals are presentation-only assets, identify their source/generation method, and forbid using them as analytical inputs.

- [ ] **Step 4: Update candidateVisuals test**

Read each asset, verify it exists, verify `SHA256SUMS` contains its digest, verify theme catalog paths are different from bag catalog paths, and verify no active source references `/portal/ux5/reference-bag.webp`.

- [ ] **Step 5: Update preview workflow**

Add branch `feature/gal-ux10-01-tee-box-personalization`, remove the UX5 scene reconstruction step from this branch path, run `sha256sum -c portal/public/ux10/SHA256SUMS`, name the artifact `GAL-UX10.01-RC1-verified-preview`, and publish the four UX10 assets with the verified build.

- [ ] **Step 6: Commit**

Commit message: `assets: govern independent UX10 tee box and bag visuals`

---

### Task 7: Full verification, visual review artifact, and preview publication

**Files:**
- Verify all modified files above.
- Generated review outputs only; no production promotion.

- [ ] **Step 1: Run the full test suite**

Run: `cd portal && pnpm run test:run`

Expected: all tests PASS.

- [ ] **Step 2: Run production build**

Run: `cd portal && pnpm run build`

Expected: TypeScript and Vite build PASS.

- [ ] **Step 3: Run release scans**

Reject `SUPABASE_SERVICE_ROLE_KEY|service_role`, the known mockup sample facts (`94 mph`, `247 yds`, `+12 Yards`, `$3,840`, `78%`, `71%`, `+11.3 yds`), and active references to `/portal/ux5/reference-bag.webp` from browser material.

- [ ] **Step 4: Verify visual behavior at desktop and mobile widths**

Desktop: selected tee-box background fills the hero; bag is a separate foreground asset; changing theme leaves bag unchanged; changing bag leaves background unchanged. Mobile: bottom nav remains viewport-anchored and the hero still preserves Course -> Bag -> Status -> Opportunity.

- [ ] **Step 5: Publish only the review candidate**

Upload/publish `GAL-UX10.01-RC1-verified-preview` from the feature branch. Do not merge/promote to production.

- [ ] **Step 6: Commit any verification-only workflow fixes and re-run from a clean commit**

Final evidence must come from the current branch head, not an earlier passing commit.
