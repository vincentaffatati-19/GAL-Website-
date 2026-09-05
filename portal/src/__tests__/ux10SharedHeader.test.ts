import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_LOGO_SRC } from '../branding';
import { renderUx10SharedHeader, UX10_PRIMARY_NAV } from '../shell/header';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const header = readFileSync(resolve(srcRoot, 'shell/header.ts'), 'utf8');
const profile = readFileSync(resolve(srcRoot, 'profile/render.ts'), 'utf8');
const today = readFileSync(resolve(srcRoot, 'surfaces/today.ts'), 'utf8');
const bag = readFileSync(resolve(srcRoot, 'bag/render.ts'), 'utf8');

describe('UX10 universal shared header', () => {
  it('uses the locked Stylized Option B Motion Arc asset', () => {
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-motion-arc-dark-lockup.webp');
    expect(header).toContain('BRAND_LOGO_SRC');
    expect(header).not.toContain('/portal/gal-option7a-motion.jpg');
  });

  it('preserves the locked five-item navigation and separate Profile access', () => {
    expect(UX10_PRIMARY_NAV.map((item) => item.label)).toEqual(['Today', 'My Bag', 'Insights', 'Guides', 'Progress']);
    const rendered = renderUx10SharedHeader('profile');
    for (const label of ['Today', 'My Bag', 'Insights', 'Guides', 'Progress', 'Golfer Profile']) expect(rendered).toContain(label);
    expect(rendered).toContain('data-ux10-shared-header="true"');
    expect(rendered).toContain('href="/portal/profile"');
  });

  it('routes the application shell through the shared header instead of page-specific header markup', () => {
    expect(main).toContain("renderUx10SharedHeader(currentRoute)");
    expect(main).not.toContain('<header class="my-gal-header');
    for (const source of [profile, today, bag]) expect(source).not.toContain('<header class="my-gal-header');
  });

  it('uses the same component for every portal route while only changing active-route state', () => {
    const routes = ['today', 'bag', 'insights', 'guides', 'progress', 'profile'] as const;
    const headers = routes.map((route) => renderUx10SharedHeader(route));
    for (const rendered of headers) {
      expect(rendered).toContain('/portal/gal-motion-arc-dark-lockup.webp');
      expect(rendered).toContain('My GAL');
      expect(rendered).toContain('Your Equipment Intelligence Center');
      expect(rendered).toContain('data-ux10-shared-header="true"');
    }
  });
});
