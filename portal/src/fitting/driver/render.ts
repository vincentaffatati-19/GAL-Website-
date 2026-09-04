import { fetchAiFitEquipment } from '../../equipment/client';
import { escapeHtml } from '../../render/escape';
import { buildDriverFitViewModel } from './model';
import { buildDriverTargetProfile, type DriverEvidenceInput } from './targets';

function readinessCopy(readiness: string, gaps: number): string {
  return readiness === 'AI_FIT_LIMITED'
    ? `Limited evidence — ${gaps} blocking gap(s). GAL narrows the fit rather than filling gaps with assumptions.`
    : 'AI Fit ready under the current governed readiness policy.';
}

export async function renderDriverFit(evidence: DriverEvidenceInput[] = []): Promise<string> {
  try {
    const equipment = await fetchAiFitEquipment();
    const model = buildDriverFitViewModel(buildDriverTargetProfile(evidence), equipment);

    const targets = model.missingEvidence
      ? '<p>GAL needs compatible golfer evidence before setting target characteristics. Missing evidence will not be replaced with assumptions.</p>'
      : `<div class="driver-target-grid">${model.targetProfile.characteristics.map((target) => `<article><strong>${escapeHtml(target.key)}</strong><span>${escapeHtml(target.direction)}</span><p>${escapeHtml(target.rationale)}</p><small>Evidence: ${escapeHtml(target.evidenceState)}</small></article>`).join('')}</div>`;

    const candidates = model.missingEvidence
      ? '<p>Complete the missing evidence before GAL ranks configurations.</p>'
      : model.candidates.length
        ? `<div class="driver-candidate-grid">${model.candidates.map((candidate) => `<article class="driver-candidate"><p class="eyebrow">Governed configuration</p><h3>${escapeHtml(candidate.item.familyName)}</h3><p>${escapeHtml(candidate.configuration.name)}</p><small>${escapeHtml(readinessCopy(candidate.configuration.readiness, candidate.configuration.blockingGapCount))}</small></article>`).join('')}</div>`
        : '<p>No governed Driver configurations currently qualify. GAL will not fill the list with unverified alternatives.</p>';

    return `<div class="driver-fit driver-fit-workspace">
      <header class="driver-fit-hero"><div><p class="eyebrow">GAL AI Fitting · Driver</p><h1>Personalized equipment fitting powered by your game.</h1><p><strong>Characteristics Before Brands.</strong> GAL determines the equipment characteristics your evidence supports before showing product configurations, brands, models, or commerce.</p></div><a class="button" href="/portal/profile">Review Golfer Profile</a></header>

      <section class="driver-fit-step" data-step="1"><span class="step-number">01</span><div><p class="eyebrow">Quick View</p><h2>What GAL knows right now</h2><p>${model.missingEvidence ? 'Your Driver fit needs more compatible evidence before GAL can define a target profile.' : 'GAL has enough compatible evidence to define target characteristics. Review the evidence context before acting.'}</p></div></section>

      <section class="driver-fit-step" data-step="2"><span class="step-number">02</span><div><p class="eyebrow">Fit Setup</p><h2>Use known data first</h2><p>Tell GAL Once applies here: valid profile, bag, measured and connected evidence should be reused. GAL asks only for missing, stale, or Driver-specific inputs.</p><a href="/portal/profile">Review profile inputs</a></div></section>

      <section class="driver-fit-step driver-fit-targets" data-step="3"><span class="step-number">03</span><div><p class="eyebrow">Target Characteristics</p><h2>What GAL is fitting for</h2>${targets}</div></section>

      <section class="driver-fit-step" data-step="4"><span class="step-number">04</span><div><p class="eyebrow">Recommendations</p><h2>Compatible configurations that follow the target</h2>${candidates}<div class="driver-action-peers" aria-label="Possible recommendation actions"><span>Keep</span><span>Adjust</span><span>Reconfigure</span><span>Replace</span></div><p class="fit-firewall">The current club is a valid peer option. Commerce appears only after the analytical decision and cannot change candidate rank.</p></div></section>

      <section class="driver-fit-step" data-step="5"><span class="step-number">05</span><div><p class="eyebrow">Why This Fit</p><h2>Evidence before explanation</h2><p>GAL explains how the target characteristics relate to your evidence, why a configuration qualifies, what is uncertain, and which evidence would strengthen or change the recommendation.</p></div></section>

      <section class="driver-fit-step" data-step="6"><span class="step-number">06</span><div><p class="eyebrow">Compare</p><h2>Compare the configuration—not just the logo</h2><p>Head, loft or effective loft, settings, shaft profile, weight, length and other supported configuration details belong together when evidence supports them.</p></div></section>

      <section class="driver-fit-step" data-step="7"><span class="step-number">07</span><div><p class="eyebrow">Next Action</p><h2>Choose the smallest defensible next step</h2><p>Keep, adjust, reconfigure, compare/test, or replace can all be correct outcomes. GAL does not assume a purchase is required.</p></div></section>

      <section class="driver-fit-step" data-step="8"><span class="step-number">08</span><div><p class="eyebrow">Outcome Tracking</p><h2>Record what changed</h2><p>After a fitting action, GAL can connect the action to attributable outcome evidence rather than assuming the recommendation worked.</p></div></section>

      <section class="driver-fit-step" data-step="9"><span class="step-number">09</span><div><p class="eyebrow">Progress Over Time</p><h2>Did the equipment opportunity resolve?</h2><p>Progress reflects evidence-backed equipment outcomes, resolutions and regressions—not a generic engagement score.</p><a href="/portal/progress">View Progress</a></div></section>
    </div>`;
  } catch (error) {
    const code = error instanceof Error ? (error as Error & { code?: string }).code ?? error.message : '';
    if (code === 'AUTH_REQUIRED') return '<section class="my-gal-state"><h2>Sign in to use GAL AI Fitting.</h2></section>';
    return '<section class="my-gal-state"><h2>Driver Fit is temporarily unavailable.</h2><p>GAL will not substitute an ungoverned ranking while the fitting contract is unavailable.</p></section>';
  }
}
