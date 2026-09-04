import { afterEach, describe, expect, it, vi } from 'vitest';
import { getPortalConfig } from '../config';

afterEach(() => {
  vi.unstubAllEnvs();
});

describe('getPortalConfig', () => {
  it('returns only public Supabase settings', () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://example.supabase.co');
    vi.stubEnv('VITE_SUPABASE_PUBLISHABLE_KEY', 'publishable');

    expect(getPortalConfig()).toEqual({
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'publishable',
    });
  });

  it('fails closed when configuration is missing', () => {
    vi.stubEnv('VITE_SUPABASE_URL', '');
    vi.stubEnv('VITE_SUPABASE_PUBLISHABLE_KEY', '');

    expect(() => getPortalConfig()).toThrow('Portal Supabase configuration is incomplete');
  });
});
