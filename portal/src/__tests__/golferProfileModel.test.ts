import { describe, expect, it } from 'vitest';
import {
  PROFILE_HOME_AREAS,
  PROFILE_WORKSPACES,
  MISS_SHAPES,
  profileWorkspaceFromParams,
  dataQualityLabel,
} from '../profile/model';

describe('GAL UX10.02 Golfer Profile model', () => {
  it('locks the six Profile Home areas', () => {
    expect(PROFILE_HOME_AREAS.map((area) => area.key)).toEqual([
      'you', 'game', 'swing', 'miss', 'environment', 'connected',
    ]);
  });

  it('locks the focused workspace routes', () => {
    expect(PROFILE_WORKSPACES).toEqual([
      'home', 'you', 'game', 'swing', 'miss', 'environment', 'connected',
    ]);
    expect(profileWorkspaceFromParams(new URLSearchParams('section=swing'))).toBe('swing');
    expect(profileWorkspaceFromParams(new URLSearchParams('section=unknown'))).toBe('home');
  });

  it('uses the approved miss-shape vocabulary', () => {
    expect(MISS_SHAPES).toEqual(['Hook', 'Pull', 'Straight', 'Push', 'Slice']);
  });

  it('maps profile evidence to the locked data-quality language without inventing confidence', () => {
    expect(dataQualityLabel({ source: 'TrackMan', source_category: 'measured' })).toBe('Measured');
    expect(dataQualityLabel({ source: 'Arccos', source_category: 'observed' })).toBe('Observed');
    expect(dataQualityLabel({ source: 'Golfer', source_category: 'self_reported' })).toBe('Self-Reported');
    expect(dataQualityLabel({ source: 'GAL model', source_category: 'inferred' })).toBe('Inferred / Estimated');
    expect(dataQualityLabel({ source: null, source_category: null })).toBe('Source not classified');
  });
});
