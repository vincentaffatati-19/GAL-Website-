import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  fetchGolferInsights: vi.fn(),
}));

vi.mock('../surfaces/insights', () => ({
  fetchGolferInsights: mocks.fetchGolferInsights,
}));

import { renderTodaySurface } from '../surfaces/today';

describe('RC-UX1 Today tee-box experience', () => {
  beforeEach(() => {
    mocks.fetchGolferInsights.mockReset();
    mocks.fetchGolferInsights.mockResolvedValue([]);
  });

  it('renders the locked My GAL tee-box composition without invented metrics', async () => {
    const html = await renderTodaySurface();

    expect(html).toContain('tee-box-hero');
    expect(html).toContain('bag-hero');
    expect(html).toContain('Bag Status');
    expect(html).toContain('Next Opportunity');
    expect(html).toContain('Bag Value');
    expect(html).toContain('How My Bag Works');
    expect(html).toContain('Quick Actions');
    expect(html).toContain('Recent Insight');
    expect(html).toContain('Progress at a Glance');
    expect(html).toContain('GAL needs more information');

    expect(html).not.toContain('12 yards');
    expect(html).not.toContain('$3,840');
    expect(html).not.toContain('71%');
  });

  it('uses governed active Driver insight copy but does not invent quantified impact', async () => {
    mocks.fetchGolferInsights.mockResolvedValue([
      {
        insight_id: 'i1',
        insight_domain: 'EQUIPMENT',
        subject_type: 'CLUB',
        subject_key: 'DRIVER',
        scope_key: 'driver',
        status: 'ACTIVE',
        golfer_message: 'Your current Driver configuration deserves review.',
      },
    ]);

    const html = await renderTodaySurface();
    expect(html).toContain('GAL Sees a Driver Opportunity');
    expect(html).toContain('Your current Driver configuration deserves review.');
    expect(html).not.toMatch(/\b\d+\s*yards?\b/i);
  });
});
