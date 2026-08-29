import test from 'node:test';
import assert from 'node:assert/strict';

import { rebuildIntelligenceState } from './state-rebuild.mjs';

const USER_ID = '20510000-0000-0000-0000-000000000001';
const GENERATION_A = '20530000-0000-4000-8000-000000000001';
const GENERATION_B = '20530000-0000-4000-8000-000000000002';
const GENERATION_C = '20530000-0000-4000-8000-000000000003';
const GENERATION_D = '20530000-0000-4000-8000-000000000004';
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function baseSources() {
  return {
    profileFacts: [
      {
        fact_key: 'game.handicap_index',
        fact_value: 12.4,
        value_state: 'KNOWN',
        source_type: 'DECLARED',
        source: 'golfer_declared',
        source_detail: {},
        confidence: 0.85,
        user_confirmed: false,
        effective_at: '2026-02-01T12:00:00Z',
      },
      {
        fact_key: 'game.handicap_index',
        fact_value: 10.9,
        value_state: 'KNOWN',
        source_type: 'IMPORTED',
        source: 'verified_handicap_import',
        source_detail: { verified: true },
        confidence: 0.99,
        user_confirmed: false,
        effective_at: '2026-08-20T12:00:00Z',
      },
    ],
    inferences: [
      {
        inference_key: 'swing.driver.speed_mph',
        inferred_value: { min: 90, max: 96, unit: 'mph' },
        value_state: 'INFERRED_ONLY',
        confidence: 0.82,
        status: 'ACTIVE',
        model_key: 'driver_speed_proxy',
        model_version: 'MODEL-1.0',
        created_at: '2026-08-25T12:00:00Z',
      },
    ],
    activeBag: {
      bag_id: 'GAL-BAG-TEST-1',
      items: [
        { category: 'DRIVER', canonical_product_id: 'TEST-DRIVER-1' },
      ],
    },
    buyerEvents: [
      {
        event_id: 'EVT-205-1',
        event_type: 'product.viewed',
        event_version: 'EVENT-1.0',
        occurred_at: '2026-08-27T10:00:00Z',
        invalidated_at: null,
      },
      {
        event_id: 'EVT-205-2',
        event_type: 'recommendation.saved',
        event_version: 'EVENT-1.0',
        occurred_at: '2026-08-28T15:00:00Z',
        invalidated_at: null,
      },
      {
        event_id: 'EVT-205-INVALID',
        event_type: 'product.viewed',
        event_version: 'EVENT-1.0',
        occurred_at: '2026-08-29T20:00:00Z',
        invalidated_at: '2026-08-29T20:05:00Z',
      },
    ],
    recommendationSummary: {
      latest_run_id: 'GAL-RUN-TEST-1',
      completed_at: '2026-08-28T14:55:00Z',
    },
    connectionSummaries: [],
    factRules: {
      'game.handicap_index': { domain: 'game', conflictTolerance: 0.5 },
      'swing.driver.speed_mph': { domain: 'swing', conflictTolerance: 2 },
    },
    expectedFacts: ['game.handicap_index', 'swing.driver.speed_mph'],
  };
}

function makeRepositories(sources) {
  const persisted = [];
  return {
    sourceRepository: {
      async loadStateSources(userId) {
        assert.equal(userId, USER_ID);
        return structuredClone(sources);
      },
    },
    stateRepository: {
      async persistState(userId, payload) {
        assert.equal(userId, USER_ID);
        persisted.push(structuredClone(payload));
        return payload.stateGenerationId;
      },
    },
    persisted,
  };
}

test('GI-STATE-001 rebuild resolves durable sources and persists only derived cache state', async () => {
  const sources = baseSources();
  const before = structuredClone(sources);
  const { sourceRepository, stateRepository, persisted } = makeRepositories(sources);

  const result = await rebuildIntelligenceState({
    userId: USER_ID,
    sourceRepository,
    stateRepository,
    generationIdFactory: () => GENERATION_A,
  });

  assert.equal(result.stateGenerationId, GENERATION_A);
  assert.equal(result.state.stateSchemaVersion, 'GI-STATE-1.1');
  assert.equal(result.state.status, 'HEALTHY');
  assert.equal(result.state.domains.game.facts['game.handicap_index'].value, 10.9);
  assert.equal(result.state.domains.game.facts['game.handicap_index'].provenance.sourceType, 'IMPORTED');
  assert.equal(result.state.domains.game.facts['game.handicap_index'].provenance.sourceLabel, 'verified_handicap_import');
  assert.deepEqual(
    result.state.domains.swing.facts['swing.driver.speed_mph'].value,
    { min: 90, max: 96, unit: 'mph' },
  );
  assert.equal(result.eventCount, 2);
  assert.equal(result.latestSourceEventAt, '2026-08-28T15:00:00.000Z');
  assert.equal(persisted.length, 1);
  assert.equal(persisted[0].status, 'HEALTHY');
  assert.equal(persisted[0].eventCount, 2);
  assert.deepEqual(sources, before, 'rebuild must not mutate durable source objects');
});

test('GI-STATE-002 missing active bag yields PARTIAL while resolved profile intelligence stays usable', async () => {
  const sources = baseSources();
  sources.activeBag = null;
  const { sourceRepository, stateRepository } = makeRepositories(sources);

  const result = await rebuildIntelligenceState({
    userId: USER_ID,
    sourceRepository,
    stateRepository,
    generationIdFactory: () => GENERATION_B,
  });

  assert.equal(result.state.status, 'PARTIAL');
  assert.equal(result.state.dependencyStatus.bag.status, 'MISSING');
  assert.equal(result.state.domains.game.facts['game.handicap_index'].value, 10.9);
  assert.equal(result.state.domainStatus.game.status, 'HEALTHY');
});

test('GI-STATE-003 each rebuild advances the generation id without changing source evidence', async () => {
  const sources = baseSources();
  const before = structuredClone(sources);
  const { sourceRepository, stateRepository, persisted } = makeRepositories(sources);
  const generationIds = [GENERATION_A, GENERATION_B];
  let sequence = 0;

  const generationIdFactory = () => generationIds[sequence++];

  const first = await rebuildIntelligenceState({ userId: USER_ID, sourceRepository, stateRepository, generationIdFactory });
  const second = await rebuildIntelligenceState({ userId: USER_ID, sourceRepository, stateRepository, generationIdFactory });

  assert.notEqual(first.stateGenerationId, second.stateGenerationId);
  assert.deepEqual(persisted.map((row) => row.stateGenerationId), generationIds);
  assert.deepEqual(sources, before);
});

test('GI-STATE-004 invalidated behavior is excluded from cache event count and latest-event watermark', async () => {
  const sources = baseSources();
  sources.buyerEvents.push({
    event_id: 'EVT-205-INVALID-LATEST',
    event_type: 'purchase.reported',
    event_version: 'EVENT-1.0',
    occurred_at: '2026-08-30T12:00:00Z',
    invalidated_at: '2026-08-30T12:01:00Z',
  });
  const { sourceRepository, stateRepository } = makeRepositories(sources);

  const result = await rebuildIntelligenceState({
    userId: USER_ID,
    sourceRepository,
    stateRepository,
    generationIdFactory: () => GENERATION_D,
  });

  assert.equal(result.eventCount, 2);
  assert.equal(result.latestSourceEventAt, '2026-08-28T15:00:00.000Z');
});

test('GI-STATE-005 default generation id is a database-compatible UUID', async () => {
  const sources = baseSources();
  const { sourceRepository, stateRepository } = makeRepositories(sources);

  const result = await rebuildIntelligenceState({
    userId: USER_ID,
    sourceRepository,
    stateRepository,
  });

  assert.match(result.stateGenerationId, UUID_RE);
  assert.notEqual(result.stateGenerationId, GENERATION_C);
});
