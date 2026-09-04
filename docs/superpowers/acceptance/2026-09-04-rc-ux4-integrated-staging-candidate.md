# RC-UX4 — Integrated Staging Candidate

Date: 2026-09-04
Status: REVIEW CANDIDATE — PRODUCTION NOT PROMOTED

## Scope

RC-UX4 reconciles the locked My GAL UX into one candidate: Today / tee-box experience, graphical Golfer Profile and Connect Your Golf, My Bag, Driver AI Fitting, Guides, Insights, Progress, and registered/subscriber entitlement invariants.

## Locked UX invariants

- Primary navigation remains Today | My Bag | Insights | Guides | Progress.
- Golfer Profile remains directly accessible without replacing the five-part primary navigation.
- Golfer Profile includes Build Your GAL Golfer, Tell GAL Once / Connect It Once, the five approved profile areas, graphical measurements/miss concepts, provenance/freshness, and Connect Your Golf.
- My Bag uses the approved bag-first visual language and never treats missing evidence as a good fit.
- Driver fitting preserves Characteristics Before Brands and the locked progressive mobile flow.
- Registered and subscriber experiences use the same analytical truth and component contracts; entitlements are additive and do not change candidate ordering.
- No fabricated Bag Score, fit confidence, yardage gain, valuation, or optimization claim.

## Verification

- RC-UX4 integrated contract test added and passed.
- Portal unit test suite passed.
- TypeScript compile passed.
- Vite production build passed.
- Browser build service-role scan passed.
- Verified portal artifact published.
- Preview publisher uses the staging Supabase project with a browser-safe publishable key only.
- No production database or production deployment change is authorized by this candidate.

## Release boundary

This candidate is for user visual review and staging acceptance. Production promotion remains a separate explicit gate after review, staging smoke testing, and final code review.
