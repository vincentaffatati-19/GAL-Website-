import { fetchAiFitEquipment } from '../../equipment/client';
import { escapeHtml } from '../../render/escape';
import { buildDriverFitViewModel } from './model';
import { buildDriverTargetProfile, type DriverEvidenceInput } from './targets';

export async function renderDriverFit(evidence: DriverEvidenceInput[] = []): Promise<string> {
  try {
    const equipment = await fetchAiFitEquipment();
    const model = buildDriverFitViewModel(buildDriverTargetProfile(evidence), equipment);
    const targetSection = model.missingEvidence
      ? '<section><h2>What GAL is fitting for</h2><p>GAL needs compatible golfer evidence before setting target characteristics. Missing evidence will not be replaced with assumptions.</p></section>'
      : `<section><h2>What GAL is fitting for</h2>${model.targetProfile.characteristics.map((target) => `<article><h3>${escapeHtml(target.key)}</h3><p>${escapeHtml(target.direction)} — ${escapeHtml(target.rationale)}</p><small>Evidence: ${escapeHtml(target.evidenceState)}</small></article>`).join('')}</section>`;
    const candidateSection = model.missingEvidence
      ? '<section><h2>Candidate configurations</h2><p>Complete the missing evidence before GAL ranks configurations.</p></section>'
      : `<section><h2>Candidate configurations</h2>${model.candidates.length ? model.candidates.map((candidate) => `<article><h3>${escapeHtml(candidate.item.familyName)}</h3><p>${escapeHtml(candidate.configuration.name)}</p><p>${candidate.configuration.readiness === 'AI_FIT_LIMITED' ? `Limited evidence — ${candidate.configuration.blockingGapCount} blocking gap(s)` : 'AI Fit ready'}</p></article>`).join('') : '<p>No governed Driver configurations currently qualify.</p>'}</section>`;
    return `<div class="driver-fit"><p class="eyebrow">GAL AI Fitting</p><h1>Driver Fit</h1>${targetSection}${candidateSection}<section><h2>Why this fit</h2><p>GAL shows target characteristics before brands and only includes governed, eligible configurations. Commerce appears only after the analytical decision.</p></section></div>`;
  } catch (error) {
    const code = error instanceof Error ? (error as Error & { code?: string }).code ?? error.message : '';
    if (code === 'AUTH_REQUIRED') return '<section class="my-gal-state"><h2>Sign in to use GAL AI Fitting.</h2></section>';
    return '<section class="my-gal-state"><h2>Driver Fit is temporarily unavailable.</h2><p>Try again without changing the analytical path.</p></section>';
  }
}
