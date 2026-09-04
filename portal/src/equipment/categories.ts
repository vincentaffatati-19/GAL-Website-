import type { EquipmentCategory } from './types';

export interface EquipmentCategoryDefinition {
  id: EquipmentCategory;
  label: string;
  active: boolean;
}

export const CATEGORY_REGISTRY: Record<EquipmentCategory, EquipmentCategoryDefinition> = {
  DRIVER: { id: 'DRIVER', label: 'Driver', active: true },
  FAIRWAY_WOOD: { id: 'FAIRWAY_WOOD', label: 'Fairway Wood', active: false },
  HYBRID: { id: 'HYBRID', label: 'Hybrid', active: false },
  IRON: { id: 'IRON', label: 'Irons', active: false },
  WEDGE: { id: 'WEDGE', label: 'Wedges', active: false },
  PUTTER: { id: 'PUTTER', label: 'Putter', active: false },
  GOLF_BALL: { id: 'GOLF_BALL', label: 'Golf Ball', active: false },
};

const CATEGORY_ALIASES: Record<string, EquipmentCategory> = {
  driver: 'DRIVER',
  drivers: 'DRIVER',
  fairwaywood: 'FAIRWAY_WOOD',
  fairwaywoods: 'FAIRWAY_WOOD',
  fairway: 'FAIRWAY_WOOD',
  wood: 'FAIRWAY_WOOD',
  woods: 'FAIRWAY_WOOD',
  hybrid: 'HYBRID',
  hybrids: 'HYBRID',
  iron: 'IRON',
  irons: 'IRON',
  wedge: 'WEDGE',
  wedges: 'WEDGE',
  putter: 'PUTTER',
  putters: 'PUTTER',
  golfball: 'GOLF_BALL',
  golfballs: 'GOLF_BALL',
  ball: 'GOLF_BALL',
  balls: 'GOLF_BALL',
};

export function normalizeEquipmentCategory(value: unknown): EquipmentCategory {
  if (typeof value !== 'string') throw new Error('Equipment category is missing');
  const key = value.trim().toLowerCase().replace(/[^a-z0-9]/g, '');
  const category = CATEGORY_ALIASES[key];
  if (!category) throw new Error(`Unsupported equipment category: ${value}`);
  return category;
}

export function isCategoryActive(category: EquipmentCategory): boolean {
  return CATEGORY_REGISTRY[category].active;
}
