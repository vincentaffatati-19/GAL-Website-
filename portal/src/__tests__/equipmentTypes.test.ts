import { describe, expect, it } from 'vitest';
import type { EquipmentRecommendation } from '../equipment/types';

describe('shared equipment types', () => {
  it('allows keep/adjust/reconfigure/replace as peer analytical actions', () => {
    const actions: EquipmentRecommendation['action'][] = ['KEEP', 'ADJUST', 'RECONFIGURE', 'REPLACE', 'COMPARE_TEST'];
    expect(actions).toEqual(['KEEP', 'ADJUST', 'RECONFIGURE', 'REPLACE', 'COMPARE_TEST']);
  });
});
