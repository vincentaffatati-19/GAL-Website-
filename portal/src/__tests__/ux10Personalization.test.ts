import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const personalizationPath = resolve(srcRoot, 'ux10/personalization.ts');
const scenePath = resolve(srcRoot, 'ux10/scene.ts');
const bindPath = resolve(srcRoot, 'ux10/bind.ts');

describe('GAL UX10.01 presentation personalization contract', () => {
  it('defines presentation preferences independently from analytical state', () => {
    expect(existsSync(personalizationPath)).toBe(true);
    if (!existsSync(personalizationPath)) return;
    const source = readFileSync(personalizationPath, 'utf8');
    for (const token of [
      'TeeBoxThemeId',
      'BagVisualId',
      'Ux10PresentationPreferences',
      'UX10_TEE_BOX_THEMES',
      'UX10_BAG_VISUALS',
      'loadUx10PresentationPreferences',
      'saveUx10PresentationPreferences',
    ]) expect(source).toContain(token);
    for (const forbidden of ['fetchMyBag', 'fetchGolferInsights', 'buildDriverTargetProfile', 'recommendation']) {
      expect(source).not.toContain(forbidden);
    }
  });

  it('renders tee-box background and bag as separate source paths and DOM layers', () => {
    expect(existsSync(scenePath)).toBe(true);
    if (!existsSync(scenePath)) return;
    const source = readFileSync(scenePath, 'utf8');
    expect(source).toContain('ux10-tee-box-background');
    expect(source).toContain('ux10-bag-image');
    expect(source).toContain('data-tee-box-theme-id');
    expect(source).toContain('data-bag-visual-id');
    expect(source).not.toContain('/portal/ux5/reference-bag.webp');
  });

  it('binds tee-box and bag choices independently', () => {
    expect(existsSync(bindPath)).toBe(true);
    if (!existsSync(bindPath)) return;
    const source = readFileSync(bindPath, 'utf8');
    expect(source).toContain('[data-tee-box-theme-id]');
    expect(source).toContain('[data-bag-visual-id]');
    expect(source).toContain('teeBoxThemeId');
    expect(source).toContain('bagVisualId');
    expect(source).not.toContain('fetchMyBag');
    expect(source).not.toContain('fetchGolferInsights');
  });
});
