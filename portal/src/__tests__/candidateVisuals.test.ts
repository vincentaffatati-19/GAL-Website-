import { createHash } from 'node:crypto';
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
const scene = readFileSync(resolve(srcRoot, 'ux10/scene.ts'), 'utf8');
const personalization = readFileSync(resolve(srcRoot, 'ux10/personalization.ts'), 'utf8');
const viteConfig = readFileSync(resolve(portalRoot, 'vite.config.ts'), 'utf8');
const vercelConfig = JSON.parse(readFileSync(resolve(siteRoot, 'vercel.json'), 'utf8')) as {
  buildCommand?: string;
  outputDirectory?: string;
  routes?: Array<Record<string, string>>;
  rewrites?: unknown;
};
const visualLayerPath = resolve(srcRoot, 'styles/ux10.css');
const readmePath = resolve(portalRoot, 'public/ux10/README.md');
const sumsPath = resolve(portalRoot, 'public/ux10/SHA256SUMS');
const assets = [
  'public/ux10/tee-boxes/coastal-01.webp',
  'public/ux10/tee-boxes/cliffs-01.webp',
  'public/ux10/bags/gal-tour-bag.png',
  'public/ux10/bags/gal-stand-bag.png',
] as const;

describe('GAL-UX10.02 candidate visual packaging', () => {
  it('serves the locked Stylized Option B Motion Arc logo and builds the preview from current source', () => {
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-motion-arc-dark-lockup.webp');
    expect(BRAND_LOGO_SRC).not.toBe('/portal/gal-option7a-motion.jpg');
    expect(viteConfig).toContain("base: './'");
    expect(vercelConfig.buildCommand).toBe('bash scripts/build-ux10-preview.sh');
    expect(vercelConfig.buildCommand).not.toContain('Using prebuilt verified UX preview');
    expect(vercelConfig.outputDirectory).toBe('preview');
    expect(vercelConfig.rewrites).toBeUndefined();
    expect(vercelConfig.routes?.[0]).toEqual({ handle: 'filesystem' });
    expect(vercelConfig.routes?.some((route) => route.dest === '/portal/index.html')).toBe(true);
  });

  it('packages independent governed tee-box and bag assets', () => {
    expect(scene).toContain('ux10-tee-box-background');
    expect(scene).toContain('ux10-bag-image');
    expect(personalization).toContain('/portal/ux10/tee-boxes/coastal-01.webp');
    expect(personalization).toContain('/portal/ux10/tee-boxes/cliffs-01.webp');
    expect(personalization).toContain('/portal/ux10/bags/gal-tour-bag.png');
    expect(personalization).toContain('/portal/ux10/bags/gal-stand-bag.png');
    expect(scene + personalization + today + bag).not.toContain('/portal/ux5/reference-bag.webp');

    expect(existsSync(readmePath)).toBe(true);
    expect(existsSync(sumsPath)).toBe(true);
    const sums = existsSync(sumsPath) ? readFileSync(sumsPath, 'utf8') : '';
    for (const relative of assets) {
      const full = resolve(portalRoot, relative);
      expect(existsSync(full)).toBe(true);
      if (!existsSync(full)) continue;
      const digest = createHash('sha256').update(readFileSync(full)).digest('hex');
      expect(sums).toContain(`${digest}  ${relative.replace('public/ux10/', '')}`);
    }
  });

  it('uses UX10 as the only active current visual layer', () => {
    expect(profile).not.toContain('representation placeholder');
    expect(main).toContain("import './styles/ux10.css'");
    expect(main).toContain("import './styles/ux10-profile.css'");
    expect(main).not.toMatch(/import '\.\/styles\/ux5-/);
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

    const visuals = readFileSync(visualLayerPath, 'utf8');
    expect(visuals).not.toContain('data:image/svg+xml');
    expect(visuals).not.toContain('base64,');
    for (const contract of ['--ux10-navy', '--ux10-orange', '.ux10-shell', '.ux10-tee-box-background', '.ux10-bag-stage', '.ux10-status-rail', '.ux10-club-panel']) {
      expect(visuals).toContain(contract);
    }
  });

  it('keeps navigation and actions readable in the UX10 layer', () => {
    const visuals = readFileSync(visualLayerPath, 'utf8');
    expect(visuals).toMatch(/\.ux10-primary-nav\s*\{[^}]*background:\s*transparent;/s);
    expect(visuals).toContain('.ux10-dashboard .quick-actions a');
  });

  it('keeps the mobile bottom navigation anchored to the viewport', () => {
    const visuals = readFileSync(visualLayerPath, 'utf8');
    expect(visuals).toMatch(/@media\s*\(max-width:\s*900px\)[\s\S]*?\.ux10-primary-nav\s*\{[^}]*position:\s*fixed;[^}]*bottom:\s*0;/s);
  });
});
