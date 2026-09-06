const HEADER_TO_FACT = new Map([
  ['clubspeed', 'swing.club_speed_mph'],
  ['clubspeedmph', 'swing.club_speed_mph'],
  ['clubheadspeed', 'swing.club_speed_mph'],
  ['clubheadspeedmph', 'swing.club_speed_mph'],
  ['ballspeed', 'swing.ball_speed_mph'],
  ['ballspeedmph', 'swing.ball_speed_mph'],
  ['launchangle', 'swing.launch_deg'],
  ['launchdeg', 'swing.launch_deg'],
  ['verticallaunch', 'swing.launch_deg'],
  ['spinrate', 'swing.spin_rpm'],
  ['spinrpm', 'swing.spin_rpm'],
  ['totalspin', 'swing.spin_rpm'],
  ['carry', 'swing.carry_yards'],
  ['carrydistance', 'swing.carry_yards'],
  ['carryyds', 'swing.carry_yards'],
  ['carryyards', 'swing.carry_yards'],
]);

const CLUB_HEADERS = new Set(['club', 'clubtype', 'equipment', 'clubname']);

function normalizeHeader(value) {
  return String(value || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

function parseCsv(text) {
  const input = String(text || '').replace(/^\uFEFF/, '');
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let i = 0; i < input.length; i += 1) {
    const char = input[i];
    if (quoted) {
      if (char === '"' && input[i + 1] === '"') {
        field += '"';
        i += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
      continue;
    }
    if (char === '"') quoted = true;
    else if (char === ',') { row.push(field); field = ''; }
    else if (char === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (char !== '\r') field += char;
  }
  if (quoted) throw new Error('CSV_UNTERMINATED_QUOTE');
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows.filter(r => r.some(cell => String(cell).trim().length));
}

function normalizeScope(value) {
  const normalized = String(value || '').trim().toLowerCase().replace(/[\s_]+/g, '-');
  if (['driver', '1w', '1-wood'].includes(normalized)) return 'driver';
  if (['7-iron', '7iron', '7-i', '7i'].includes(normalized)) return '7-iron';
  return null;
}

export function parseLaunchMonitorCsv(text, metadata = {}) {
  const rows = parseCsv(text);
  if (rows.length < 2) throw new Error('CSV_DATA_REQUIRED');
  const headers = rows[0].map(h => String(h).trim());
  const dataRows = rows.slice(1).filter(r => r.some(cell => String(cell ?? '').trim().length));
  if (!dataRows.length) throw new Error('CSV_DATA_REQUIRED');
  const selected = dataRows[0];
  const warnings = [];
  if (dataRows.length > 1) {
    warnings.push({ code: 'MULTIPLE_ROWS_FIRST_VALID_ONLY', rowCount: dataRows.length });
  }

  const clubColumnIndex = headers.findIndex(h => CLUB_HEADERS.has(normalizeHeader(h)));
  const scope = normalizeScope(metadata.scope) || normalizeScope(clubColumnIndex >= 0 ? selected[clubColumnIndex] : null);
  if (!scope) throw new Error('CLUB_SCOPE_REQUIRED');

  const provider = String(metadata.provider || 'Other Launch Monitor').trim() || 'Other Launch Monitor';
  const sourceReference = String(metadata.filename || metadata.sourceReference || 'launch-monitor-import.csv').trim();
  const observedAt = metadata.observedAt || new Date().toISOString();
  const facts = [];

  headers.forEach((header, index) => {
    const normalized = normalizeHeader(header);
    if (!normalized || CLUB_HEADERS.has(normalized)) return;
    const factKey = HEADER_TO_FACT.get(normalized);
    if (!factKey) {
      warnings.push({ code: 'UNSUPPORTED_COLUMN', header });
      return;
    }
    const raw = String(selected[index] ?? '').trim();
    if (!raw) return;
    const value = Number(raw.replace(/,/g, ''));
    if (!Number.isFinite(value)) {
      warnings.push({ code: 'INVALID_NUMERIC_VALUE', header, value: raw });
      return;
    }
    facts.push({
      factKey,
      value,
      scope,
      source: 'FILE_IMPORT',
      sourceCategory: 'MEASURED',
      sourceReference,
      userConfirmed: false,
    });
  });

  if (!facts.length) throw new Error('NO_SUPPORTED_MEASURED_FACTS');
  return { provider, sourceReference, observedAt, facts, warnings };
}
