import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  fetchGolferInsights: vi.fn(),
}));

vi.mock('../surfaces/insights', () => ({
  fetchGolferInsights: mocks.fetchGolferInsights,
}));

import { renderTodaySurface } from '../surfaces/today';

describe('GAL UX10 Today intelligence dashboard', () => {
  beforeEach(() => {
    mocks.fetchGolferInsights.mockReset();
    mocks.fetchGolferInsights.mockResolvedValue([]);
  });

  it('renders the locked bag-first dashboard with independent presentation choices and no invented metrics', async () => {
    const html = await renderTodaySurface();

    expect(html).toContain('ux10-dashboard');
    expect(html).toContain('ux10-bag-environment');
    expect(html).toContain('ux10-status-rail');
    expect(html).toContain('ux10-tee-box-background');
    expect(html).toContain('ux10-bag-image');
    expect((html.match(/data-bag-category=/g) ?? []).length).toBe(7);
    expect(html).toContain('Choose My Tee Box');
    expect(html).toContain('Changes the background only.');
    expect(html).toContain('Bag Visual');
    expect(html).toContain('Customize My Bag');
    expect(html).toContain('Bag Status');
    expect(html).toContain('Next Opportunity');
    expect(html).toContain('Bag Value');
    expect(html).toContain('How My Bag Works');
    expect(html).toContain('Quick Actions');
    expect(html).toContain('Recent Insight');
    expect(html).toContain('Progress at a Glance');
    expect(html).toContain('How It Works');
    expect(html).toContain('Works for Every Club');
    expect(html).toContain('Not evaluated');
    expect(html).toContain('GAL needs more information');

    for (const forbidden of ['12 yards', '$3,840', '71%', '94 mph', '247 yds', '+11.3 yds']) {
      expect(html).not.toContain(forbidden);
    }
  });

  it('marks Driver as needing attention only when a governed active Driver insight exists', async () => {
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
    expect(html).toMatch(/data-bag-category="driver"[^>]*data-status="NEEDS_ATTENTION"/);
    expect(html).not.toMatch(/\b\d+\s*yards?\b/i);
  });
});
