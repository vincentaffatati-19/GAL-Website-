import type { ProfileFactRow } from './types';

export type ProfileWorkspace = 'home' | 'you' | 'game' | 'swing' | 'miss' | 'environment' | 'connected';

export const PROFILE_WORKSPACES: ProfileWorkspace[] = [
  'home',
  'you',
  'game',
  'swing',
  'miss',
  'environment',
  'connected',
];

export const PROFILE_HOME_AREAS: Array<{ key: Exclude<ProfileWorkspace, 'home'>; label: string; description: string }> = [
  { key: 'you', label: 'You', description: 'Body measurements and handedness' },
  { key: 'game', label: 'Your Game', description: 'Handicap, scoring and goals' },
  { key: 'swing', label: 'Your Swing', description: 'Speed, carry, tempo and ball flight' },
  { key: 'miss', label: 'Your Miss', description: 'Direction, shape and strike location' },
  { key: 'environment', label: 'Where You Play', description: 'Location, altitude and conditions' },
  { key: 'connected', label: 'Connected Golf', description: 'Approved sources and imports' },
];

export const MISS_SHAPES = ['Hook', 'Pull', 'Straight', 'Push', 'Slice'] as const;
export const MISS_DIRECTIONS = ['Left', 'Straight', 'Right', 'Short', 'Long'] as const;
export const STRIKE_LOCATIONS = ['High', 'Heel', 'Center', 'Toe', 'Low'] as const;

export function profileWorkspaceFromParams(params: URLSearchParams): ProfileWorkspace {
  const requested = (params.get('section') ?? 'home').toLowerCase();
  return PROFILE_WORKSPACES.includes(requested as ProfileWorkspace) ? requested as ProfileWorkspace : 'home';
}

export function dataQualityLabel(fact: Pick<ProfileFactRow, 'source' | 'source_category'>): string {
  const category = (fact.source_category ?? '').trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  if (['measured', 'measurement', 'instrument', 'launch_monitor'].includes(category)) return 'Measured';
  if (['observed', 'on_course', 'oncourse', 'session'].includes(category)) return 'Observed';
  if (['self_reported', 'selfreported', 'golfer_provided', 'user'].includes(category)) return 'Self-Reported';
  if (['inferred', 'estimated', 'model', 'derived'].includes(category)) return 'Inferred / Estimated';
  return 'Source not classified';
}

export function normalizedFactKey(fact: ProfileFactRow): string {
  return fact.fact_key.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

export function factsMatching(facts: ProfileFactRow[], terms: string[]): ProfileFactRow[] {
  return facts.filter((fact) => terms.some((term) => normalizedFactKey(fact).includes(term.toLowerCase())));
}

export function firstFactMatching(facts: ProfileFactRow[], terms: string[]): ProfileFactRow | null {
  return factsMatching(facts, terms)[0] ?? null;
}

export function hasExternalSource(fact: ProfileFactRow): boolean {
  const category = (fact.source_category ?? '').toLowerCase();
  const source = (fact.source ?? '').toLowerCase();
  return !category.includes('self') && !source.includes('golfer') && !source.includes('user') && Boolean(fact.source || fact.source_category);
}
