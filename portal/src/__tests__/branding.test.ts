import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_DATA_URI } from '../branding';

describe('My GAL Option 7A Motion brand contract', () => {
  it('uses the approved Motion logo asset contract', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_DATA_URI.startsWith('data:image/png;base64,')).toBe(true);
    expect(BRAND_LOGO_DATA_URI.length).toBeGreaterThan(1000);
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
