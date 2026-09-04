import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  getCurrentSession: vi.fn(),
  from: vi.fn(),
}));

vi.mock('../auth/session', () => ({ getCurrentSession: mocks.getCurrentSession }));
vi.mock('../supabase/client', () => ({ getSupabaseClient: () => ({ from: mocks.from }) }));

import { getCommercialAggregateConsent, recordCommercialAggregateConsent } from '../privacy/commercialConsent';

beforeEach(() => {
  mocks.getCurrentSession.mockReset();
  mocks.from.mockReset();
  mocks.getCurrentSession.mockResolvedValue({ user: { id: 'auth-1' } });
});

function userLookup() {
  return { select: () => ({ eq: () => ({ single: async () => ({ data: { id: 'gal-1' }, error: null }) }) }) };
}

describe('commercial aggregate consent', () => {
  it('reads only the latest explicit commercial aggregate decision', async () => {
    const consentQuery = {
      select: () => consentQuery,
      eq: () => consentQuery,
      order: () => consentQuery,
      limit: () => consentQuery,
      maybeSingle: async () => ({ data: { status: 'ACCEPTED', recorded_at: '2026-09-04T00:00:00Z' }, error: null }),
    };
    mocks.from.mockImplementation((table: string) => table === 'gal_users' ? userLookup() : consentQuery);

    await expect(getCommercialAggregateConsent()).resolves.toEqual({
      decision: 'ACCEPTED',
      recordedAt: '2026-09-04T00:00:00Z',
    });
  });

  it('records a new event and never updates or deletes consent history', async () => {
    const insert = vi.fn().mockResolvedValue({ error: null });
    mocks.from.mockImplementation((table: string) => table === 'gal_users' ? userLookup() : { insert });

    await recordCommercialAggregateConsent('WITHDRAWN');

    expect(insert).toHaveBeenCalledWith(expect.objectContaining({
      user_id: 'gal-1', consent_type: 'COMMERCIAL_AGGREGATE', status: 'WITHDRAWN',
    }));
  });
});
