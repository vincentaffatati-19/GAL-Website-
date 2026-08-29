import { randomUUID } from 'node:crypto';

import { buildIntelligenceState } from './intelligence-state-builder.mjs';

const ENGINE_VERSION = 'GI-STATE-BUILDER-1.0';
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function numberOrNull(value) {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function isoOrNull(value) {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function normalizeProfileFact(row) {
  const sourceDetail = row?.source_detail && typeof row.source_detail === 'object'
    ? row.source_detail
    : {};

  return {
    factKey: row.fact_key,
    value: row.fact_value ?? null,
    valueState: row.value_state ?? 'KNOWN',
    sourceType: row.source_type ?? 'SYSTEM',
    sourceLabel: row.source ?? sourceDetail.label ?? null,
    confidence: numberOrNull(row.confidence),
    userConfirmed: row.user_confirmed === true,
    verified: sourceDetail.verified === true,
    effectiveAt: isoOrNull(row.effective_at ?? row.observed_at ?? row.updated_at),
    modelVersion: row.model_version ?? null,
  };
}

function normalizeInference(row) {
  return {
    factKey: row.inference_key,
    value: row.inferred_value ?? null,
    valueState: row.value_state ?? 'INFERRED_ONLY',
    sourceType: 'INFERRED',
    sourceLabel: row.model_key ?? 'inference',
    confidence: numberOrNull(row.confidence),
    userConfirmed: row.status === 'CONFIRMED',
    verified: false,
    effectiveAt: isoOrNull(row.confirmed_at ?? row.activated_at ?? row.created_at),
    modelVersion: row.model_version ?? null,
  };
}

function activeInference(row) {
  return row?.status === 'ACTIVE' || row?.status === 'CONFIRMED';
}

function validBuyerEvents(events) {
  return (Array.isArray(events) ? events : [])
    .filter((event) => event && !event.invalidated_at)
    .slice()
    .sort((left, right) => {
      const leftTime = Date.parse(left.occurred_at ?? '') || 0;
      const rightTime = Date.parse(right.occurred_at ?? '') || 0;
      return leftTime - rightTime;
    });
}

function latestEventWatermark(events) {
  const latest = events.at(-1);
  return latest ? isoOrNull(latest.occurred_at) : null;
}

function defaultGenerationIdFactory() {
  return randomUUID();
}

function requireRepositoryMethod(repository, methodName) {
  if (!repository || typeof repository[methodName] !== 'function') {
    throw new TypeError(`${methodName} repository method is required`);
  }
}

export async function rebuildIntelligenceState({
  userId,
  sourceRepository,
  stateRepository,
  generationIdFactory = defaultGenerationIdFactory,
} = {}) {
  if (!userId) throw new TypeError('userId is required');
  requireRepositoryMethod(sourceRepository, 'loadStateSources');
  requireRepositoryMethod(stateRepository, 'persistState');
  if (typeof generationIdFactory !== 'function') throw new TypeError('generationIdFactory must be a function');

  const sources = await sourceRepository.loadStateSources(userId);
  if (!sources || typeof sources !== 'object') throw new TypeError('loadStateSources must return an object');

  const facts = (Array.isArray(sources.profileFacts) ? sources.profileFacts : [])
    .filter((row) => row?.fact_key)
    .map(normalizeProfileFact);

  const inferences = (Array.isArray(sources.inferences) ? sources.inferences : [])
    .filter((row) => row?.inference_key && activeInference(row))
    .map(normalizeInference);

  const state = buildIntelligenceState({
    facts,
    inferences,
    factRules: sources.factRules ?? {},
    expectedFacts: sources.expectedFacts ?? [],
    dependencies: {
      bag: sources.activeBag ?? null,
    },
    bag: sources.activeBag ?? null,
    events: Array.isArray(sources.buyerEvents) ? sources.buyerEvents : [],
    recommendations: sources.recommendationSummary ?? null,
    connectionSummaries: Array.isArray(sources.connectionSummaries) ? sources.connectionSummaries : [],
  });

  const events = validBuyerEvents(sources.buyerEvents);
  const stateGenerationId = generationIdFactory();
  if (typeof stateGenerationId !== 'string' || !UUID_RE.test(stateGenerationId)) {
    throw new TypeError('generationIdFactory must return a UUID string');
  }

  const latestSourceEventAt = latestEventWatermark(events);
  const payload = {
    stateGenerationId,
    stateSchemaVersion: state.stateSchemaVersion,
    engineVersion: ENGINE_VERSION,
    status: state.status,
    state,
    domainStatus: state.domainStatus,
    eventCount: events.length,
    latestEventAt: latestSourceEventAt,
    latestSourceEventAt,
  };

  await stateRepository.persistState(userId, payload);

  return payload;
}
