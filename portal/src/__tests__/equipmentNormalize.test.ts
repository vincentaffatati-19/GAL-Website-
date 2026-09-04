import { describe, expect, it } from 'vitest';
import { normalizeAiFitRows, normalizeGuideRows } from '../equipment/normalize';

const baseRow = {
  family_id: 'family-1',
  equipment_family_id: 'GAL-EQF-1',
  canonical_product_id: 'product-1',
  canonical_brand_id: 'brand-1',
  category: 'Driver',
  family_name: 'Example Driver',
  lifecycle_state: 'CURRENT',
  approved_characteristics: [{
    attribute_key: 'head_volume_cc',
    value: 460,
    unit: 'cc',
    claim_state: 'KNOWN',
    methodology_version: 'v1',
  }],
};

describe('governed equipment normalizers', () => {
  it('normalizes public Guide rows without creating recommendations', () => {
    const [result] = normalizeGuideRows([{ ...baseRow, readiness_state: 'GUIDE_READY', media_assets: [] }]);
    expect(result.item.familyName).toBe('Example Driver');
    expect(result.item.category).toBe('DRIVER');
    expect(result.readiness).toBe('GUIDE_READY');
    expect(result).not.toHaveProperty('recommendation');
    expect(result).not.toHaveProperty('fitScore');
  });

  it('preserves AI_FIT_LIMITED and configuration readiness', () => {
    const [result] = normalizeAiFitRows([{
      ...baseRow,
      readiness_state: 'AI_FIT_LIMITED',
      blocking_gap_count: 2,
      configuration_id: 'config-1',
      equipment_configuration_id: 'GAL-EQCFG-1',
      configuration_key: '10.5-standard',
      configuration_name: '10.5 Standard',
      support_state: 'FACTORY_STANDARD',
      limited_evidence: true,
    }]);

    expect(result.configuration.readiness).toBe('AI_FIT_LIMITED');
    expect(result.configuration.limitedEvidence).toBe(true);
    expect(result.configuration.blockingGapCount).toBe(2);
    expect(result).not.toHaveProperty('fitScore');
    expect(result).not.toHaveProperty('confidence');
  });
});
