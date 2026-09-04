import { existsSync, readFileSync } from 'node:fs';
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
  ux_family: string;
  ux_version: string;
  next_review_candidate: string;
};
const scenePath = resolve(srcRoot, 'ux10/scene.ts');
const scene = existsSync(scenePath) ? readFileSync(scenePath, 'utf8') : '';

describe('GAL-UX10.01-RC1 locked portal contract', () => {
  it('binds implementation to the locked UX10 authority', () => {
    expect(manifest.ux_family).toBe('GAL-UX10');
    expect(manifest.ux_version).toBe('GAL-UX10.01');
    expect(manifest.next_review_candidate).toBe('GAL-UX10.01-RC1');
    expect(main).toContain('GAL-UX10.01-RC1');
    expect(main).toContain('data-ux-version="GAL-UX10.01-RC1"');
    expect(main).toContain("import './styles/ux10.css'");
    expect(main).not.toContain("import './styles/ux5-mid.css'");
  });

  it('shares the independent UX10 scene across Today and My Bag', () => {
    expect(scene).toContain('ux10-tee-box-background');
    expect(scene).toContain('ux10-bag-image');
    expect(today).toContain('renderUx10BagEnvironment');
    expect(bag).toContain('renderUx10BagEnvironment');
    expect(today + bag + scene).not.toContain('/portal/ux5/reference-bag.webp');
  });

  it('uses the five-step Driver intelligence model without sample-fact leakage', () => {
    for (const token of ['Overview', 'Why It Matters', 'What To Do', 'Recommendations', 'Compare', 'driver-what-to-do']) {
      expect(driver).toContain(token);
    }
    for (const forbidden of ['94 mph', '247 yds', '+12 Yards', '$3,840', '78%', '71%', '+11.3 yds']) {
      expect(today + driver + bag + scene).not.toContain(forbidden);
    }
  });
});
