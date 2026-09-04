import type { RecommendationAction } from '../../equipment/types';
import type { DriverFitViewModel } from './model';

export function deriveDriverActions(model: DriverFitViewModel, hasCurrentConfiguration: boolean): RecommendationAction[] {
  if (model.missingEvidence) return [];
  const actions: RecommendationAction[] = [];
  if (hasCurrentConfiguration) actions.push('KEEP', 'ADJUST', 'RECONFIGURE');
  if (model.candidates.length) actions.push('REPLACE');
  return [...new Set(actions)];
}
