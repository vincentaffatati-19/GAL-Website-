import { afterEach, describe, expect, it, vi } from 'vitest';
import { getSupabaseClient, resetSupabaseClientForTests } from '../supabase/client';

afterEach(() => {
  vi.unstubAllEnvs();
  resetSupabaseClientForTests();
});

describe('browser Supabase boundary', () => {
  it('creates a singleton from only public portal configuration', () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://example.supabase.co');
    vi.stubEnv('VITE_SUPABASE_PUBLISHABLE_KEY', 'publishable-test-key');

    const first = getSupabaseClient();
    const second = getSupabaseClient();

    expect(first).toBe(second);
  });

  it('fails closed when public configuration is unavailable', () => {
    vi.stubEnv('VITE_SUPABASE_URL', '');
    vi.stubEnv('VITE_SUPABASE_PUBLISHABLE_KEY', '');

    expect(() => getSupabaseClient()).toThrow('Portal Supabase configuration is incomplete');
  });
});
