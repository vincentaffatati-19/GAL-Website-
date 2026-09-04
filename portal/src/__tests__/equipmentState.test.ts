import { describe, expect, it } from 'vitest';
import { stateFromConfiguration, stateFromError } from '../equipment/state';

const readyConfiguration = {
  configurationId: 'c1',
  equipmentConfigurationId: 'GAL-EQCFG-1',
  configurationKey: 'standard',
  name: 'Standard',
  supportState: 'FACTORY_STANDARD' as const,
  readiness: 'AI_FIT_READY' as const,
  limitedEvidence: false,
  blockingGapCount: 0,
};

describe('consumer equipment state', () => {
  it('keeps limited evidence distinct from ready', () => {
    expect(stateFromConfiguration({ ...readyConfiguration, readiness: 'AI_FIT_LIMITED', limitedEvidence: true, blockingGapCount: 3 })).toEqual({
      kind: 'limited',
      blockingGapCount: 3,
    });
    expect(stateFromConfiguration(readyConfiguration)).toEqual({ kind: 'ready' });
  });

  it('maps auth-required failures to unauthorized', () => {
    expect(stateFromError({ code: 'AUTH_REQUIRED' })).toEqual({ kind: 'unauthorized' });
  });
});
