import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const renderPath = resolve(srcRoot, 'profile/render.ts');
const clientPath = resolve(srcRoot, 'profile/client.ts');
const typesPath = resolve(srcRoot, 'profile/types.ts');

describe('GAL UX10.02 profile data contract', () => {
  it('preserves provenance, freshness and truthful progressive coverage', () => {
    expect(existsSync(clientPath)).toBe(true);
    expect(existsSync(renderPath)).toBe(true);
    expect(existsSync(typesPath)).toBe(true);
    const client = readFileSync(clientPath, 'utf8');
    const render = readFileSync(renderPath, 'utf8');
    const types = readFileSync(typesPath, 'utf8');
    const profileContract = `${types}\n${render}`;

    for (const field of ['fact_key', 'fact_value', 'source', 'source_category', 'confidence', 'observed_at', 'updated_at', 'stale_after_days', 'source_reference']) {
      expect(client).toContain(field);
    }
    for (const copy of ['Tell GAL Once', 'Connect It Once', 'profile areas started', 'Coverage only', 'You / Measurements', 'Your Game', 'Your Swing', 'Your Miss', 'Where You Play', 'Connected Golf']) {
      expect(profileContract).toContain(copy);
    }
    expect(profileContract).not.toContain('Profile completeness');
  });

  it('uses truthful integration states and never claims unsupported live connections', () => {
    if (!existsSync(renderPath)) return;
    const render = readFileSync(renderPath, 'utf8');
    expect(render).toContain('Not connected');
    expect(render).toContain('Unavailable in this review');
    expect(render).toContain('What GAL Learned');
    expect(render).not.toContain('Illustrative connection');
    expect(render).not.toContain('Connected to Arccos');
    expect(render).not.toContain('Connected to Garmin');
  });
});
