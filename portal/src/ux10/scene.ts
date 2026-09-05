import { BRAND_LOGO_SRC } from '../branding';
import { escapeHtml } from '../render/escape';
import {
  UX10_BAG_VISUALS,
  UX10_TEE_BOX_THEMES,
  loadUx10PresentationPreferences,
} from './personalization';

export type Ux10BagStatus = 'NEEDS_ATTENTION' | 'GOOD' | 'WATCHING' | 'NOT_EVALUATED';

export type Ux10BagCategory = {
  key: 'driver' | 'fairway' | 'hybrid' | 'irons' | 'wedges' | 'putter' | 'ball';
  label: string;
  status: Ux10BagStatus;
  detail: string;
  href: string;
};

export type Ux10BagEnvironmentOptions = {
  categories: Ux10BagCategory[];
  contextLabel: string;
};

const STATUS_LABEL: Record<Ux10BagStatus, string> = {
  NEEDS_ATTENTION: 'Needs Attention',
  GOOD: 'Good',
  WATCHING: 'Watching',
  NOT_EVALUATED: 'Not evaluated',
};

export function renderUx10BagEnvironment(options: Ux10BagEnvironmentOptions): string {
  const preferences = loadUx10PresentationPreferences();
  const teeBox = UX10_TEE_BOX_THEMES.find((item) => item.id === preferences.teeBoxThemeId) ?? UX10_TEE_BOX_THEMES[0];
  const bagVisual = UX10_BAG_VISUALS.find((item) => item.id === preferences.bagVisualId) ?? UX10_BAG_VISUALS[0];

  const categories = options.categories.map((category) => `
    <a class="ux10-status-item" data-bag-category="${escapeHtml(category.key)}" data-status="${escapeHtml(category.status)}" href="${escapeHtml(category.href)}" aria-label="${escapeHtml(`${category.label}: ${STATUS_LABEL[category.status]}`)}">
      <span><strong>${escapeHtml(category.label)}</strong><small>${escapeHtml(category.detail)}</small></span>
      <b aria-hidden="true">${escapeHtml(STATUS_LABEL[category.status])}</b>
    </a>`).join('');

  const teeBoxOptions = UX10_TEE_BOX_THEMES.map((item) => `
    <button type="button" class="ux10-theme-option" data-tee-box-theme-id="${item.id}" data-theme-src="${escapeHtml(item.src)}" aria-pressed="${item.id === teeBox.id ? 'true' : 'false'}">
      <span>${escapeHtml(item.shortLabel)}</span><small>${escapeHtml(item.label)}</small>
    </button>`).join('');

  const bagOptions = UX10_BAG_VISUALS.map((item) => `
    <button type="button" class="ux10-bag-option" data-bag-visual-id="${item.id}" data-bag-src="${escapeHtml(item.src)}" aria-pressed="${item.id === bagVisual.id ? 'true' : 'false'}">
      <span>${escapeHtml(item.label)}</span>
    </button>`).join('');

  return `
    <section class="ux10-bag-environment" aria-label="${escapeHtml(options.contextLabel)}">
      <img class="ux10-tee-box-background" data-current-tee-box="${teeBox.id}" src="${escapeHtml(teeBox.src)}" alt="" aria-hidden="true" loading="eager" decoding="async">
      <div class="ux10-scene-overlay" aria-hidden="true"></div>

      <div class="ux10-scene-controls">
        <section class="ux10-tee-box-selector" aria-label="Choose My Tee Box">
          <div><p class="eyebrow">Choose My Tee Box</p><small>Changes the background only.</small></div>
          <div class="ux10-selector-options">${teeBoxOptions}</div>
        </section>
        <section class="ux10-bag-selector" aria-label="Bag Visual">
          <div><p class="eyebrow">Bag Visual</p><small>Changes presentation only. Your equipment data stays the same.</small></div>
          <div class="ux10-selector-options">${bagOptions}</div>
        </section>
      </div>

      <div class="ux10-bag-environment-grid">
        <nav class="ux10-status-rail" aria-label="Equipment category status">${categories}</nav>
        <div class="ux10-bag-stage" aria-label="Personalized bag visual">
          <img class="ux10-bag-image" data-current-bag-visual="${bagVisual.id}" src="${escapeHtml(bagVisual.src)}" alt="Personalized golf bag visual" loading="eager" decoding="async">
          <div class="ux10-bag-brand" aria-hidden="true"><img src="${escapeHtml(BRAND_LOGO_SRC)}" alt=""></div>
          <p class="ux10-scene-note">Different tee box. Same bag intelligence.</p>
        </div>
      </div>
    </section>`;
}
