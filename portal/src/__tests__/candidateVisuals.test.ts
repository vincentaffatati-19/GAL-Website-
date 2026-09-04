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
const today = readFileSync(resolve(srcRoot, 'surfaces/today.ts'), 'utf8');
const bag = readFileSync(resolve(srcRoot, 'bag/render.ts'), 'utf8');
const viteConfig = readFileSync(resolve(portalRoot, 'vite.config.ts'), 'utf8');
const vercelConfig = JSON.parse(readFileSync(resolve(siteRoot, 'vercel.json'), 'utf8')) as {
  routes?: Array<Record<string, string>>;
  rewrites?: unknown;
};
const visualLayerPath = resolve(srcRoot, 'styles/ux5-mid.css');

describe('GAL-UX5-MID candidate visual packaging', () => {
  it('serves the locked GAL logo from a stable portal asset route before the SPA fallback', () => {
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-option7a-motion.jpg');
    expect(viteConfig).toContain("base: './'");
    expect(vercelConfig.rewrites).toBeUndefined();
    expect(vercelConfig.routes?.[0]).toEqual({ handle: 'filesystem' });
    expect(vercelConfig.routes?.some((route) => route.dest === '/portal/index.html')).toBe(true);
  });

  it('uses UX5 as the only active current visual layer', () => {
    expect(profile).not.toContain('representation placeholder');
    expect(main).toContain("import './styles/ux5-mid.css'");
    expect(main).not.toContain("import './styles/rcux4-visuals.css'");
    expect(existsSync(visualLayerPath)).toBe(true);

    for (const [source, primitive] of [
      [today, 'tee-box-sky'],
      [today, 'tee-box-water'],
      [today, 'tee-box-fairway'],
      [today, 'bag-clubs'],
      [today, 'bag-body'],
      [today, 'bag-base'],
      [bag, 'my-bag-course'],
      [bag, 'bag-clubs'],
      [bag, 'bag-body'],
      [bag, 'bag-base'],
      [profile, 'golfer-head'],
      [profile, 'golfer-body'],
      [profile, 'golfer-club'],
      [profile, 'measure-person'],
      [profile, 'measure-line'],
    ] as const) {
      expect(source).not.toContain(primitive);
    }

    if (existsSync(visualLayerPath)) {
      const visuals = readFileSync(visualLayerPath, 'utf8');
      expect(visuals).not.toContain('data:image/svg+xml');
      expect(visuals).not.toContain('base64,');
      for (const contract of ['--ux5-navy', '--ux5-orange', '.ux5-shell', '.ux5-bag-environment', '.ux5-club-panel']) {
        expect(visuals).toContain(contract);
      }
    }
  });
});
