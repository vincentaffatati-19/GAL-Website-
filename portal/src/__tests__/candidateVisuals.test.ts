import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_LOGO_SRC } from '../branding';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const portalRoot = resolve(srcRoot, '..');
const siteRoot = resolve(portalRoot, '..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const profile = readFileSync(resolve(srcRoot, 'profile/render.ts'), 'utf8');
const viteConfig = readFileSync(resolve(portalRoot, 'vite.config.ts'), 'utf8');
const vercelConfig = JSON.parse(readFileSync(resolve(siteRoot, 'vercel.json'), 'utf8')) as {
  routes?: Array<Record<string, string>>;
  rewrites?: unknown;
};
const visualLayerPath = resolve(srcRoot, 'styles/rcux4-visuals.css');

describe('RC-UX4 candidate visual packaging', () => {
  it('serves the locked GAL logo from a stable portal asset route before the SPA fallback', () => {
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-option7a-motion.jpg');
    expect(viteConfig).toContain("base: './'");
    expect(vercelConfig.rewrites).toBeUndefined();
    expect(vercelConfig.routes?.[0]).toEqual({ handle: 'filesystem' });
    expect(vercelConfig.routes?.some((route) => route.dest === '/portal/index.html')).toBe(true);
  });

  it('uses a clean GAL data-product visual layer without embedded illustration artwork', () => {
    expect(profile).not.toContain('representation placeholder');
    expect(main).toContain("import './styles/rcux4-visuals.css'");
    expect(existsSync(visualLayerPath)).toBe(true);

    if (existsSync(visualLayerPath)) {
      const visuals = readFileSync(visualLayerPath, 'utf8');
      expect(visuals).not.toContain('data:image/svg+xml');
      expect(visuals).not.toContain('base64,');
      for (const contract of ['--gal-navy', '--gal-orange', '.tee-box-hero', '.my-bag-hero', '.golfer-figure', '.measurement-figure', 'linear-gradient', 'radial-gradient']) {
        expect(visuals).toContain(contract);
      }
    }
  });
});
