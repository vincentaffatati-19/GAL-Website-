import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  buildIntelligenceState,
  resolveCurrentFact,
} from './intelligence-state-builder.mjs';

const fixtures = JSON.parse(
  await readFile(new URL('./state-fixtures.json', import.meta.url), 'utf8'),
);

function getResolvedFact(state, domain, factKey) {
  return state.domains?.[domain]?.facts?.[factKey];
}

test('GI-STATE-BUILDER-001 verified imported handicap outranks older declaration', () => {
  const scenario = fixtures.scenarios.find((item) => item.id === 'verified-import-over-older-declaration');
  const state = buildIntelligenceState(scenario.input);
  const fact = getResolvedFact(state, scenario.expected.domain, scenario.expected.factKey);

  assert.equal(state.stateSchemaVersion, fixtures.schemaVersion);
  assert.equal(state.status, scenario.expected.status);
  assert.equal(fact.resolution, scenario.expected.resolution);
  assert.equal(fact.value, scenario.expected.value);
  assert.equal(fact.valueState, scenario.expected.valueState);
  assert.equal(fact.provenance.sourceType, scenario.expected.sourceType);
  assert.equal(fact.provenance.sourceLabel, scenario.expected.sourceLabel);
  assert.equal(fact.provenance.confidence, scenario.expected.confidence);
});

test('GI-STATE-BUILDER-002 material conflict is explicit instead of fabricating certainty', () => {
  const scenario = fixtures.scenarios.find((item) => item.id === 'material-conflict-no-clear-authority');
  const state = buildIntelligenceState(scenario.input);
  const fact = getResolvedFact(state, scenario.expected.domain, scenario.expected.factKey);

  assert.equal(state.status, scenario.expected.status);
  assert.equal(state.domainStatus[scenario.expected.domain].status, 'PARTIAL');
  assert.equal(fact.resolution, scenario.expected.resolution);
  assert.equal(fact.value, null);
  assert.equal(fact.valueState, 'UNKNOWN');
  assert.equal(fact.conflict.candidates.length, scenario.expected.conflictCount);
  assert.deepEqual(
    fact.conflict.candidates.map((candidate) => candidate.value).sort((a, b) => a - b),
    [10.2, 14.8],
  );
});

test('GI-STATE-BUILDER-003 inferred driver-speed range keeps range, provenance, and confidence', () => {
  const scenario = fixtures.scenarios.find((item) => item.id === 'inferred-driver-speed-range');
  const state = buildIntelligenceState(scenario.input);
  const fact = getResolvedFact(state, scenario.expected.domain, scenario.expected.factKey);

  assert.equal(state.status, scenario.expected.status);
  assert.equal(fact.resolution, scenario.expected.resolution);
  assert.deepEqual(fact.value, scenario.expected.value);
  assert.equal(fact.valueState, scenario.expected.valueState);
  assert.equal(fact.provenance.sourceType, scenario.expected.sourceType);
  assert.equal(fact.provenance.sourceLabel, scenario.expected.sourceLabel);
  assert.equal(fact.provenance.confidence, scenario.expected.confidence);
  assert.equal(fact.provenance.modelVersion, scenario.expected.modelVersion);
});

test('GI-STATE-BUILDER-004 missing wedge carry remains a first-class unknown', () => {
  const scenario = fixtures.scenarios.find((item) => item.id === 'missing-wedge-carry-remains-unknown');
  const state = buildIntelligenceState(scenario.input);
  const fact = getResolvedFact(state, scenario.expected.domain, scenario.expected.factKey);

  assert.equal(state.status, scenario.expected.status);
  assert.equal(fact.resolution, scenario.expected.resolution);
  assert.equal(fact.value, null);
  assert.equal(fact.valueState, scenario.expected.valueState);
  assert.equal(fact.provenance.sourceType, null);
  assert.equal(fact.provenance.sourceLabel, null);
  assert.equal(fact.provenance.confidence, null);
});

test('GI-STATE-BUILDER-005 resolver output is deterministic for identical input', () => {
  const scenario = fixtures.scenarios.find((item) => item.id === 'verified-import-over-older-declaration');
  const first = buildIntelligenceState(scenario.input);
  const second = buildIntelligenceState(scenario.input);

  assert.deepEqual(second, first);
});

test('GI-STATE-BUILDER-006 direct resolver does not use recency to break a material same-authority conflict', () => {
  const candidates = [
    {
      factKey: 'game.handicap_index',
      value: 9.1,
      valueState: 'KNOWN',
      sourceType: 'DECLARED',
      sourceLabel: 'older',
      confidence: 0.9,
      effectiveAt: '2026-01-01T00:00:00Z',
    },
    {
      factKey: 'game.handicap_index',
      value: 13.7,
      valueState: 'KNOWN',
      sourceType: 'DECLARED',
      sourceLabel: 'newer',
      confidence: 0.9,
      effectiveAt: '2026-08-01T00:00:00Z',
    },
  ];

  const resolved = resolveCurrentFact(candidates, {
    domain: 'game',
    conflictTolerance: 0.5,
  });

  assert.equal(resolved.resolution, 'CONFLICT');
  assert.equal(resolved.value, null);
});
