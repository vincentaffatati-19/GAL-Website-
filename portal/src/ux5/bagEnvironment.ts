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
        <div class="ux5-bag-visual" role="img" aria-label="My GAL bag visualization">
          <div class="ux5-bag-photo-frame" aria-hidden="true">
            <span class="ux5-bag-photo-mark">GAL</span>
          </div>
          <a class="ux5-customize-bag" href="/portal/bag#customize">Customize My Bag</a>
        </div>
      </div>
    </section>`;
}
