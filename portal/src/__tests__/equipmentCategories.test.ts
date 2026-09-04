import { describe, expect, it } from 'vitest';
import { CATEGORY_REGISTRY, normalizeEquipmentCategory } from '../equipment/categories';

describe('equipment category registry', () => {
  it('declares all seven GAL categories and activates only Driver', () => {
    expect(Object.keys(CATEGORY_REGISTRY)).toHaveLength(7);
    expect(CATEGORY_REGISTRY.DRIVER.active).toBe(true);
    expect(Object.entries(CATEGORY_REGISTRY).filter(([, value]) => value.active).map(([key]) => key)).toEqual(['DRIVER']);
  });

  it('normalizes governed category labels without inventing categories', () => {
    expect(normalizeEquipmentCategory('Driver')).toBe('DRIVER');
    expect(normalizeEquipmentCategory('Fairway Woods')).toBe('FAIRWAY_WOOD');
    expect(normalizeEquipmentCategory('golf_ball')).toBe('GOLF_BALL');
    expect(() => normalizeEquipmentCategory('Training Aid')).toThrow('Unsupported equipment category');
  });
});
