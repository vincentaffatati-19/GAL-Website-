# GAL UX10.02 — Toptracer Connected Golf Amendment

**Status:** USER-APPROVED / LOCKED  
**Date:** 2026-09-05  
**Applies to:** GAL-UX10.02 Connected Golf and future integration roadmap

## Decision

Toptracer / Topgolf is a Tier-1 strategic Connected Golf integration target for Golf Analytics Lab.

GAL will treat Toptracer as a partnership/API-access integration target rather than an assumed public/self-service API. Until technical, commercial, privacy, trademark, and data-retention rights are confirmed, the product must not present Toptracer as actively connected or imply that GAL has access to a golfer's Toptracer/Topgolf data.

## Intended golfer value

Where authorized access becomes available, GAL should ingest only fields actually supplied by Toptracer and preserve source, observation/session date, freshness, and data-quality state. Potentially useful source data may include ball speed, carry/distance, launch, curve/shot shape, peak height, hang time, and other confirmed shot/session fields.

GAL must not assume Toptracer supplies clubhead speed, attack angle, club path, face angle, or strike location unless the actual integration contract/schema confirms those fields.

## Downstream use

Authorized Toptracer data may update governed golfer-profile facts and then be reused in Your Swing, Your Miss, Buyers Guides, fitting logic, Insights, and future recommendations under the Tell GAL Once model.

Source observations remain distinct from later derived or representative profile facts.

## Connected Golf presentation

Before access exists, display Toptracer only as a strategic/partnership target using language such as `Partnership/API access required`, `Not available`, or equivalent truthful state. Do not show `Connect` or `Connected` unless GAL has a valid supported integration state.

## Integration priority

Tier-1 strategic targets include Toptracer / Topgolf, TrackMan, and GHIN. Arccos and Garmin Golf remain important additional Connected Golf targets, with manual/other launch-monitor import providing broader compatibility.
