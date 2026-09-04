import { escapeHtml } from '../render/escape';

export type Ux5BagStatus = 'NEEDS_ATTENTION' | 'GOOD' | 'WATCHING' | 'NOT_EVALUATED';

export type Ux5BagCategory = {
  key: 'driver' | 'fairway' | 'hybrid' | 'irons' | 'wedges' | 'putter' | 'ball';
  label: string;
  status: Ux5BagStatus;
  detail: string;
  href: string;
};

export type Ux5BagEnvironmentOptions = {
  categories: Ux5BagCategory[];
  contextLabel: string;
};

const STATUS_LABEL: Record<Ux5BagStatus, string> = {
  NEEDS_ATTENTION: 'Needs Attention',
  GOOD: 'Good',
  WATCHING: 'Watching',
  NOT_EVALUATED: 'Not evaluated',
};

const UX5_BAG_SCENE_SRC = '/portal/ux5/reference-bag.webp';

export function renderUx5BagEnvironment(options: Ux5BagEnvironmentOptions): string {
  const categories = options.categories.map((category) => `
    <a class="ux5-status-item" data-bag-category="${escapeHtml(category.key)}" data-status="${escapeHtml(category.status)}" href="${escapeHtml(category.href)}" aria-label="${escapeHtml(`${category.label}: ${STATUS_LABEL[category.status]}`)}">
      <span><strong>${escapeHtml(category.label)}</strong><small>${escapeHtml(category.detail)}</small></span>
      <b aria-hidden="true">${escapeHtml(STATUS_LABEL[category.status])}</b>
    </a>`).join('');

  return `
    <section class="ux5-bag-environment" aria-label="${escapeHtml(options.contextLabel)}">
      <div class="ux5-bag-scene-actions">
        <button type="button" class="ux5-scene-button" aria-label="Choose My Tee Box">Choose My Tee Box</button>
      </div>
      <div class="ux5-bag-environment-grid">
        <nav class="ux5-status-rail" aria-label="Equipment category status">
          ${categories}
        </nav>
        <div class="ux5-bag-visual" aria-label="My GAL bag environment">
          <figure class="ux5-bag-photo-frame" aria-label="Illustrative GAL bag scene">
            <img class="ux5-bag-photo" src="${UX5_BAG_SCENE_SRC}" alt="" aria-hidden="true" loading="eager" decoding="async">
          </figure>
          <small class="ux5-scene-disclaimer">Illustrative scene · equipment status comes from your governed My Bag data.</small>
          <a class="ux5-customize-bag" href="/portal/bag#customize">Customize My Bag</a>
        </div>
      </div>
    </section>`;
}
