import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const today = readFileSync(resolve(srcRoot, 'surfaces/today.ts'), 'utf8');
const scene = readFileSync(resolve(srcRoot, 'ux10/scene.ts'), 'utf8');
const driver = readFileSync(resolve(srcRoot, 'fitting/driver/render.ts'), 'utf8');
const profile = readFileSync(resolve(srcRoot, 'profile/render.ts'), 'utf8');
const branding = readFileSync(resolve(srcRoot, 'branding.ts'), 'utf8');

describe('UX10 approved dashboard and profile baseline', () => {
  it('retains the approved My GAL shell and five-item navigation', () => {
    expect(main).toContain('Your Equipment Intelligence Center');
    for (const label of ['Today', 'My Bag', 'Insights', 'Guides', 'Progress']) expect(main).toContain(label);
    expect(main).toContain('Golfer Profile');
    expect(main).toContain('GAL-UX10.02-RC1');
    expect(branding).toContain('/portal/gal-motion-arc-dark-lockup.webp');
    expect(branding).not.toContain('/portal/gal-option7a-motion.jpg');
  });

  it('retains the approved dashboard hierarchy and independent scene', () => {
    for (const copy of ['Your bag. Your game. Smarter together.', 'Bag Status', 'Bag Visual', 'Bag Value', 'Quick Actions', 'Recent Insight', 'How It Works', 'Works for Every Club']) {
      expect(today).toContain(copy);
    }
    expect(scene).toContain('ux10-tee-box-background');
    expect(scene).toContain('ux10-bag-image');
    expect(scene).toContain('ux10-status-rail');
    expect(today + scene).not.toContain('/portal/ux5/reference-bag.webp');
  });

  it('renders the Step 2 visual tee-box and bag selectors without changing their data contract', () => {
    expect(main).toContain("import './styles/ux10-dashboard-step2.css'");
    expect(scene).toContain('ux10-theme-preview');
    expect(scene).toContain('ux10-bag-preview');
    expect(scene).toContain('Choose My Tee Box');
    expect(scene).toContain('Changes the background only.');
    expect(scene).toContain('Changes presentation only. Your equipment data stays the same.');
    expect(scene).toContain('data-tee-box-theme-id');
    expect(scene).toContain('data-bag-visual-id');
  });

  it('retains the five-stage Driver intelligence panel', () => {
    for (const label of ['Overview', 'Why It Matters', 'What To Do', 'Recommendations', 'Compare']) expect(driver).toContain(label);
  });

  it('retains Profile Home and focused UX10.02 workspaces', () => {
    for (const copy of ['My Golfer Profile', 'You / Measurements', 'Your Game', 'Your Swing', 'Your Miss', 'Where You Play', 'Connected Golf', 'Tell GAL Once', 'What GAL Learned']) {
      expect(profile).toContain(copy);
    }
    for (const route of ['section=you', 'section=game', 'section=swing', 'section=miss', 'section=environment', 'section=connected']) expect(profile).toContain(route);
  });
});
