import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const repoRoot = resolve(srcRoot, '../..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const today = readFileSync(resolve(srcRoot, 'surfaces/today.ts'), 'utf8');
const bag = readFileSync(resolve(srcRoot, 'bag/render.ts'), 'utf8');
const driver = readFileSync(resolve(srcRoot, 'fitting/driver/render.ts'), 'utf8');
const manifest = JSON.parse(readFileSync(resolve(repoRoot, 'GAL_UX_MANIFEST.json'), 'utf8')) as {
  ux_version: string;
  next_review_candidate: string;
};

describe('GAL-UX5-MID-RC1 locked portal contract', () => {
  it('binds implementation to the locked UX5 authority', () => {
    expect(manifest.ux_version).toBe('GAL-UX5-MID');
    expect(manifest.next_review_candidate).toBe('GAL-UX5-MID-RC1');
    expect(main).toContain('GAL-UX5-MID-RC1');
    expect(main).toContain("import './styles/ux5-mid.css'");
    expect(main).not.toContain("import './styles/rcux4-visuals.css'");
  });

  it('implements the locked dashboard landmarks', () => {
    for (const token of [
      'ux5-dashboard',
      'ux5-bag-environment',
      'ux5-status-rail',
      'Bag Status',
      'Next Opportunity',
      'Bag Value',
      'Quick Actions',
      'Recent Insight',
      'Progress at a Glance',
      'How It Works',
      'Works for Every Club',
    ]) {
      expect(today).toContain(token);
    }
    expect(bag).toContain('ux5-bag-environment');
  });

  it('uses contextual club intelligence tabs without sample-fact leakage', () => {
    for (const token of ['ux5-club-panel', 'Overview', 'Why It Matters', 'Recommendations', 'Compare']) {
      expect(driver).toContain(token);
    }
    for (const forbidden of ['94 mph', '247 yds', '+12 Yards', '$3,840', '78%', '71%', '+11.3 yds']) {
      expect(today + driver + bag).not.toContain(forbidden);
    }
  });
});
