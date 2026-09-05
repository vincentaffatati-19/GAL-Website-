import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const mainSource = readFileSync(resolve(here, '../main.ts'), 'utf8');
const headerSource = readFileSync(resolve(here, '../shell/header.ts'), 'utf8');
const cssSource = readFileSync(resolve(here, '../styles/portal.css'), 'utf8');

describe('My GAL shell UX contract', () => {
  it('keeps the locked five-part primary navigation and exposes Profile separately through the shared header', () => {
    for (const label of ['Today', 'My Bag', 'Insights', 'Guides', 'Progress']) {
      expect(headerSource).toContain(`label: '${label}'`);
    }
    expect(headerSource).toContain('/portal/profile');
    expect(headerSource).toContain('Golfer Profile');
    expect(mainSource).toContain('renderUx10SharedHeader(currentRoute)');
  });

  it('includes mobile-first tee-box and bottom-navigation styling hooks', () => {
    expect(cssSource).toContain('.tee-box-hero');
    expect(cssSource).toContain('.bag-hero');
    expect(cssSource).toContain('@media');
    expect(cssSource).toContain('min-height: 44px');
  });
});
