import type { AiFitEquipmentRead } from '../../equipment/types';
import type { DriverTargetProfile } from './targets';

export interface DriverFitViewModel {
  targetProfile: DriverTargetProfile;
  candidates: AiFitEquipmentRead[];
  limited: boolean;
  missingEvidence: boolean;
}

export function buildDriverFitViewModel(targetProfile: DriverTargetProfile, equipment: AiFitEquipmentRead[]): DriverFitViewModel {
  const candidates = equipment.filter((read) => read.item.category === 'DRIVER' && (read.configuration.readiness === 'AI_FIT_READY' || read.configuration.readiness === 'AI_FIT_LIMITED'));
  return {
    targetProfile,
    candidates,
    limited: candidates.some((candidate) => candidate.configuration.readiness === 'AI_FIT_LIMITED'),
    missingEvidence: targetProfile.characteristics.length === 0,
  };
}
