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

    const snapshotCopy = model.missingEvidence
      ? 'Your Driver fit needs more compatible evidence before GAL can define a target profile.'
      : 'GAL has enough compatible evidence to define target characteristics. Review the evidence context before acting.';

    return `<div class="driver-fit ux5-driver-context">
      <section class="ux5-club-panel" aria-label="Driver equipment intelligence">
        <header class="ux5-club-panel-header">
          <div class="ux5-selected-club">
            <p class="eyebrow">Selected Club</p>
            <h1>Driver</h1>
            <p><strong>Characteristics Before Brands.</strong> GAL starts with supported golfer evidence and target characteristics before product configurations or commerce.</p>
          </div>
          <a class="ux5-club-close" href="/portal/" aria-label="Close Driver intelligence">Close Driver intelligence</a>
        </header>

        <nav class="ux5-club-tabs" aria-label="Driver intelligence sections">
          <a href="#driver-overview" aria-current="page">Overview</a>
          <a href="#driver-why">Why It Matters</a>
          <a href="#driver-recommendations">Recommendations</a>
          <a href="#driver-compare">Compare</a>
        </nav>

        <div class="ux5-club-panel-body">
          <section class="ux5-club-primary">
            <section class="ux5-club-overview" id="driver-overview">
              <header><p class="eyebrow">Quick View</p><h2>What GAL knows right now</h2></header>
              <article class="ux5-driver-snapshot">
                <h3>Driver Snapshot</h3>
                <p>${snapshotCopy}</p>
                <p class="ux5-source-note">Only compatible governed evidence is shown here. Missing measurements remain missing.</p>
              </article>
              <article class="ux5-fit-setup">
                <p class="eyebrow">Fit Setup</p><h3>Use known data first</h3>
                <p>Tell GAL Once applies here: valid profile, bag, measured and connected evidence should be reused. GAL asks only for missing, stale, or Driver-specific inputs.</p>
                <a href="/portal/profile">Review profile inputs</a>
              </article>
              <article class="ux5-target-characteristics">
                <p class="eyebrow">Target Characteristics</p><h3>What GAL is fitting for</h3>${targets}
              </article>
            </section>

            <section class="ux5-club-why" id="driver-why">
              <p class="eyebrow">Why It Matters</p><h2>Evidence before explanation</h2>
              <p>GAL explains how the target characteristics relate to your evidence, why a configuration qualifies, what is uncertain, and which evidence would strengthen or change the recommendation.</p>
              <div class="ux5-why-cards">
                <article><h3>Performance context</h3><p>Current-versus-target performance appears only when compatible measured or observed data supports the comparison.</p></article>
                <article><h3>What is holding you back</h3><p>GAL identifies a limiting factor only when the evidence supports that conclusion; otherwise it asks for the missing evidence.</p></article>
              </div>
            </section>

            <section class="ux5-club-recommendations" id="driver-recommendations">
              <p class="eyebrow">Recommendations</p><h2>Compatible configurations that follow the target</h2>
              ${candidates}
              <div class="driver-action-peers" aria-label="Possible recommendation actions"><span>Keep</span><span>Adjust</span><span>Reconfigure</span><span>Replace</span></div>
              <p class="fit-firewall">The current club is a valid peer option. Commerce appears only after the analytical decision and cannot change candidate rank.</p>
            </section>

            <section class="ux5-club-compare" id="driver-compare">
              <p class="eyebrow">Compare</p><h2>Compare the configuration—not just the logo</h2>
              <p>Head, loft or effective loft, settings, shaft profile, weight, length and other supported configuration details belong together when evidence supports them.</p>
              <p>If comparable configuration evidence is not available, GAL withholds the comparison instead of filling it with assumptions.</p>
            </section>
          </section>

          <aside class="ux5-club-explain" aria-label="Driver exploration">
            <article><p class="eyebrow">Why It Matters</p><h3>Understand the evidence</h3><p>${model.missingEvidence ? 'More compatible golfer evidence is required before GAL can quantify the performance impact.' : 'Review the evidence-linked target characteristics and uncertainty before choosing an action.'}</p></article>
            <article><p class="eyebrow">Recommendations</p><h3>Characteristics first</h3><p>${model.missingEvidence ? 'Recommendations are withheld until the missing evidence is resolved.' : `${model.candidates.length} governed configuration candidate(s) currently follow the evidence-backed target.`}</p></article>
            <article><p class="eyebrow">Compare</p><h3>Side-by-side when supported</h3><p>GAL compares configuration evidence, fit-relevant characteristics, and supported performance context—not brand popularity.</p></article>
            <article><p class="eyebrow">Inspect &amp; Specs</p><h3>Configuration detail</h3><p>Supported head, loft, setting, shaft and length details appear when they exist in governed Equipment Knowledge.</p></article>
            <article><p class="eyebrow">Real-World Results</p><h3>Outcome evidence</h3><p>Real-world outcome summaries appear only after GAL has attributable, governed results for comparable golfers or this golfer.</p></article>
          </aside>
        </div>

        <footer class="ux5-driver-follow-through">
          <article><p class="eyebrow">Next Action</p><h3>Choose the smallest defensible next step</h3><p>Keep, adjust, reconfigure, compare/test, or replace can all be correct outcomes. GAL does not assume a purchase is required.</p></article>
          <article><p class="eyebrow">Outcome Tracking</p><h3>Record what changed</h3><p>After a fitting action, GAL can connect the action to attributable outcome evidence rather than assuming the recommendation worked.</p></article>
          <article><p class="eyebrow">Progress Over Time</p><h3>Did the equipment opportunity resolve?</h3><p>Progress reflects evidence-backed equipment outcomes, resolutions and regressions—not a generic engagement score.</p><a href="/portal/progress">View Progress</a></article>
        </footer>
      </section>
    </div>`;
  } catch (error) {
    const code = error instanceof Error ? (error as Error & { code?: string }).code ?? error.message : '';
    if (code === 'AUTH_REQUIRED') return '<section class="my-gal-state"><h2>Sign in to use GAL AI Fitting.</h2></section>';
    return '<section class="my-gal-state"><h2>Driver Fit is temporarily unavailable.</h2><p>GAL will not substitute an ungoverned ranking while the fitting contract is unavailable.</p></section>';
  }
}
