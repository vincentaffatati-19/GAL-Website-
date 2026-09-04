import { describe, expect, it } from 'vitest';
import { escapeHtml } from '../render/escape';

describe('golfer-facing HTML escaping', () => {
  it('escapes markup and attribute delimiters', () => {
    expect(escapeHtml('<img src=x onerror="boom"> & \'test\'')).toBe('&lt;img src=x onerror=&quot;boom&quot;&gt; &amp; &#39;test&#39;');
  });
});
