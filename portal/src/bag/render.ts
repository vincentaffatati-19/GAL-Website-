import { escapeHtml } from '../render/escape';
import type { EquipmentCategory } from '../equipment/types';
import { renderUx5BagEnvironment, type Ux5BagCategory } from '../ux5/bagEnvironment';
import { fetchMyBag } from './client';
import type { BagEquipmentView } from './model';

const CATEGORY_ORDER: EquipmentCategory[] = ['DRIVER', 'FAIRWAY_WOOD', 'HYBRID', 'IRON', 'WEDGE', 'PUTTER', 'GOLF_BALL'];
const CATEGORY_LABELS: Record<EquipmentCategory, string> = {
  DRIVER: 'Driver', FAIRWAY_WOOD: 'Fairway Woods', HYBRID: 'Hybrids', IRON: 'Irons', WEDGE: 'Wedges', PUTTER: 'Putter', GOLF_BALL: 'Ball',
};
const UX5_KEYS: Record<EquipmentCategory, Ux5BagCategory['key']> = {
  DRIVER: 'driver', FAIRWAY_WOOD: 'fairway', HYBRID: 'hybrid', IRON: 'irons', WEDGE: 'wedges', PUTTER: 'putter', GOLF_BALL: 'ball',
};

function bagCategory(category: EquipmentCategory, item?: BagEquipmentView): Ux5BagCategory {
  const label = CATEGORY_LABELS[category];
  if (!item) {
    return {
      key: UX5_KEYS[category],
      label,
      status: 'NOT_EVALUATED',
      detail: 'GAL needs more information',
      href: '#bag-details',
    };
  }

  const hasConfiguration = item.state === 'KNOWN';
  return {
    key: UX5_KEYS[category],
    label,
    status: hasConfiguration ? 'WATCHING' : 'NOT_EVALUATED',
    detail: hasConfiguration
      ? item.configuration?.name ?? 'Equipment configuration known; fit not yet claimed'
      : 'Configuration details needed',
    href: item.fittingHref ?? '#bag-details',
  };
}

function equipmentDetail(item: BagEquipmentView): string {
  const config = item.state === 'KNOWN'
    ? item.configuration ? `Configuration: ${escapeHtml(item.configuration.name)}` : 'Configuration linked to GAL Equipment Knowledge.'
    : 'Configuration details needed';
  return `<article class="bag-detail-card ux5-panel"><p class="eyebrow">${escapeHtml(CATEGORY_LABELS[item.category])}</p><h3>${escapeHtml(item.equipmentName)}</h3><p>${config}</p><p class="ux5-fit-caution">Equipment identity alone does not prove fit.</p>${item.fittingHref ? `<a class="button" href="${escapeHtml(item.fittingHref)}">${item.state === 'KNOWN' ? 'Open Driver Fit' : 'Complete Driver Details'}</a>` : ''}</article>`;
}

export async function renderMyBag(): Promise<string> {
  try {
    const items = await fetchMyBag();
    const byCategory = new Map<EquipmentCategory, BagEquipmentView>(items.map((item) => [item.category, item]));
    const categories = CATEGORY_ORDER.map((category) => bagCategory(category, byCategory.get(category)));
    const environment = renderUx5BagEnvironment({ categories, contextLabel: 'My Bag equipment environment' });

    return `<section class="my-bag-experience ux5-my-bag">
      <header class="my-bag-heading ux5-section-heading"><div><p class="eyebrow">My Bag</p><h2>Your equipment, as GAL currently knows it.</h2><p>Select a category to see what is known, what still needs details, and where governed equipment intelligence can help. Missing information is not treated as a good fit.</p></div><a class="bag-guide-link" href="#bag-guide">How My Bag Works</a></header>
      <div class="ux5-bag-environment-slot">${environment}</div>
      <section class="bag-detail-grid ux5-bag-details" id="bag-details" aria-label="Recorded equipment details">
        ${items.length ? items.map(equipmentDetail).join('') : '<article class="bag-detail-card bag-empty ux5-panel"><h3>Build your bag</h3><p>Add equipment so GAL can connect your bag to governed equipment intelligence.</p></article>'}
      </section>
      <section class="my-gal-state ux5-panel" id="customize"><p class="eyebrow">Customize My Bag</p><h2>Presentation preferences stay separate from equipment truth.</h2><p>Bag appearance can be personalized without changing what GAL knows about your equipment or fit.</p></section>
      <section class="my-gal-state ux5-panel" id="bag-guide"><p class="eyebrow">Bag User’s Guide</p><h2>How My Bag Works</h2><p>Known equipment and configuration details come from your bag and governed GAL Equipment Knowledge. “Not evaluated” or missing configuration means GAL needs more evidence; it does not mean the club is optimized. Driver fitting uses the same equipment truth and shows characteristics before brands.</p></section>
    </section>`;
  } catch (error) {
    const message = error instanceof Error && error.message === 'AUTH_REQUIRED' ? 'Sign in to view My Bag.' : 'My Bag is temporarily unavailable.';
    return `<section class="my-gal-state"><h2>${message}</h2></section>`;
  }
}
