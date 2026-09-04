import { describe, expect, it } from 'vitest';
import { insightLabel } from '../surfaces/insights';

describe('My GAL surface language', () => {
  it('maps governed insight lifecycle into golfer-safe labels', () => {
    expect(insightLabel('ACTIVE')).toBe('Needs Attention');
    expect(insightLabel('ACKNOWLEDGED')).toBe('Watching');
    expect(insightLabel('RESOLVED')).toBe('Solved');
    expect(insightLabel('REGRESSED')).toBe('Came Back');
    expect(insightLabel('EVIDENCE_PENDING')).toBe('Checking Progress');
    expect(insightLabel('INEFFECTIVE')).toBe('Still Needs Attention');
  });

  it('does not promote suppressed or expired insight states', () => {
    expect(insightLabel('SUPPRESSED')).toBeNull();
    expect(insightLabel('EXPIRED')).toBeNull();
  });
});
