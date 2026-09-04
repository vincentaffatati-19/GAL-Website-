import type { EquipmentConfiguration } from './types';

export type ConsumerEquipmentState =
  | { kind: 'ready' }
  | { kind: 'limited'; blockingGapCount: number }
  | { kind: 'missing-profile'; fields: string[] }
  | { kind: 'missing-configuration' }
  | { kind: 'stale'; reason: string }
  | { kind: 'compatibility-unresolved' }
  | { kind: 'not-ready'; useCase: 'GUIDE' | 'AI_FIT' }
  | { kind: 'disconnected-source'; source: string }
  | { kind: 'unauthorized' }
  | { kind: 'error'; message: string };

export function stateFromConfiguration(configuration: EquipmentConfiguration): ConsumerEquipmentState {
  if (configuration.readiness === 'AI_FIT_LIMITED' || configuration.limitedEvidence) {
    return { kind: 'limited', blockingGapCount: configuration.blockingGapCount };
  }
  return { kind: 'ready' };
}

export function stateFromError(error: unknown): ConsumerEquipmentState {
  if (error && typeof error === 'object' && 'code' in error && error.code === 'AUTH_REQUIRED') {
    return { kind: 'unauthorized' };
  }
  return {
    kind: 'error',
    message: error instanceof Error ? error.message : 'Equipment intelligence is temporarily unavailable',
  };
}
