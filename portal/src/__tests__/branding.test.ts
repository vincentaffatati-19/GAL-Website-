import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';

const here = dirname(fileURLToPath(import.meta.url));
const logoPath = resolve(here, '../../public/gal-motion-arc-dark-lockup.png');
const LOCKED_LOGO_SHA256 = '55058aa639e98aa00ba9f2bfe3fa13d27d6829cca5ef0a1c562227a2e2fe3001';

describe('My GAL UX10 Stylized Option B Motion Arc brand contract', () => {
  it('uses the locked Motion Arc premium-on-dark asset at the stable portal route', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-motion-arc-dark-lockup.png');
    expect(BRAND_LOGO_SRC).not.toContain('gal-option7a-motion.jpg');
  });

  it('ships the exact locked Motion Arc premium-on-dark logo bytes', () => {
    expect(existsSync(logoPath)).toBe(true);
    if (!existsSync(logoPath)) return;
    const bytes = readFileSync(logoPath);
    expect(bytes.length).toBe(140813);
    expect(bytes.subarray(0, 8)).toEqual(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    expect(createHash('sha256').update(bytes).digest('hex')).toBe(LOCKED_LOGO_SHA256);
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
