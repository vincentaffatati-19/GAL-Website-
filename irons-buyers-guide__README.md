# GAL Irons Buyers Guide v3.1 — Backbone Bridge

The Irons Buyers Guide UI and scoring remain v3.1.

Data ownership changed in GAL-SITE-3.1.2:
- `irons-buyers-guide__data.js` is generated from the private GAL Data Backbone.
- `irons-buyers-guide__commerce.js` is generated from the GAL Commerce Router registry.
- Retailer URLs must not be hardcoded into `irons-buyers-guide__app.js`.
- Manufacturer product/source pages do not count as verified purchase paths unless the Commerce Router record explicitly permits publication.

The unanswered budget state is price-neutral until Question 6 is selected.
