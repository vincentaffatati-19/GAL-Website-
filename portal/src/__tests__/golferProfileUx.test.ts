import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const renderPath = resolve(srcRoot, 'profile/render.ts');
const modelPath = resolve(srcRoot, 'profile/model.ts');
const profileCssPath = resolve(srcRoot, 'styles/ux10-profile.css');
const mainSource = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const renderSource = readFileSync(renderPath, 'utf8');

describe('GAL UX10.02 Golfer Profile experience', () => {
  it('uses a governed profile renderer and workspace model', () => {
    expect(existsSync(renderPath)).toBe(true);
    expect(existsSync(modelPath)).toBe(true);
    expect(mainSource).toContain("from './profile/render'");
    expect(mainSource).toContain('renderGolferProfile(params)');
    expect(mainSource).toContain('GAL-UX10.02-RC1');
  });

  it('renders Profile Home plus six focused profile areas instead of one long page', () => {
    expect(renderSource).toContain('renderProfileHome');
    expect(renderSource).toContain("section=you");
    expect(renderSource).toContain("section=game");
    expect(renderSource).toContain("section=swing");
    expect(renderSource).toContain("section=miss");
    expect(renderSource).toContain("section=environment");
    expect(renderSource).toContain("section=connected");
    expect(renderSource).toContain('profileWorkspaceFromParams');
    expect(renderSource).not.toContain('${measurementGuidance()}\n      ${missGuidance()}\n      ${environmentGuidance()}\n      ${connectGolf()}');
  });

  it('implements the locked miss vocabulary and truthful connection language', () => {
    expect(renderSource).toContain('MISS_SHAPES');
    expect(renderSource).toContain('Save My Miss Profile');
    expect(renderSource).toContain('Not connected');
    expect(renderSource).not.toContain('Illustrative connection');
  });

  it('uses a dedicated responsive UX10 Profile visual system', () => {
    expect(existsSync(profileCssPath)).toBe(true);
    expect(mainSource).toContain("import './styles/ux10-profile.css'");
    if (!existsSync(profileCssPath)) return;
    const cssSource = readFileSync(profileCssPath, 'utf8');
    expect(cssSource).toContain('.ux10-profile-home');
    expect(cssSource).toContain('.ux10-profile-workspace');
    expect(cssSource).toContain('.ux10-data-quality');
    expect(cssSource).toContain('@media (max-width: 600px)');
  });
});
