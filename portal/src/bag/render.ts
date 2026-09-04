import { escapeHtml } from '../render/escape';
import type { EquipmentCategory } from '../equipment/types';
import { fetchMyBag } from './client';
import type { BagEquipmentView } from './model';

const CATEGORY_ORDER: EquipmentCategory[] = ['DRIVER','FAIRWAY_WOOD','HYBRID','IRON','WEDGE','PUTTER','GOLF_BALL'];
const CATEGORY_LABELS: Record<EquipmentCategory,string> = {
  DRIVER:'Driver', FAIRWAY_WOOD:'Fairway Woods', HYBRID:'Hybrids', IRON:'Irons', WEDGE:'Wedges', PUTTER:'Putter', GOLF_BALL:'Ball',
};

function categoryTarget(category: EquipmentCategory, item?: BagEquipmentView): string {
  const label = CATEGORY_LABELS[category];
  const known = Boolean(item);
  const detail = !item
    ? 'Not in your recorded bag'
    : item.state === 'KNOWN'
      ? item.configuration?.name ?? 'Configuration linked'
      : 'Configuration details needed';
  const href = item?.fittingHref ?? '#bag-details';
  return `<a class="bag-category-target bag-category-${category.toLowerCase()}${known ? ' is-present' : ''}" href="${escapeHtml(href)}"><strong>${escapeHtml(label)}</strong><small>${escapeHtml(detail)}</small></a>`;
}

function equipmentDetail(item: BagEquipmentView): string {
  const config = item.state === 'KNOWN'
    ? item.configuration ? `Configuration: ${escapeHtml(item.configuration.name)}` : 'Configuration linked to GAL Equipment Knowledge.'
    : 'Configuration details needed';
  return `<article class="bag-detail-card"><p class="eyebrow">${escapeHtml(CATEGORY_LABELS[item.category])}</p><h3>${escapeHtml(item.equipmentName)}</h3><p>${config}</p>${item.fittingHref ? `<a class="button" href="${escapeHtml(item.fittingHref)}">${item.state === 'KNOWN' ? 'Open Driver Fit' : 'Complete Driver Details'}</a>` : ''}</article>`;
}

export async function renderMyBag(): Promise<string> {
  try {
    const items = await fetchMyBag();
    const byCategory = new Map<EquipmentCategory, BagEquipmentView>(items.map((item) => [item.category, item]));

    return `<section class="my-bag-experience">
      <header class="my-bag-heading"><div><p class="eyebrow">My Bag</p><h2>Your equipment, as GAL currently knows it.</h2><p>Select a category to see what is known, what still needs details, and where governed equipment intelligence can help. Missing information is not treated as a good fit.</p></div><a class="bag-guide-link" href="#bag-guide">How My Bag Works</a></header>
      <section class="my-bag-hero" aria-label="My Bag equipment visualization">
        <div class="my-bag-course" aria-hidden="true"></div>
        <div class="my-bag-stage">
          ${CATEGORY_ORDER.map((category) => categoryTarget(category, byCategory.get(category))).join('')}
          <div class="bag-hero bag-hero-detail" role="img" aria-label="GAL golf bag visualization"><div class="bag-clubs" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></div><div class="bag-body"><span class="bag-gal-mark">GAL</span><span>MY BAG</span></div><div class="bag-base" aria-hidden="true"></div></div>
        </div>
      </section>
      <section class="bag-detail-grid" id="bag-details" aria-label="Recorded equipment details">
        ${items.length ? items.map(equipmentDetail).join('') : '<article class="bag-detail-card bag-empty"><h3>Build your bag</h3><p>Add equipment so GAL can connect your bag to governed equipment intelligence.</p></article>'}
      </section>
      <section class="my-gal-state" id="bag-guide"><p class="eyebrow">Bag User’s Guide</p><h2>How My Bag Works</h2><p>Known equipment and configuration details come from your bag and governed GAL Equipment Knowledge. “Not evaluated” or missing configuration means GAL needs more evidence; it does not mean the club is optimized. Driver fitting uses the same equipment truth and shows characteristics before brands.</p></section>
    </section>`;
  } catch (error) {
    const message = error instanceof Error && error.message === 'AUTH_REQUIRED' ? 'Sign in to view My Bag.' : 'My Bag is temporarily unavailable.';
    return `<section class="my-gal-state"><h2>${message}</h2></section>`;
  }
}
