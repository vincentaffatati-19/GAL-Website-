# GAL UX10 — Shared Header and Brand Amendment

**Status:** USER-APPROVED / LOCKED  
**Date:** 2026-09-05  
**Applies to:** `GAL-UX10.02` and all later UX10 revisions unless explicitly replaced

## Decision

Every UX10 screen, route, modal/focused workspace, dashboard, Golfer Profile screen, guide, insight, progress view, My Bag view, and fitting/intelligence view must use one shared GAL header implementation.

## Brand authority

The header must use the locked **Stylized Option B: Motion Arc — built on Option 7A GAL Custom Hybrid** brand system.

Active dark lockup:

`/portal/gal-motion-arc-dark-lockup.webp`

SHA-256:

`8cd2030c7b3f4e75a9474dbd3e9f27e6697ce89ea756f22a5c4749192c117636`

Older Option 7A-only marks, generated approximations, alternate logo systems, and page-specific logo substitutions are retired from active UX10 use.

This amendment supersedes any older UX10.02 specification text that refers to Option 7A alone as the active brand system.

## Shared header contract

The shared header must preserve:

- the locked Motion Arc logo;
- product identity `My GAL` / `Your Equipment Intelligence Center` where space permits;
- primary navigation `Today | My Bag | Insights | Guides | Progress`;
- separate `Golfer Profile` access;
- consistent active-route treatment;
- consistent accessibility labels and focus behavior;
- responsive/mobile adaptation without changing the brand or navigation model.

Individual route/screen implementations must not contain their own substitute GAL header markup. Future header changes are made once in the shared header component and propagate everywhere.

## Review rule

Any material future change to the shared header is its own review step and must be previewed and explicitly approved before the next UX step proceeds.
