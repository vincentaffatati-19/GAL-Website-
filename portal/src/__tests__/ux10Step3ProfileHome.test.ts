import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const profile = readFileSync(resolve(srcRoot, 'profile/render.ts'), 'utf8');
const css = readFileSync(resolve(srcRoot, 'styles/ux10-step3-profile-home.css'), 'utf8');

describe('UX10 Step 3 Profile Home presentation', () => {
  it('adds only the scoped Profile Home visual layer', () => {
    expect(main).toContain("import './styles/ux10-step3-profile-home.css'");
    expect(css).toContain('.ux10-profile-home-hero');
    expect(css).toContain('.ux10-profile-area-list');
    expect(css).toContain('.ux10-profile-area-card');
    expect(css).toContain('.ux10-profile-coverage');
  });

  it('preserves the six governed Profile Home areas and trust message', () => {
    for (const copy of ['Tell GAL Once. Connect It Once. Use It Everywhere.', 'profile areas started']) {
      expect(profile).toContain(copy);
    }
    expect(profile).toContain('PROFILE_HOME_AREAS');
    for (const section of ['section=you', 'section=game', 'section=swing', 'section=miss', 'section=environment', 'section=connected']) {
      expect(profile).toContain(section);
    }
  });

  it('keeps the Profile Home responsive without altering workspace layouts', () => {
    expect(css).toMatch(/@media\s*\(max-width:\s*760px\)/);
    expect(css).not.toContain('.ux10-profile-workspace-header');
    expect(css).not.toContain('.ux10-measurement-layout');
    expect(css).not.toContain('.ux10-swing-layout');
  });
});
