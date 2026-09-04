import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const bag = readFileSync(resolve(srcRoot, 'bag/render.ts'), 'utf8');
const css = [
  readFileSync(resolve(srcRoot, 'styles/portal.css'), 'utf8'),
  readFileSync(resolve(srcRoot, 'styles/rcux3.css'), 'utf8'),
].join('\n');

describe('RC-UX3 My Bag visual contract', () => {
  it('uses the approved bag-first visual language and honest incomplete states', () => {
    expect(bag).toContain('my-bag-hero');
    expect(bag).toContain('bag-category-target');
    expect(bag).toContain('How My Bag Works');
    expect(bag).toContain('Configuration details needed');
    expect(bag).not.toContain('Optimized');
    expect(bag).not.toContain('Bag Score');
  });

  it('has responsive bag interaction styling', () => {
    expect(css).toContain('.my-bag-hero');
    expect(css).toContain('.bag-category-target');
    expect(css).toContain('.bag-detail-grid');
  });
});
