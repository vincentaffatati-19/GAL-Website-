import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const renderPath = resolve(srcRoot, 'profile/render.ts');
const clientPath = resolve(srcRoot, 'profile/client.ts');

describe('RC-UX2 profile data contract', () => {
  it('preserves provenance, freshness and progressive completion', () => {
    expect(existsSync(clientPath)).toBe(true);
    expect(existsSync(renderPath)).toBe(true);
    const client = readFileSync(clientPath, 'utf8');
    const render = readFileSync(renderPath, 'utf8');

    for (const field of ['fact_key', 'fact_value', 'source', 'source_category', 'confidence', 'observed_at', 'updated_at', 'stale_after_days', 'source_reference']) {
      expect(client).toContain(field);
    }
    expect(render).toContain('Tell GAL Once');
    expect(render).toContain('Connect It Once');
    expect(render).toContain('Profile completeness');
    expect(render).toContain('data coverage');
    expect(render).toContain('You');
    expect(render).toContain('Your Game');
    expect(render).toContain('Your Swing');
    expect(render).toContain('Your Miss');
    expect(render).toContain('Where You Play');
    expect(render).toContain('Connect Your Golf');
  });

  it('does not claim illustrative integrations are live', () => {
    if (!existsSync(renderPath)) return;
    const render = readFileSync(renderPath, 'utf8');
    expect(render).toContain('Illustrative connection');
    expect(render).not.toContain('Connected to Arccos');
    expect(render).not.toContain('Connected to Garmin');
  });
});
