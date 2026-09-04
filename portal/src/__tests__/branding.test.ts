import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';

describe('My GAL Option 7A Motion brand contract', () => {
  it('uses the approved Motion logo asset contract at the compiled portal path', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-option7a-motion.jpg');
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
