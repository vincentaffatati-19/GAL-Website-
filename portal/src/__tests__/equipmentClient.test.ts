import { beforeEach, describe, expect, it, vi } from 'vitest';

const rpc = vi.fn();
const getCurrentSession = vi.fn();

vi.mock('../supabase/client', () => ({
  getSupabaseClient: () => ({ rpc }),
}));

vi.mock('../auth/session', () => ({
  getCurrentSession,
}));

import { fetchAiFitEquipment, fetchGuideEquipment } from '../equipment/client';

const baseRow = {
  family_id: 'family-1',
  equipment_family_id: 'GAL-EQF-1',
  canonical_product_id: 'product-1',
  canonical_brand_id: 'brand-1',
  category: 'Driver',
  family_name: 'Example Driver',
  lifecycle_state: 'CURRENT',
  approved_characteristics: [],
};

beforeEach(() => {
  rpc.mockReset();
  getCurrentSession.mockReset();
});

describe('governed equipment browser client', () => {
  it('routes public Guide reads only through the public Guide RPC', async () => {
    rpc.mockResolvedValue({
      data: [{ ...baseRow, readiness_state: 'GUIDE_READY', media_assets: [] }],
      error: null,
    });

    const result = await fetchGuideEquipment();

    expect(rpc).toHaveBeenCalledTimes(1);
    expect(rpc).toHaveBeenCalledWith('gal_public_equipment_guide');
    expect(result[0].item.familyName).toBe('Example Driver');
  });

  it('requires authentication before any AI Fit RPC call', async () => {
    getCurrentSession.mockResolvedValue(null);

    await expect(fetchAiFitEquipment()).rejects.toMatchObject({ code: 'AUTH_REQUIRED' });
    expect(rpc).not.toHaveBeenCalled();
  });

  it('routes authenticated fitting only through the AI Fit RPC', async () => {
    getCurrentSession.mockResolvedValue({ access_token: 'test-token' });
    rpc.mockResolvedValue({
      data: [{
        ...baseRow,
        readiness_state: 'AI_FIT_READY',
        blocking_gap_count: 0,
        configuration_id: 'config-1',
        equipment_configuration_id: 'GAL-EQCFG-1',
        configuration_key: 'standard',
        configuration_name: 'Standard',
        support_state: 'FACTORY_STANDARD',
        limited_evidence: false,
      }],
      error: null,
    });

    const result = await fetchAiFitEquipment();

    expect(rpc).toHaveBeenCalledWith('gal_authenticated_equipment_ai_fit');
    expect(result[0].configuration.readiness).toBe('AI_FIT_READY');
  });

  it('does not silently fall back to a different ranking path on RPC failure', async () => {
    getCurrentSession.mockResolvedValue({ access_token: 'test-token' });
    rpc.mockResolvedValue({ data: null, error: { message: 'backend unavailable' } });

    await expect(fetchAiFitEquipment()).rejects.toMatchObject({
      code: 'AI_FIT_RPC_FAILED',
      message: 'backend unavailable',
    });
    expect(rpc).toHaveBeenCalledTimes(1);
  });
});
