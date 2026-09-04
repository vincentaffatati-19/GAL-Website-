import { describe, expect, it } from 'vitest';
import { projectBagItems } from '../bag/model';

describe('My Bag governed identity', () => {
  it('does not infer a good fit when governed configuration is missing', () => {
    const [item] = projectBagItems([{ bag_item_id: 'BI-1', category: 'Driver', slot_label: 'Driver', display_snapshot: {} }], []);
    expect(item.state).toBe('MISSING_CONFIGURATION');
    expect(item.configuration).toBeUndefined();
  });

  it('marks a bag item known from governed configuration identity even when fit detail is not returned', () => {
    const [item] = projectBagItems([{ bag_item_id: 'BI-2', category: 'Driver', slot_label: 'Driver', display_snapshot: {}, equipment_configuration_id: 'cfg-1' }], []);
    expect(item.state).toBe('KNOWN');
    expect(item.equipmentConfigurationId).toBe('cfg-1');
  });
});
