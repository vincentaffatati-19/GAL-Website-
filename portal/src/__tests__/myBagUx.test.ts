import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  fetchMyBag: vi.fn(),
}));

vi.mock('../bag/client', () => ({
  fetchMyBag: mocks.fetchMyBag,
}));

import { renderMyBag } from '../bag/render';

describe('GAL UX5 My Bag visual contract', () => {
  beforeEach(() => {
    mocks.fetchMyBag.mockReset();
    mocks.fetchMyBag.mockResolvedValue([]);
  });

  it('reuses the locked bag environment and honest incomplete states', async () => {
    const html = await renderMyBag();

    expect(html).toContain('ux5-bag-environment');
    expect(html).toContain('ux5-status-rail');
    expect(html).toContain('ux5-bag-visual');
    expect((html.match(/data-bag-category=/g) ?? []).length).toBe(7);
    expect(html).toContain('Choose My Tee Box');
    expect(html).toContain('Customize My Bag');
    expect(html).toContain('How My Bag Works');
    expect(html).toContain('Not evaluated');
    expect(html).not.toContain('Optimized');
    expect(html).not.toContain('Bag Score');
  });

  it('does not turn known equipment identity into an unsupported positive fit claim', async () => {
    mocks.fetchMyBag.mockResolvedValue([
      {
        bagItemId: 'bag-driver',
        category: 'DRIVER',
        equipmentName: 'Known Driver',
        equipmentConfigurationId: 'driver-config',
        configuration: { configurationId: 'driver-config', name: 'Known Driver Configuration' },
        state: 'KNOWN',
        fittingHref: '/portal/insights?fit=driver',
      },
    ]);

    const html = await renderMyBag();
    expect(html).toContain('Known Driver');
    expect(html).toMatch(/data-bag-category="driver"[^>]*data-status="WATCHING"/);
    expect(html).not.toMatch(/data-bag-category="driver"[^>]*data-status="GOOD"/);
  });
});
