import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const renderPath = resolve(srcRoot, 'profile/render.ts');
const clientPath = resolve(srcRoot, 'profile/client.ts');
const mainSource = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const cssSource = readFileSync(resolve(srcRoot, 'styles/portal.css'), 'utf8');

describe('RC-UX2 graphical Golfer Profile', () => {
  it('uses a real profile renderer rather than the RC-UX1 placeholder', () => {
    expect(existsSync(renderPath)).toBe(true);
    expect(existsSync(clientPath)).toBe(true);
    expect(mainSource).toContain("from './profile/render'");
    expect(mainSource).toContain('renderGolferProfile()');
    expect(mainSource).not.toContain('The new graphical Golfer Profile is the next review stage');
  });

  it('implements the locked graphical profile language', () => {
    expect(cssSource).toContain('.golfer-profile-hub');
    expect(cssSource).toContain('.golfer-figure');
    expect(cssSource).toContain('.profile-area');
    expect(cssSource).toContain('.strike-grid');
    expect(cssSource).toContain('.shot-shape-lane');
    expect(cssSource).toContain('.connect-golf-grid');
  });
});
