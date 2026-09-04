export interface DriverTargetCharacteristic {
  key: string;
  direction: 'LOWER' | 'NEUTRAL' | 'HIGHER' | 'MATCH';
  rationale: string;
  evidenceState: 'KNOWN' | 'LIMITED' | 'MISSING';
}

export interface DriverTargetProfile {
  characteristics: DriverTargetCharacteristic[];
}

export interface DriverEvidenceInput {
  key: string;
  desiredDirection: DriverTargetCharacteristic['direction'];
  rationale: string;
  evidenceState: DriverTargetCharacteristic['evidenceState'];
}

export function buildDriverTargetProfile(evidence: DriverEvidenceInput[]): DriverTargetProfile {
  return {
    characteristics: evidence
      .filter((item) => item.key.trim() && item.rationale.trim())
      .map((item) => ({
        key: item.key,
        direction: item.desiredDirection,
        rationale: item.rationale,
        evidenceState: item.evidenceState,
      })),
  };
}
