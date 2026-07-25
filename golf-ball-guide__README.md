# Golf Ball Buyers Guide

GitHub Pages-ready static app for the Golf Analytics Lab **Build a Better Bag — Golf Ball Buyers Guide**.

## Source database

Built from the uploaded spreadsheet:

`golf_ball_brand_matrix.xlsx`

Converted records: **77 golf balls**

## Publish on GitHub Pages

1. Create a new GitHub repository.
2. Upload all files in this ZIP to the root of the repository.
3. Go to **Settings → Pages**.
4. Set **Source** to **Deploy from a branch**.
5. Set **Branch** to `main` and folder to `/root`.
6. Save.
7. Open the published GitHub Pages link after deployment completes.

## Scoring model

This rebuild uses value-weighted fit scoring:

- Compression fit: 30%
- Feel: 15%
- Cover: 15%
- Construction: 10%
- Cost/value: 30%

Cost affects the score even when the golfer chooses “No preference” for budget.


## Theme update

The application background has been changed to navy blue: `#071a33`.


## Font color update

Navy-background areas now use light text, while white panels/cards/tables use dark text.


## Logo and theme update

- Header logo updated to use the uploaded company artwork: `assets/golf-ball-guide__golf_analytics_lab_logo.png`
- Application navy background updated to match the logo tone: `#011734`


## Logo path update

The app now uses the logo from the repository root:

`golf-ball-guide__golf_analytics_lab_logo.png`

No `assets` folder is required.


## Mobile-compatible version

This version adds:

- Phone-first responsive layout
- Sticky mobile "Show filters" button
- Larger tap targets
- Single-column results on phones
- Hidden comparison table on phones for cleaner scrolling
- Logo and navy theme retained
- Root-level logo file, so no assets folder is required


## Mobile usability update

The sticky mobile filter button now says `Find Your Fit` when closed and `Hide Fit` when open.


## Database refresh

Database refreshed: 2026-07-09

- Source workbook: `golf-ball-guide__golf_ball_database_current_verified.xlsx`
- Records in app database: 77
- Added link audit and source notes
- Updated `golf-ball-guide__data.js` with current source URLs, pricing where verified, and confidence notes


## Production/origin database update

This version adds production and origin information:

- Manufacturing Country
- Production Location
- Design Origin
- Company / Brand Origin
- Production Notes
- Production Confidence
- Production Source URL

Important: golf-ball country of origin is often SKU/package specific. Use the confidence field to distinguish verified brand-level production facts from rows that need package confirmation.
