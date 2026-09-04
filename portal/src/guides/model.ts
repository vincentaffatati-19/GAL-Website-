import type { AiFitEquipmentRead, GuideEquipmentRead } from '../equipment/types';

export function driverGuideRows(rows: GuideEquipmentRead[]): GuideEquipmentRead[] {
  return rows.filter((row) => row.item.category === 'DRIVER');
}

export function equipmentTruthMatches(guide: GuideEquipmentRead, fit: AiFitEquipmentRead): boolean {
  return guide.item.equipmentFamilyId === fit.item.equipmentFamilyId
    && guide.item.canonicalProductId === fit.item.canonicalProductId
    && guide.item.canonicalBrandId === fit.item.canonicalBrandId
    && JSON.stringify(guide.item.characteristics) === JSON.stringify(fit.item.characteristics);
}
