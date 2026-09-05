import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';

const here = dirname(fileURLToPath(import.meta.url));
const logoPath = resolve(here, '../../public/gal-motion-arc-dark-lockup.webp');
const LOCKED_LOGO_SHA256 = '8cd2030c7b3f4e75a9474dbd3e9f27e6697ce89ea756f22a5c4749192c117636';

describe('My GAL UX10 Stylized Option B Motion Arc brand contract', () => {
  it('uses the locked Motion Arc premium-on-dark asset at the stable portal route', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-motion-arc-dark-lockup.webp');
    expect(BRAND_LOGO_SRC).not.toContain('gal-option7a-motion.jpg');
  });

  it('ships the verified compressed crop derived from the locked Motion Arc brand board', () => {
    expect(existsSync(logoPath)).toBe(true);
    if (!existsSync(logoPath)) return;
    const bytes = readFileSync(logoPath);
    expect(bytes.length).toBe(15580);
    expect(bytes.subarray(0, 4).toString('ascii')).toBe('RIFF');
    expect(bytes.subarray(8, 12).toString('ascii')).toBe('WEBP');
    expect(createHash('sha256').update(bytes).digest('hex')).toBe(LOCKED_LOGO_SHA256);
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
