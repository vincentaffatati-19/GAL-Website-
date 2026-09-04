import { beforeEach, describe, expect, it, vi } from 'vitest';

const getSession = vi.fn();

vi.mock('../supabase/client', () => ({
  getSupabaseClient: () => ({ auth: { getSession } }),
}));

import { getCurrentSession } from '../auth/session';

beforeEach(() => {
  getSession.mockReset();
});

describe('getCurrentSession', () => {
  it('returns the current browser session', async () => {
    const session = { access_token: 'test-token' };
    getSession.mockResolvedValue({ data: { session }, error: null });

    await expect(getCurrentSession()).resolves.toBe(session);
  });

  it('propagates Supabase session errors', async () => {
    const error = new Error('session failed');
    getSession.mockResolvedValue({ data: { session: null }, error });

    await expect(getCurrentSession()).rejects.toThrow('session failed');
  });
});
