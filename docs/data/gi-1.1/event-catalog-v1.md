# GAL GI-1.1 Event Catalog — EVENT-1.0

**Status:** Development  
**Schema family:** GI-1.1  
**Catalog version:** EVENT-1.0  
**Governing rule:** **Behavior is evidence, not automatically truth.**

## Purpose

`gal_event_catalog` is the semantic authority for behavioral events written to the canonical `gal_buyer_events` stream. GAL does not create a second generic behavior table.

An event definition states what an event means, how strong a signal it is, whether it is relevant to personalization, whether it may support governed aggregate analytics, and how long the event class should generally be retained. Event observations do **not** write profile facts directly. Any behavioral inference must pass through a governed inference model with evidence, confidence, and model provenance.

## Governed metadata

Each active event definition includes:

- `event_key` + `event_version`
- domain, object type, and action
- human-readable description
- signal class
- profile relevance
- operational class
- commercial class
- retention class
- active/status flags

### Signal classes

- `NAVIGATION` — movement through a surface; weak evidence by itself.
- `ENGAGEMENT` — deliberate interaction, still generally weak-to-moderate evidence.
- `INTENT` — explicit consideration behavior.
- `COMMITMENT` — completion/save behavior showing stronger intent.
- `OUTCOME` — reported or authoritative downstream outcome.

### Profile relevance

`NONE`, `LOW`, `MEDIUM`, `HIGH` indicates whether the event may be useful evidence for future personalization or inference. It does not authorize direct fact creation.

### Commercial classes

- `PERSONAL_ONLY`
- `AGGREGATE_ELIGIBLE`
- `RESTRICTED_AGGREGATE`
- `EXCLUDED`

Aggregate eligibility remains subject to consent, cohort privacy floors, and the customer-portal boundary.

## EVENT-1.0 vocabulary

| Event key | Signal | Profile relevance | Meaning |
|---|---|---:|---|
| `guide.started` | ENGAGEMENT | LOW | Golfer starts a governed Buyer’s Guide/fitting workflow. |
| `guide.completed` | COMMITMENT | MEDIUM | Golfer completes a governed guide/fitting workflow. |
| `guide.question.answered` | ENGAGEMENT | MEDIUM | A governed question response is submitted. |
| `recommendation.run.started` | INTENT | MEDIUM | Deterministic recommendation execution begins. |
| `recommendation.run.completed` | COMMITMENT | MEDIUM | Deterministic recommendation execution completes. |
| `recommendation.viewed` | ENGAGEMENT | LOW | Golfer views a recommendation. |
| `recommendation.saved` | INTENT | HIGH | Golfer explicitly saves a recommendation. |
| `product.viewed` | ENGAGEMENT | LOW | Golfer views a product. |
| `product.compared` | INTENT | MEDIUM | Golfer explicitly compares a product. |
| `bag.item.added` | OUTCOME | HIGH | Equipment is added to the authoritative bag. |
| `bag.item.replaced` | OUTCOME | HIGH | Equipment is replaced in the authoritative bag. |
| `scenario.created` | INTENT | MEDIUM | Golfer creates a what-if bag scenario. |
| `scenario.adopted` | OUTCOME | HIGH | Golfer explicitly adopts a bag scenario. |
| `commerce.route.clicked` | INTENT | LOW | Golfer follows a GAL commerce route. |
| `purchase.reported` | OUTCOME | HIGH | Golfer explicitly reports a purchase; purchase alone is not bag ownership. |
| `equipment.adopted` | OUTCOME | HIGH | Equipment adoption is explicitly confirmed or established by authoritative bag state. |
| `recommendation.feedback.submitted` | OUTCOME | HIGH | Golfer supplies explicit recommendation/outcome feedback. |

## Interpretation safeguards

1. A product view does not create a brand-preference fact.
2. Repeated comparison activity may become evidence for a governed inference, never silent truth.
3. Affiliate/commerce clicks do not establish purchase or ownership.
4. A reported purchase does not automatically change Jerry’s Bag.
5. Authoritative bag adoption is a stronger outcome signal than a commerce click.
6. Recommendation outcome/feedback is more valuable long-term validation evidence than raw click volume.
7. New event keys or versions require a reviewed catalog migration before production use.

## Governance

Browser roles cannot create, rewrite, or delete Event Catalog semantics. Definitions are system-governed and versioned. Buyer-event RLS and append-only behavior are governed separately in the next Longitudinal Intelligence task.
