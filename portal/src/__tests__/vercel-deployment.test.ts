import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');

describe('Vercel staging deployment contract', () => {
  it('builds the portal and serves compiled output without replacing the static public site', () => {
    const config = JSON.parse(readFileSync(resolve(repoRoot, 'vercel.json'), 'utf8')) as {
      buildCommand?: string;
      outputDirectory?: string;
      rewrites?: Array<{ source: string; destination: string }>;
    };

    expect(config.outputDirectory).toBe('.');
    expect(config.buildCommand).toContain('pnpm build');
    expect(config.buildCommand).toContain('cp -R dist/. .');
    expect(config.rewrites).toContainEqual({
      source: '/portal/:path*',
      destination: '/portal/index.html',
    });
  });
});
