export interface ProfileFactRow {
  fact_key: string;
  fact_value: unknown;
  source: string | null;
  source_category: string | null;
  confidence: number | null;
  user_confirmed: boolean | null;
  scope: string | null;
  stale_after_days: number | null;
  observed_at: string | null;
  updated_at: string | null;
  source_reference: string | null;
}

export type ProfileAreaKey = 'you' | 'game' | 'swing' | 'miss' | 'environment';

export interface ProfileAreaSummary {
  key: ProfileAreaKey;
  label: string;
  facts: ProfileFactRow[];
}

const AREA_MATCHERS: Record<ProfileAreaKey, string[]> = {
  you: ['height', 'wrist', 'hand', 'glove', 'handed', 'age', 'gender', 'presentation'],
  game: ['handicap', 'score', 'round', 'goal', 'priority', 'frequency', 'skill'],
  swing: ['speed', 'launch', 'spin', 'attack', 'path', 'face', 'carry', 'tempo', 'transition'],
  miss: ['miss', 'shape', 'strike', 'dispersion', 'curve'],
  environment: ['environment', 'elevation', 'temperature', 'wind', 'firmness', 'green', 'location', 'course'],
};

const AREA_LABELS: Record<ProfileAreaKey, string> = {
  you: 'You',
  game: 'Your Game',
  swing: 'Your Swing',
  miss: 'Your Miss',
  environment: 'Where You Play',
};

export function profileAreaForFact(factKey: string): ProfileAreaKey | null {
  const normalized = factKey.toLowerCase();
  for (const [area, terms] of Object.entries(AREA_MATCHERS) as Array<[ProfileAreaKey, string[]]>) {
    if (terms.some((term) => normalized.includes(term))) return area;
  }
  return null;
}

export function summarizeProfileAreas(facts: ProfileFactRow[]): ProfileAreaSummary[] {
  return (Object.keys(AREA_LABELS) as ProfileAreaKey[]).map((key) => ({
    key,
    label: AREA_LABELS[key],
    facts: facts.filter((fact) => profileAreaForFact(fact.fact_key) === key),
  }));
}

export function completedProfileAreaCount(facts: ProfileFactRow[]): number {
  return summarizeProfileAreas(facts).filter((area) => area.facts.length > 0).length;
}
