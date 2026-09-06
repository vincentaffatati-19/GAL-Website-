import test from 'node:test';
import assert from 'node:assert/strict';
import {
  PROFILE_AREAS,
  MISS_FINISH_VALUES,
  MISS_SHAPE_VALUES,
  PROVIDER_CAPABILITIES,
  normalizeFactInput,
  buildProfileFactRows,
  summarizeProfile,
  classifyStrike,
} from '../portal/profile-model.mjs';

test('defines the six approved UX10.02 profile areas in order', () => {
  assert.deepEqual(PROFILE_AREAS.map(a => a.id), [
    'you', 'game', 'swing', 'miss', 'play', 'connected'
  ]);
  assert.deepEqual(PROFILE_AREAS.map(a => a.label), [
    'You', 'Your Game', 'Your Swing', 'Your Miss', 'Where You Play', 'Connected Golf'
  ]);
});

test('preserves locked miss vocabulary exactly', () => {
  assert.deepEqual(MISS_FINISH_VALUES, ['Left', 'Straight', 'Right', 'Short', 'Long']);
  assert.deepEqual(MISS_SHAPE_VALUES, ['Hook', 'Pull', 'Straight', 'Push', 'Slice']);
});

test('normalizes meaningful values and omits unknown or blank values', () => {
  assert.equal(normalizeFactInput('  Right  '), 'Right');
  assert.equal(normalizeFactInput(92.4), 92.4);
  assert.equal(normalizeFactInput(false), false);
  assert.equal(normalizeFactInput('   '), null);
  assert.equal(normalizeFactInput(null), null);
  assert.equal(normalizeFactInput(undefined), null);
  assert.equal(normalizeFactInput(Number.NaN), null);
  assert.deepEqual(normalizeFactInput({ x: 1 }), { x: 1 });
});

test('builds atomic governed rows while preserving source quality and scope', () => {
  const rows = buildProfileFactRows({
    userId: 'user-a',
    observedAt: '2026-09-06T15:00:00.000Z',
    facts: [
      { factKey: 'profile.handedness', value: 'Right' },
      {
        factKey: 'swing.club_speed_mph', value: 97.2, scope: 'driver',
        source: 'FILE_IMPORT', sourceCategory: 'MEASURED',
        sourceReference: 'trackman-session.csv', userConfirmed: false,
      },
      {
        factKey: 'swing.club_speed_mph', value: ' ', scope: '7-iron',
        source: 'USER_REPORTED', sourceCategory: 'INFERRED_ESTIMATED'
      }
    ]
  });

  assert.equal(rows.length, 2, 'blank unknown fact must not be written');
  assert.deepEqual(rows[0], {
    user_id: 'user-a', fact_key: 'profile.handedness', fact_value: 'Right',
    source: 'USER_REPORTED', source_category: 'SELF_REPORTED', confidence: 1,
    user_confirmed: true, scope: 'global', stale_after_days: null,
    observed_at: '2026-09-06T15:00:00.000Z', source_reference: null,
  });
  assert.equal(rows[1].source, 'FILE_IMPORT');
  assert.equal(rows[1].source_category, 'MEASURED');
  assert.equal(rows[1].scope, 'driver');
  assert.equal(rows[1].source_reference, 'trackman-session.csv');
  assert.equal(rows[1].user_confirmed, false);
});

test('does not silently upgrade estimated user data to measured', () => {
  const [row] = buildProfileFactRows({
    userId: 'user-a',
    observedAt: '2026-09-06T15:00:00.000Z',
    facts: [{
      factKey: 'swing.club_speed_mph', value: 90, scope: 'driver',
      source: 'USER_REPORTED', sourceCategory: 'INFERRED_ESTIMATED', userConfirmed: true,
    }]
  });
  assert.equal(row.source_category, 'INFERRED_ESTIMATED');
  assert.notEqual(row.source_category, 'MEASURED');
});

test('classifies strike location using approved Step 6 thresholds', () => {
  assert.equal(classifyStrike({ xPct: 50, yPct: 50 }), 'Center');
  assert.equal(classifyStrike({ xPct: 20, yPct: 50 }), 'Heel');
  assert.equal(classifyStrike({ xPct: 80, yPct: 50 }), 'Toe');
  assert.equal(classifyStrike({ xPct: 50, yPct: 20 }), 'High');
  assert.equal(classifyStrike({ xPct: 80, yPct: 20 }), 'High / Toe');
  assert.equal(classifyStrike({ xPct: 20, yPct: 80 }), 'Low / Heel');
});

test('provider catalog never claims a live connection that has not been established', () => {
  const byId = Object.fromEntries(PROVIDER_CAPABILITIES.map(p => [p.id, p]));
  assert.equal(byId.toptracer.status, 'PARTNERSHIP_REQUIRED');
  assert.equal(byId.trackman.status, 'NOT_CONNECTED');
  assert.equal(byId.trackman.importAvailable, true);
  assert.equal(byId.ghin.status, 'NOT_CONNECTED');
  assert.equal(byId.arccos.status, 'UNAVAILABLE');
  assert.equal(byId.garmin.status, 'UNAVAILABLE');
  assert.equal(byId.other_launch_monitor.status, 'IMPORT_AVAILABLE');
  assert.equal(PROVIDER_CAPABILITIES.some(p => p.status === 'CONNECTED'), false);
});

test('coverage counts areas started, not confidence, and connected starts from a governed import', () => {
  const rows = [
    { fact_key: 'profile.handedness', fact_value: 'Right', scope: 'global', source: 'USER_REPORTED' },
    { fact_key: 'game.primary_goal', fact_value: 'Consistency', scope: 'global', source: 'USER_REPORTED' },
    { fact_key: 'swing.club_speed_mph', fact_value: 94, scope: 'driver', source: 'FILE_IMPORT' },
    { fact_key: 'miss.shape', fact_value: 'Slice', scope: 'driver', source: 'USER_REPORTED' },
    { fact_key: 'play.typical_conditions', fact_value: 'Windy', scope: 'global', source: 'USER_REPORTED' },
  ];
  const summary = summarizeProfile(rows);
  assert.deepEqual(summary.startedAreaIds, ['you', 'game', 'swing', 'miss', 'play', 'connected']);
  assert.equal(summary.startedCount, 6);
  assert.equal(summary.totalAreas, 6);
  assert.equal(summary.coveragePct, 100);
});
