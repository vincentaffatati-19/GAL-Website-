import { describe, expect, it } from 'vitest';
import { driverGuideRows, equipmentTruthMatches } from '../guides/model';

const item = { familyId:'f1', equipmentFamilyId:'GAL-EQF-1', canonicalProductId:'p1', canonicalBrandId:'b1', category:'DRIVER' as const, familyName:'Driver One', lifecycleState:'CURRENT', characteristics:[{ attributeKey:'loft', value:10.5, unit:'deg', claimState:'KNOWN', methodologyVersion:null }] };

describe('Driver Guide shared truth', () => {
  it('filters the shared public contract to Driver without a second product dataset', () => {
    expect(driverGuideRows([{ item, readiness:'GUIDE_READY', mediaAssets:[] }])).toHaveLength(1);
  });

  it('detects contradiction between Guide and AI Fit canonical truth', () => {
    const guide = { item, readiness:'GUIDE_READY' as const, mediaAssets:[] };
    const fit = { item, configuration:{ configurationId:'c1', equipmentConfigurationId:'cfg1', configurationKey:'std', name:'Std', supportState:'FACTORY_STANDARD' as const, readiness:'AI_FIT_READY' as const, limitedEvidence:false, blockingGapCount:0 } };
    expect(equipmentTruthMatches(guide, fit)).toBe(true);
    expect(equipmentTruthMatches(guide, { ...fit, item:{ ...item, canonicalProductId:'different' } })).toBe(false);
  });
});
