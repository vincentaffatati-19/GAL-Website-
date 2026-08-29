const STATE_SCHEMA_VERSION = 'GI-STATE-1.1';
const DEFAULT_CONFLICT_TOLERANCE = 0;
const DEFAULT_CONFIDENCE_DOMINANCE = 0.15;

function stableStringify(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;

  const entries = Object.keys(value)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`);
  return `{${entries.join(',')}}`;
}

function normalizeSourceType(value) {
  return typeof value === 'string' ? value.trim().toUpperCase() : 'SYSTEM';
}

function authorityRank(candidate) {
  const sourceType = normalizeSourceType(candidate.sourceType);

  if (candidate.golferCorrection === true) return 600;
  if (candidate.verified === true && (sourceType === 'MEASURED' || sourceType === 'IMPORTED')) return 500;
  if (candidate.userConfirmed === true) return 450;

  switch (sourceType) {
    case 'MEASURED':
      return 425;
    case 'IMPORTED':
      return 400;
    case 'DECLARED':
      return 350;
    case 'INFERRED':
      return 200;
    case 'OBSERVED':
      return 150;
    case 'SYSTEM':
    default:
      return 100;
  }
}

function confidenceValue(candidate) {
  return Number.isFinite(candidate.confidence) ? Number(candidate.confidence) : 0;
}

function timestampValue(candidate) {
  const parsed = Date.parse(candidate.effectiveAt ?? '');
  return Number.isFinite(parsed) ? parsed : 0;
}

function compareCandidates(left, right) {
  const authorityDifference = authorityRank(right) - authorityRank(left);
  if (authorityDifference !== 0) return authorityDifference;

  const confidenceDifference = confidenceValue(right) - confidenceValue(left);
  if (confidenceDifference !== 0) return confidenceDifference;

  const recencyDifference = timestampValue(right) - timestampValue(left);
  if (recencyDifference !== 0) return recencyDifference;

  const sourceDifference = String(left.sourceLabel ?? '').localeCompare(String(right.sourceLabel ?? ''));
  if (sourceDifference !== 0) return sourceDifference;

  return stableStringify(left.value).localeCompare(stableStringify(right.value));
}

function valuesMateriallyConflict(leftValue, rightValue, tolerance) {
  if (typeof leftValue === 'number' && typeof rightValue === 'number') {
    return Math.abs(leftValue - rightValue) > tolerance;
  }

  return stableStringify(leftValue) !== stableStringify(rightValue);
}

function provenanceFor(candidate, candidateCount) {
  if (!candidate) {
    return {
      sourceType: null,
      sourceLabel: null,
      confidence: null,
      userConfirmed: null,
      verified: null,
      effectiveAt: null,
      modelVersion: null,
      candidateCount,
    };
  }

  return {
    sourceType: normalizeSourceType(candidate.sourceType),
    sourceLabel: candidate.sourceLabel ?? null,
    confidence: Number.isFinite(candidate.confidence) ? Number(candidate.confidence) : null,
    userConfirmed: candidate.userConfirmed === true,
    verified: candidate.verified === true,
    effectiveAt: candidate.effectiveAt ?? null,
    modelVersion: candidate.modelVersion ?? null,
    candidateCount,
  };
}

function conflictCandidateSummary(candidate) {
  return {
    value: candidate.value ?? null,
    valueState: candidate.valueState ?? 'KNOWN',
    sourceType: normalizeSourceType(candidate.sourceType),
    sourceLabel: candidate.sourceLabel ?? null,
    confidence: Number.isFinite(candidate.confidence) ? Number(candidate.confidence) : null,
    userConfirmed: candidate.userConfirmed === true,
    verified: candidate.verified === true,
    effectiveAt: candidate.effectiveAt ?? null,
    modelVersion: candidate.modelVersion ?? null,
  };
}

export function resolveCurrentFact(candidates = [], catalogRule = {}) {
  const eligible = candidates
    .filter((candidate) => candidate && candidate.invalidated !== true)
    .slice()
    .sort(compareCandidates);

  if (eligible.length === 0) {
    return {
      resolution: 'MISSING',
      value: null,
      valueState: 'UNKNOWN',
      provenance: provenanceFor(null, 0),
    };
  }

  const top = eligible[0];
  const runnerUp = eligible[1];
  const tolerance = Number.isFinite(catalogRule.conflictTolerance)
    ? Number(catalogRule.conflictTolerance)
    : DEFAULT_CONFLICT_TOLERANCE;
  const confidenceDominance = Number.isFinite(catalogRule.confidenceDominance)
    ? Number(catalogRule.confidenceDominance)
    : DEFAULT_CONFIDENCE_DOMINANCE;

  if (runnerUp && authorityRank(top) === authorityRank(runnerUp)) {
    const materialConflict = valuesMateriallyConflict(top.value, runnerUp.value, tolerance);
    const confidenceGap = Math.abs(confidenceValue(top) - confidenceValue(runnerUp));

    if (materialConflict && confidenceGap < confidenceDominance) {
      const conflictSet = eligible
        .filter((candidate) => authorityRank(candidate) === authorityRank(top))
        .filter((candidate) => valuesMateriallyConflict(top.value, candidate.value, tolerance) || candidate === top)
        .map(conflictCandidateSummary);

      return {
        resolution: 'CONFLICT',
        value: null,
        valueState: 'UNKNOWN',
        provenance: provenanceFor(null, eligible.length),
        conflict: {
          reason: 'MATERIAL_SAME_AUTHORITY_CONFLICT',
          candidates: conflictSet,
        },
      };
    }
  }

  const sourceType = normalizeSourceType(top.sourceType);
  const inferred = sourceType === 'INFERRED' || top.valueState === 'INFERRED_ONLY';

  return {
    resolution: inferred ? 'INFERRED' : 'RESOLVED',
    value: top.value ?? null,
    valueState: top.valueState ?? (inferred ? 'INFERRED_ONLY' : 'KNOWN'),
    provenance: provenanceFor(top, eligible.length),
  };
}

function domainForFact(factKey, factRules) {
  return factRules?.[factKey]?.domain ?? String(factKey).split('.')[0] ?? 'unknown';
}

function ensureDomain(domains, domain) {
  if (!domains[domain]) domains[domain] = { facts: {} };
  return domains[domain];
}

export function buildIntelligenceState(input = {}) {
  const facts = Array.isArray(input.facts) ? input.facts : [];
  const inferences = Array.isArray(input.inferences) ? input.inferences : [];
  const factRules = input.factRules && typeof input.factRules === 'object' ? input.factRules : {};
  const expectedFacts = Array.isArray(input.expectedFacts) ? input.expectedFacts : [];

  const candidatesByFact = new Map();
  for (const candidate of [...facts, ...inferences]) {
    if (!candidate?.factKey) continue;
    if (!candidatesByFact.has(candidate.factKey)) candidatesByFact.set(candidate.factKey, []);
    candidatesByFact.get(candidate.factKey).push(candidate);
  }

  const factKeys = [...new Set([
    ...Object.keys(factRules),
    ...expectedFacts,
    ...candidatesByFact.keys(),
  ])].sort();

  const domains = {};
  for (const factKey of factKeys) {
    const domain = domainForFact(factKey, factRules);
    const resolved = resolveCurrentFact(candidatesByFact.get(factKey) ?? [], factRules[factKey] ?? {});
    ensureDomain(domains, domain).facts[factKey] = resolved;
  }

  const domainStatus = {};
  for (const domain of Object.keys(domains).sort()) {
    const resolvedFacts = Object.values(domains[domain].facts);
    const counts = {
      resolved: resolvedFacts.filter((fact) => fact.resolution === 'RESOLVED').length,
      inferred: resolvedFacts.filter((fact) => fact.resolution === 'INFERRED').length,
      unknown: resolvedFacts.filter((fact) => fact.resolution === 'MISSING').length,
      conflicts: resolvedFacts.filter((fact) => fact.resolution === 'CONFLICT').length,
    };

    domainStatus[domain] = {
      status: counts.conflicts > 0 ? 'PARTIAL' : 'HEALTHY',
      ...counts,
    };
  }

  const status = Object.values(domainStatus).some((domain) => domain.status === 'PARTIAL')
    ? 'PARTIAL'
    : 'HEALTHY';

  return {
    stateSchemaVersion: STATE_SCHEMA_VERSION,
    status,
    domains,
    domainStatus,
  };
}
