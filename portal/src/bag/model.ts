import { normalizeEquipmentCategory } from '../equipment/categories';
import type { AiFitEquipmentRead, EquipmentCategory, EquipmentConfiguration } from '../equipment/types';

export interface BagEquipmentView {
  bagItemId: string;
  category: EquipmentCategory;
  equipmentName: string;
  equipmentConfigurationId: string | null;
  configuration?: EquipmentConfiguration;
  state: 'KNOWN' | 'MISSING_CONFIGURATION';
  fittingHref?: string;
}

export type BagItemRow = Record<string, unknown>;

function equipmentName(row: BagItemRow): string {
  const snapshot = row.display_snapshot;
  if (snapshot && typeof snapshot === 'object') {
    const raw = snapshot as Record<string, unknown>;
    for (const key of ['display_name', 'product_name', 'model_name', 'name']) {
      if (typeof raw[key] === 'string' && raw[key]) return raw[key] as string;
    }
  }
  return typeof row.slot_label === 'string' && row.slot_label ? row.slot_label : 'Equipment details needed';
}

export function projectBagItems(rows: BagItemRow[], aiFit: AiFitEquipmentRead[]): BagEquipmentView[] {
  const byConfiguration = new Map(aiFit.map((read) => [read.configuration.configurationId, read.configuration]));
  return rows.map((row) => {
    const category = normalizeEquipmentCategory(row.category);
    const configurationId = typeof row.equipment_configuration_id === 'string' && row.equipment_configuration_id
      ? row.equipment_configuration_id
      : null;
    const configuration = configurationId ? byConfiguration.get(configurationId) : undefined;
    const state = configurationId ? 'KNOWN' : 'MISSING_CONFIGURATION';
    return {
      bagItemId: String(row.bag_item_id ?? row.id ?? ''),
      category,
      equipmentName: equipmentName(row),
      equipmentConfigurationId: configurationId,
      configuration,
      state,
      fittingHref: category === 'DRIVER' ? '/portal/insights?fit=driver' : undefined,
    };
  });
}
