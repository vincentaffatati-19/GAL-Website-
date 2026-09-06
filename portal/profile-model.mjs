export const PROFILE_AREAS = Object.freeze([
  { id: 'you', label: 'You', prefixes: ['profile.'] },
  { id: 'game', label: 'Your Game', prefixes: ['game.'] },
  { id: 'swing', label: 'Your Swing', prefixes: ['swing.'] },
  { id: 'miss', label: 'Your Miss', prefixes: ['miss.'] },
  { id: 'play', label: 'Where You Play', prefixes: ['play.'] },
  { id: 'connected', label: 'Connected Golf', prefixes: ['connection.'] },
]);

export const MISS_FINISH_VALUES = Object.freeze(['Left', 'Straight', 'Right', 'Short', 'Long']);
export const MISS_SHAPE_VALUES = Object.freeze(['Hook', 'Pull', 'Straight', 'Push', 'Slice']);

export const PROVIDER_CAPABILITIES = Object.freeze([
  Object.freeze({
    id: 'toptracer', label: 'Toptracer / Topgolf', status: 'PARTNERSHIP_REQUIRED',
    connectAvailable: false, importAvailable: false,
    detail: 'Tier 1 strategic integration target. Partnership/API access is required before GAL can connect.'
  }),
  Object.freeze({
    id: 'trackman', label: 'TrackMan / Launch Monitor', status: 'NOT_CONNECTED',
    connectAvailable: false, importAvailable: true,
    detail: 'No approved live GAL connection is configured. A governed launch-monitor file can be imported.'
  }),
  Object.freeze({
    id: 'ghin', label: 'Handicap Source / GHIN', status: 'NOT_CONNECTED',
    connectAvailable: false, importAvailable: false,
    detail: 'No approved live GAL handicap-source integration is configured.'
  }),
  Object.freeze({
    id: 'arccos', label: 'On-Course Performance', status: 'UNAVAILABLE',
    connectAvailable: false, importAvailable: false,
    detail: 'An approved on-course performance integration is not available.'
  }),
  Object.freeze({
    id: 'garmin', label: 'Golf Device / App', status: 'UNAVAILABLE',
    connectAvailable: false, importAvailable: false,
    detail: 'An approved golf-device/app integration is not available.'
  }),
  Object.freeze({
    id: 'other_launch_monitor', label: 'Other Launch Monitor', status: 'IMPORT_AVAILABLE',
    connectAvailable: false, importAvailable: true,
    detail: 'Manual import is available for supported launch-monitor CSV data.'
  }),
]);

export function normalizeFactInput(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (typeof value === 'string') {
    const trimmed = value.trim();
    return trimmed.length ? trimmed : null;
  }
  return value;
}

export function buildProfileFactRows({ userId, facts, observedAt = new Date().toISOString() }) {
  if (!userId) throw new Error('userId is required');
  if (!Array.isArray(facts)) throw new Error('facts must be an array');

  return facts.flatMap((fact) => {
    const factKey = String(fact?.factKey || '').trim();
    if (!factKey) return [];
    const value = normalizeFactInput(fact.value);
    if (value === null) return [];

    const confidence = Number.isFinite(Number(fact.confidence)) ? Number(fact.confidence) : 1;
    if (confidence < 0 || confidence > 1) throw new Error(`confidence out of range for ${factKey}`);

    return [{
      user_id: userId,
      fact_key: factKey,
      fact_value: value,
      source: fact.source || 'USER_REPORTED',
      source_category: fact.sourceCategory || 'SELF_REPORTED',
      confidence,
      user_confirmed: fact.userConfirmed ?? true,
      scope: fact.scope || 'global',
      stale_after_days: fact.staleAfterDays ?? null,
      observed_at: observedAt,
      source_reference: fact.sourceReference ?? null,
    }];
  });
}

export function classifyStrike({ xPct, yPct }) {
  const x = Number(xPct);
  const y = Number(yPct);
  if (!Number.isFinite(x) || !Number.isFinite(y)) return null;
  const horizontal = x < 38 ? 'Heel' : x > 62 ? 'Toe' : 'Center';
  const vertical = y < 38 ? 'High' : y > 62 ? 'Low' : 'Center';
  if (vertical === 'Center') return horizontal;
  return horizontal === 'Center' ? vertical : `${vertical} / ${horizontal}`;
}

function rowStartsArea(row, area) {
  const key = String(row?.fact_key || '');
  if (area.prefixes.some(prefix => key.startsWith(prefix))) return true;
  if (area.id === 'connected') {
    return row?.source === 'FILE_IMPORT' || row?.source === 'PROVIDER_SYNC';
  }
  return false;
}

export function summarizeProfile(rows = []) {
  const startedAreaIds = PROFILE_AREAS
    .filter(area => rows.some(row => normalizeFactInput(row?.fact_value) !== null && rowStartsArea(row, area)))
    .map(area => area.id);
  const totalAreas = PROFILE_AREAS.length;
  const startedCount = startedAreaIds.length;
  return {
    startedAreaIds,
    startedCount,
    totalAreas,
    coveragePct: Math.round((startedCount / totalAreas) * 100),
  };
}
