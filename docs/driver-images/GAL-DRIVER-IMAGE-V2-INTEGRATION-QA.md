# GAL Driver Image v2 Integration — QA Handoff

**Date:** 2026-09-09  
**Status:** CODE + RUNTIME CONTRACT PASS; VERCEL PREVIEW READY; PROTECTED BROWSER ACCEPTANCE PENDING STAGING REVIEW  
**Feature branch:** `feature/driver-image-v2-integration`  
**Base:** `codex/ux10-02-step17-18-integrated-rc` @ `ebbbf7e173f873a7123a5398378f05492e9f0d28`  
**Governed source:** Driver Image Governance v2.0 FINAL

## Integrated scope

- Preserves **64** canonical Driver records.
- Uses **54** `VERIFIED_REVIEW_ASSET` images as the only production-eligible Driver imagery.
- Preserves **10** explicit image holds with no guessed, legacy, candidate, or unrelated fallback image.
- Adds a single governed Driver media resolver used by:
  - catalog
  - detail
  - compare
  - bag
- Responsive Cloudinary delivery requests 320/640/960 px derivatives from the versioned 1200×1200 WebP master without changing canonical asset identity.
- Replaces the foundation-only `drivers.html` page with a responsive Driver equipment browser.
- Adds search, brand/profile/image-state filters, detail dialog, compare up to three Drivers, Add/Remove from Bag, duplicate Driver warning, and 14-club guard.
- Missing price values remain unavailable (`—`) and are not coerced to `$0`.

## Bag/profile boundary

The September Step 17/18 integrated repository does not contain the standalone staging profile candidate as a reusable frontend module. The Driver experience therefore uses a small adapter boundary:

- if `window.GALBagAdapter.load/save` exists, Driver bag operations use it;
- otherwise the review candidate uses `localStorage` key `gal_equipment_bag_v1`.

Canonical Driver IDs are persisted so the authenticated profile adapter can replace the fallback store without remapping image identity.

## Governed image holds

1. GAL-DRV-0029 — Mizuno JPX ONE Select — source quality below 850 px floor.
2. GAL-DRV-0048 — Takomo IGNIS D1 — no defensible current OEM image source.
3. GAL-DRV-0056 — ONOFF XCBT Driver AKA — source quality below 850 px floor.
4. GAL-DRV-0058 — PRGR RS Driver — source quality below 850 px floor.
5. GAL-DRV-0059 — PRGR RS SPEED Driver — source quality below 850 px floor.
6. GAL-DRV-0061 — LA Golf Face ID 13-12 — exact OEM source verified; remote binary ingest blocked.
7. GAL-DRV-0062 — LA Golf Face ID 12-11 — exact OEM source verified; remote binary ingest blocked.
8. GAL-DRV-0063 — LA Golf Face ID 10-10 — exact OEM source verified; remote binary ingest blocked.
9. GAL-DRV-0064 — LA Golf Face ID 9-9 — exact OEM source verified; remote binary ingest blocked.
10. GAL-DRV-0065 — LA Golf Face ID 8-7 — exact OEM source verified; remote binary ingest blocked.

## TDD / contract verification

A failing contract was created before the Driver data/media modules existed. It failed with the expected missing-module error, then passed after implementation.

A second UI contract failed before the Driver page/app/styles existed, then passed after implementation.

A price regression test was added before the formatter fix. It failed because blank prices were coerced to `$0`, then passed after the null/empty guard was added.

### Fresh final local verification

```text
PASS driver image v2 data/media contract
PASS driver equipment UI contract
PASS driver image v2 runtime contract
```

Additional syntax checks:

```text
node --check drivers__app.js   PASS
node --check drivers__data.js  PASS
node --check drivers__media.js PASS
```

Runtime contract verifies:

- 64 catalog cards render.
- exactly 54 catalog images render.
- exactly 10 controlled `Image coming soon` states render.
- second Driver in a bag emits `DUPLICATE_DRIVER` warning.
- a 15th club is blocked by the 14-club guard.

## Repository preservation verification

Feature branch is a clean fast-forward descendant of the September integrated RC. It does not modify Supabase migrations, profile/location contracts, global site JS, or unrelated Buyer Guide files.

## Vercel preview evidence

Connected project: `gal-website` (`prj_42qpNLd0D8npq4hgm3WSOpyuhYBd`)  
Latest verified feature deployment: `dpl_4EHU8cqc9H9T4Yh4NpRSPkX5wrHS`  
Git commit: `f0456dfc3a872da59344517ef3c25301f7bfd8b5`  
State: **READY**  
Build errors-only log: no errors; `Build Completed in /vercel/output`.

The preview is protected by Vercel SSO. The available automated fetch/browser channels receive the authentication redirect rather than the application page, so a full protected-preview visual interaction pass cannot be truthfully marked PASS from this environment. This is an access boundary, not a build failure.

## Release disposition

**Ready for staging PR/review. Not promoted to production.**

Production promotion remains subject to the GAL release path: integrated RC → protected preview/staging visual acceptance → production approval/promotion.
