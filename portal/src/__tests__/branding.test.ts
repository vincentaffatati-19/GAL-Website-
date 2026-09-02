import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';

describe('My GAL Option 7A Motion brand contract', () => {
  it('bundles the approved Motion logo as an inline data asset', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_SRC.startsWith('data:image/jpeg;base64,')).toBe(true);
    expect(BRAND_LOGO_SRC.length).toBeGreaterThan(1000);
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
