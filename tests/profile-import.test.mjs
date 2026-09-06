import test from 'node:test';
import assert from 'node:assert/strict';
import { parseLaunchMonitorCsv } from '../portal/profile-import.mjs';

test('parses approved launch-monitor aliases into measured driver facts with provenance', () => {
  const csv = 'Club Speed,Ball Speed,Launch Angle,Spin Rate,Carry\n96.4,142.8,13.2,2480,238\n';
  const out = parseLaunchMonitorCsv(csv, {
    provider: 'TrackMan', filename: 'tm-driver.csv', scope: 'driver',
    observedAt: '2026-09-01T18:00:00.000Z'
  });
  assert.equal(out.provider, 'TrackMan');
  assert.equal(out.sourceReference, 'tm-driver.csv');
  assert.equal(out.observedAt, '2026-09-01T18:00:00.000Z');
  assert.deepEqual(out.facts.map(f => [f.factKey, f.value, f.scope]), [
    ['swing.club_speed_mph', 96.4, 'driver'],
    ['swing.ball_speed_mph', 142.8, 'driver'],
    ['swing.launch_deg', 13.2, 'driver'],
    ['swing.spin_rpm', 2480, 'driver'],
    ['swing.carry_yards', 238, 'driver'],
  ]);
  assert.ok(out.facts.every(f => f.source === 'FILE_IMPORT'));
  assert.ok(out.facts.every(f => f.sourceCategory === 'MEASURED'));
  assert.ok(out.facts.every(f => f.userConfirmed === false));
  assert.ok(out.facts.every(f => f.sourceReference === 'tm-driver.csv'));
});

test('supports normalized aliases and 7-iron scope inferred from a club column', () => {
  const csv = 'Club,ClubHeadSpeed,ball_speed_mph,Vertical Launch,Total Spin,Carry Distance\n7 Iron,81.5,112.2,18.4,5800,164\n';
  const out = parseLaunchMonitorCsv(csv, { provider: 'Other Launch Monitor', filename: 'seven.csv' });
  assert.equal(out.facts[0].scope, '7-iron');
  assert.equal(out.facts.find(f => f.factKey === 'swing.spin_rpm').value, 5800);
});

test('omits blank values and rejects malformed numeric values rather than coercing them', () => {
  const csv = 'Club Speed,Ball Speed,Launch Angle,Spin Rate,Carry\n95.1,,banana,2450,231\n';
  const out = parseLaunchMonitorCsv(csv, { provider: 'TrackMan', filename: 'bad.csv', scope: 'driver' });
  assert.equal(out.facts.some(f => f.factKey === 'swing.ball_speed_mph'), false);
  assert.equal(out.facts.some(f => f.factKey === 'swing.launch_deg'), false);
  assert.ok(out.warnings.some(w => w.code === 'INVALID_NUMERIC_VALUE' && w.header === 'Launch Angle'));
});

test('reports unsupported columns without turning them into profile facts', () => {
  const csv = 'Club Speed,Smash Factor,Face Angle\n93.3,1.47,-1.2\n';
  const out = parseLaunchMonitorCsv(csv, { provider: 'TrackMan', filename: 'extra.csv', scope: 'driver' });
  assert.deepEqual(out.facts.map(f => f.factKey), ['swing.club_speed_mph']);
  assert.ok(out.warnings.some(w => w.code === 'UNSUPPORTED_COLUMN' && w.header === 'Smash Factor'));
  assert.ok(out.warnings.some(w => w.code === 'UNSUPPORTED_COLUMN' && w.header === 'Face Angle'));
});

test('requires a governed club scope instead of guessing from missing context', () => {
  const csv = 'Club Speed,Ball Speed\n94,140\n';
  assert.throws(
    () => parseLaunchMonitorCsv(csv, { provider: 'TrackMan', filename: 'unknown-club.csv' }),
    /CLUB_SCOPE_REQUIRED/
  );
});

test('is truthful about multi-row files by importing only the first valid row and warning', () => {
  const csv = 'Club Speed,Ball Speed\n94,140\n96,143\n';
  const out = parseLaunchMonitorCsv(csv, { provider: 'TrackMan', filename: 'multi.csv', scope: 'driver' });
  assert.equal(out.facts.find(f => f.factKey === 'swing.club_speed_mph').value, 94);
  assert.ok(out.warnings.some(w => w.code === 'MULTIPLE_ROWS_FIRST_VALID_ONLY'));
});
