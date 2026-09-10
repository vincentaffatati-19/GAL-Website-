# Driver Image v2 Integration Plan

> **For GAL:** Implement against `feature/driver-image-v2-integration`, based on `codex/ux10-02-step17-18-integrated-rc`. Do not modify `main` directly.

**Goal:** Integrate the approved Driver Image Governance v2.0 master into the GAL Driver experience with one canonical image contract, controlled holds, responsive delivery, catalog/detail/compare/bag parity, and regression verification.

**Architecture:** Keep the governed Driver records as one static data module. Add one media resolver that is the only rendering path for Driver imagery. Approved records resolve to their versioned Cloudinary WebP master plus responsive delivery URLs; hold records resolve to a controlled `image coming soon` state and never fall back to legacy or unrelated images. The Driver page consumes the same record/resolver for catalog cards, detail view, compare, and bag. Bag persistence uses canonical Driver IDs so future authenticated/profile integration can replace storage without changing image identity.

**Base:** `codex/ux10-02-step17-18-integrated-rc` (`ebbbf7e173f873a7123a5398378f05492e9f0d28`)

---

## Task 1 — Contract tests (RED)

**Files:**
- Create: `tests/driver-image-v2-integration.test.mjs`

Verify the desired contract before implementation:
- 64 canonical Driver records.
- 54 `VERIFIED_REVIEW_ASSET` records and 10 governed holds.
- Approved records expose unique, versioned Cloudinary WebP master URLs.
- Holds expose no production image URL.
- Media resolver never falls back to legacy/candidate imagery.
- Catalog/detail/compare/bag render helpers all consume the same resolver.
- Responsive URLs preserve the versioned public ID while requesting smaller delivery widths.

Run locally and confirm failure because the Driver data/media modules do not yet exist.

## Task 2 — Canonical Driver data + media resolver (GREEN)

**Files:**
- Create: `drivers__data.js`
- Create: `drivers__media.js`

Generate `drivers__data.js` from the approved v2.0 governance master without changing non-image Driver fields. Implement `GALDriverMedia.resolve(record, width)` and `GALDriverMedia.picture(record)` so:
- approved records return governed image metadata and a responsive Cloudinary URL;
- hold records return an explicit unavailable state with reason/status;
- no legacy, source-candidate, or guessed fallback is permitted.

Re-run the contract test.

## Task 3 — Driver equipment experience

**Files:**
- Modify: `drivers.html`
- Create: `drivers__app.js`
- Create: `drivers__styles.css`

Replace the foundation-only Driver page with a governed equipment browser:
- search + brand filters;
- responsive catalog cards;
- controlled hold placeholder;
- product detail drawer/dialog;
- compare up to three Drivers;
- Add to Bag / Remove from Bag with canonical ID persistence;
- 14-club warning behavior for the shared local bag representation;
- duplicate Driver warning by canonical ID;
- same governed image resolver in every surface.

Preserve GAL locked brand colors and current header/footer/navigation.

## Task 4 — Integration regression checks

**Files:**
- Extend: `tests/driver-image-v2-integration.test.mjs`

Verify:
- page loads all Driver modules;
- no direct image URL rendering exists in Driver app outside the media resolver;
- catalog/detail/compare/bag render through the canonical resolver;
- hold records cannot render an `<img>`;
- approved records use responsive Cloudinary delivery;
- no duplicate canonical IDs;
- existing `site.js` and global GAL navigation remain referenced.

Run the full Driver integration test and syntax checks.

## Task 5 — Release candidate handoff

**Files:**
- Create: `docs/driver-images/GAL-DRIVER-IMAGE-V2-INTEGRATION-QA.md`

Record base branch/commit, governed master version, counts, test output, known 10 image holds, and release status. Open a PR from `feature/driver-image-v2-integration` back to the September integrated RC for staging review. Do not promote to `main` until the normal GAL staging/release gate is completed.