import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';

const here = dirname(fileURLToPath(import.meta.url));
const logoPath = resolve(here, '../../public/gal-option7a-motion.jpg');
const LOCKED_LOGO_SHA256 = '26ccad548313c1d018cb6421efdfc4a95fb18d2e5123eccdc0518777a5b7047a';

describe('My GAL Option 7A Motion brand contract', () => {
  it('uses the approved Motion logo asset contract at the stable portal route', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-option7a-motion.jpg');
  });

  it('ships the locked responsive Option 7A Motion logo bytes', () => {
    const bytes = readFileSync(logoPath);
    expect(bytes.length).toBe(15946);
    expect(bytes.subarray(0, 2)).toEqual(Buffer.from([0xff, 0xd8]));
    expect(bytes.subarray(-2)).toEqual(Buffer.from([0xff, 0xd9]));
    expect(createHash('sha256').update(bytes).digest('hex')).toBe(LOCKED_LOGO_SHA256);
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
