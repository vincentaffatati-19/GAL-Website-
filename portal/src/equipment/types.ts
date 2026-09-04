export type EquipmentCategory =
  | 'DRIVER'
  | 'FAIRWAY_WOOD'
  | 'HYBRID'
  | 'IRON'
  | 'WEDGE'
  | 'PUTTER'
  | 'GOLF_BALL';

export type EquipmentReadiness = 'GUIDE_READY' | 'AI_FIT_LIMITED' | 'AI_FIT_READY';

export type EquipmentSupportState =
  | 'FACTORY_STANDARD'
  | 'FACTORY_CUSTOM'
  | 'AFTERMARKET_VALID';

export interface EquipmentCharacteristic {
  attributeKey: string;
  value: unknown;
  unit: string | null;
  claimState: string;
  methodologyVersion: string | null;
}

export interface EquipmentItem {
  familyId: string;
  equipmentFamilyId: string;
  canonicalProductId: string | null;
  canonicalBrandId: string | null;
  category: EquipmentCategory;
  familyName: string;
  lifecycleState: string;
  characteristics: EquipmentCharacteristic[];
}

export interface EquipmentConfiguration {
  configurationId: string;
  equipmentConfigurationId: string;
  configurationKey: string;
  name: string;
  supportState: EquipmentSupportState;
  readiness: 'AI_FIT_LIMITED' | 'AI_FIT_READY';
  limitedEvidence: boolean;
  blockingGapCount: number;
}

export type EquipmentOpportunityEvidence =
  | 'PROFILE_FIT'
  | 'PERFORMANCE_OPPORTUNITY'
  | 'EQUIPMENT_ATTRIBUTION';

export interface EquipmentOpportunity {
  category: EquipmentCategory;
  equipment: EquipmentItem;
  evidenceLevel: EquipmentOpportunityEvidence;
  state: 'NEEDS_ATTENTION' | 'WATCHING' | 'CHECKING_PROGRESS' | 'SOLVED' | 'CAME_BACK' | 'STILL_NEEDS_ATTENTION';
  headline: string;
  explanation: string;
}

export type RecommendationAction = 'KEEP' | 'ADJUST' | 'RECONFIGURE' | 'REPLACE' | 'COMPARE_TEST';

export interface EquipmentRecommendation {
  category: EquipmentCategory;
  action: RecommendationAction;
  targetCharacteristics: EquipmentCharacteristic[];
  candidateConfiguration: EquipmentConfiguration | null;
  rationale: string[];
}

export interface GuideEquipmentRead {
  item: EquipmentItem;
  readiness: 'GUIDE_READY' | 'AI_FIT_READY';
  mediaAssets: unknown[];
}

export interface AiFitEquipmentRead {
  item: EquipmentItem;
  configuration: EquipmentConfiguration;
}
