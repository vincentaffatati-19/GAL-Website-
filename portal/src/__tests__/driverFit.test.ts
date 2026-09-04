import { describe, expect, it } from 'vitest';
import { buildDriverFitViewModel } from '../fitting/driver/model';
import { buildDriverTargetProfile } from '../fitting/driver/targets';

const readyDriver = {
  item: {
    familyId: 'f1', equipmentFamilyId: 'GAL-EQF-1', canonicalProductId: 'p1', canonicalBrandId: 'b1',
    category: 'DRIVER' as const, familyName: 'Example Driver', lifecycleState: 'CURRENT', characteristics: [],
  },
  configuration: {
    configurationId: 'c1', equipmentConfigurationId: 'GAL-EQCFG-1', configurationKey: 'std', name: 'Standard',
    supportState: 'FACTORY_STANDARD' as const, readiness: 'AI_FIT_READY' as const, limitedEvidence: false, blockingGapCount: 0,
  },
};

describe('Driver AI fitting', () => {
  it('requires evidence before candidate ranking', () => {
    const model = buildDriverFitViewModel(buildDriverTargetProfile([]), [readyDriver]);
    expect(model.missingEvidence).toBe(true);
    expect(model.candidates).toHaveLength(1);
  });

  it('keeps target characteristics independent from brand/model candidates', () => {
    const targets = buildDriverTargetProfile([{ key: 'spin', desiredDirection: 'LOWER', rationale: 'Measured spin is above target window', evidenceState: 'KNOWN' }]);
    const model = buildDriverFitViewModel(targets, [readyDriver]);
    expect(model.targetProfile.characteristics[0].key).toBe('spin');
    expect(JSON.stringify(model.targetProfile)).not.toContain('Example Driver');
  });

  it('keeps limited evidence distinct from ready', () => {
    const limited = { ...readyDriver, configuration: { ...readyDriver.configuration, readiness: 'AI_FIT_LIMITED' as const, limitedEvidence: true, blockingGapCount: 2 } };
    const model = buildDriverFitViewModel(buildDriverTargetProfile([{ key: 'launch', desiredDirection: 'MATCH', rationale: 'Measured', evidenceState: 'LIMITED' }]), [limited]);
    expect(model.limited).toBe(true);
    expect(model.candidates[0].configuration.blockingGapCount).toBe(2);
  });
});
