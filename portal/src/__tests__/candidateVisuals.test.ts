import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_LOGO_SRC } from '../branding';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const portalRoot = resolve(srcRoot, '..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const profile = readFileSync(resolve(srcRoot, 'profile/render.ts'), 'utf8');
const viteConfig = readFileSync(resolve(portalRoot, 'vite.config.ts'), 'utf8');
const visualLayerPath = resolve(srcRoot, 'styles/rcux4-visuals.css');

describe('RC-UX4 candidate visual packaging', () => {
  it('uses deployment-safe relative paths for the packaged portal and logo', () => {
    expect(BRAND_LOGO_SRC).toBe('./gal-option7a-motion.jpg');
    expect(viteConfig).toContain("base: './'");
  });

  it('ships a production visual layer instead of placeholder graphics', () => {
    expect(profile).not.toContain('representation placeholder');
    expect(main).toContain("import './styles/rcux4-visuals.css'");
    expect(existsSync(visualLayerPath)).toBe(true);

    if (existsSync(visualLayerPath)) {
      const visuals = readFileSync(visualLayerPath, 'utf8');
      for (const contract of ['.golfer-figure', '.bag-hero', '.measurement-figure', '.tee-box-hero', 'data:image/svg+xml']) {
        expect(visuals).toContain(contract);
      }
    }
  });
});
