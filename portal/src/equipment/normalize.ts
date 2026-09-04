import { normalizeEquipmentCategory } from './categories';
import type {
  AiFitEquipmentRead,
  EquipmentCharacteristic,
  EquipmentItem,
  EquipmentSupportState,
  GuideEquipmentRead,
} from './types';

export type RpcRow = Record<string, unknown>;

function requireString(row: RpcRow, key: string): string {
  const value = row[key];
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`Equipment contract field ${key} is missing`);
  }
  return value;
}

function nullableString(value: unknown): string | null {
  return typeof value === 'string' && value.trim() !== '' ? value : null;
}

function numberOrZero(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

function parseJsonArray(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value) as unknown;
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

function normalizeCharacteristics(value: unknown): EquipmentCharacteristic[] {
  return parseJsonArray(value).flatMap((entry) => {
    if (!entry || typeof entry !== 'object') return [];
    const raw = entry as Record<string, unknown>;
    const attributeKey = raw.attribute_key;
    if (typeof attributeKey !== 'string' || attributeKey.trim() === '') return [];
    return [{
      attributeKey,
      value: raw.value,
      unit: nullableString(raw.unit),
      claimState: nullableString(raw.claim_state) ?? 'UNKNOWN',
      methodologyVersion: nullableString(raw.methodology_version),
    }];
  });
}

function normalizeItem(row: RpcRow): EquipmentItem {
  return {
    familyId: requireString(row, 'family_id'),
    equipmentFamilyId: requireString(row, 'equipment_family_id'),
    canonicalProductId: nullableString(row.canonical_product_id),
    canonicalBrandId: nullableString(row.canonical_brand_id),
    category: normalizeEquipmentCategory(row.category),
    familyName: requireString(row, 'family_name'),
    lifecycleState: requireString(row, 'lifecycle_state'),
    characteristics: normalizeCharacteristics(row.approved_characteristics),
  };
}

function normalizeSupportState(value: unknown): EquipmentSupportState {
  if (value === 'FACTORY_STANDARD' || value === 'FACTORY_CUSTOM' || value === 'AFTERMARKET_VALID') return value;
  throw new Error(`Unsupported equipment support state: ${String(value)}`);
}

export function normalizeGuideRows(rows: RpcRow[]): GuideEquipmentRead[] {
  return rows.map((row) => {
    const readiness = requireString(row, 'readiness_state');
    if (readiness !== 'GUIDE_READY' && readiness !== 'AI_FIT_READY') {
      throw new Error(`Guide contract returned unsupported readiness: ${readiness}`);
    }
    return {
      item: normalizeItem(row),
      readiness,
      mediaAssets: parseJsonArray(row.media_assets),
    };
  });
}

export function normalizeAiFitRows(rows: RpcRow[]): AiFitEquipmentRead[] {
  return rows.map((row) => {
    const readiness = requireString(row, 'readiness_state');
    if (readiness !== 'AI_FIT_LIMITED' && readiness !== 'AI_FIT_READY') {
      throw new Error(`AI Fit contract returned unsupported readiness: ${readiness}`);
    }

    return {
      item: normalizeItem(row),
      configuration: {
        configurationId: requireString(row, 'configuration_id'),
        equipmentConfigurationId: requireString(row, 'equipment_configuration_id'),
        configurationKey: requireString(row, 'configuration_key'),
        name: requireString(row, 'configuration_name'),
        supportState: normalizeSupportState(row.support_state),
        readiness,
        limitedEvidence: row.limited_evidence === true || readiness === 'AI_FIT_LIMITED',
        blockingGapCount: numberOrZero(row.blocking_gap_count),
      },
    };
  });
}
