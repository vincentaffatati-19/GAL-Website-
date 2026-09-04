export interface Entitlements {
  extendedHistory: boolean;
  advancedExplanations: boolean;
  premiumFittingWorkflows: boolean;
}

export type MembershipLevel = 'REGISTERED' | 'SUBSCRIBER';

export function entitlementsFor(level: MembershipLevel): Entitlements {
  return level === 'SUBSCRIBER'
    ? { extendedHistory: true, advancedExplanations: true, premiumFittingWorkflows: true }
    : { extendedHistory: false, advancedExplanations: false, premiumFittingWorkflows: false };
}

export function preserveAnalyticalOrder<T extends { id?: string }>(items: T[], _entitlements: Entitlements): T[] {
  return [...items];
}
