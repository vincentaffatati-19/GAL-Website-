import { escapeHtml } from '../render/escape';
import { renderUx5BagEnvironment, type Ux5BagCategory } from '../ux5/bagEnvironment';
import { fetchGolferInsights, type GolferInsightRow } from './insights';

export function isDriverInsight(row: GolferInsightRow): boolean {
  return [row.insight_domain, row.subject_type, row.subject_key, row.scope_key].join(' ').toLowerCase().includes('driver');
}

function todayCategories(hasDriverOpportunity: boolean): Ux5BagCategory[] {
  const needsEvidence = 'GAL needs more information';
  return [
    {
      key: 'driver',
      label: 'Driver',
      status: hasDriverOpportunity ? 'NEEDS_ATTENTION' : 'NOT_EVALUATED',
      detail: hasDriverOpportunity ? 'Review governed Driver insight' : needsEvidence,
      href: hasDriverOpportunity ? '/portal/insights?fit=driver' : '/portal/bag',
    },
    { key: 'fairway', label: '3 Wood', status: 'NOT_EVALUATED', detail: needsEvidence, href: '/portal/bag' },
    { key: 'hybrid', label: 'Hybrid', status: 'NOT_EVALUATED', detail: needsEvidence, href: '/portal/bag' },
    { key: 'irons', label: 'Irons', status: 'NOT_EVALUATED', detail: needsEvidence, href: '/portal/bag' },
    { key: 'wedges', label: 'Wedges', status: 'NOT_EVALUATED', detail: needsEvidence, href: '/portal/bag' },
    { key: 'putter', label: 'Putter', status: 'NOT_EVALUATED', detail: needsEvidence, href: '/portal/bag' },
    { key: 'ball', label: 'Ball', status: 'NOT_EVALUATED', detail: needsEvidence, href: '/portal/bag' },
  ];
}

function howItWorks(): string {
  const steps = [
    ['1', 'Tap a Club', 'Select any equipment category in your bag.'],
    ['2', 'See Why', 'GAL shows what it knows and what needs evidence.'],
    ['3', 'Explore', 'Review insights, fit guidance and comparisons.'],
    ['4', 'Take Action', 'Keep, adjust, test or replace when evidence supports it.'],
    ['5', 'Track Progress', 'See what changed and whether the issue resolved.'],
  ];
  return `<section class="ux5-how-it-works" aria-label="How It Works">
    <div class="ux5-section-heading"><div><p class="eyebrow">How It Works</p><h2>Simple. Visual. Personal.</h2></div></div>
    <div class="ux5-how-steps">${steps.map(([number, title, detail]) => `<article><span>${number}</span><div><strong>${title}</strong><small>${detail}</small></div></article>`).join('')}</div>
  </section>`;
}

export async function renderTodaySurface(): Promise<string> {
  let driverMessage = '';
  try {
    const rows = await fetchGolferInsights();
    const driver = rows.find((row) => row.status === 'ACTIVE' && isDriverInsight(row));
    if (driver) driverMessage = escapeHtml(driver.golfer_message);
  } catch {
    driverMessage = '';
  }

  const hasDriverOpportunity = Boolean(driverMessage);
  const nextOpportunity = hasDriverOpportunity
    ? `<p class="eyebrow">Needs Attention</p><h2>GAL Sees a Driver Opportunity</h2><p>${driverMessage}</p><a class="button" href="/portal/insights?fit=driver">See Why</a>`
    : `<p class="eyebrow">Learning Your Bag</p><h2>Next Opportunity</h2><p><strong>GAL needs more information</strong> before identifying a governed equipment opportunity.</p><a class="button" href="/portal/bag">Review My Bag</a>`;

  const bagEnvironment = renderUx5BagEnvironment({
    categories: todayCategories(hasDriverOpportunity),
    contextLabel: 'My GAL equipment intelligence bag environment',
  });

  return `
    <section class="ux5-dashboard" aria-label="My GAL Intelligence Dashboard">
      <header class="ux5-dashboard-heading">
        <div><p class="eyebrow">My GAL</p><h1>Your bag. Your game. Smarter together.</h1></div>
      </header>

      <div class="ux5-dashboard-main">
        <div class="ux5-bag-environment-slot">${bagEnvironment}</div>
        <aside class="ux5-dashboard-summary" aria-label="Bag intelligence summary">
          <article class="ux5-panel ux5-bag-status">
            <p class="eyebrow">Bag Status</p>
            <h2>GAL is learning your equipment</h2>
            <p>GAL needs more information before it can describe the whole bag as evaluated or optimized.</p>
            <a href="/portal/bag">Review My Bag</a>
          </article>
          <article class="ux5-panel ux5-next-opportunity">${nextOpportunity}</article>
          <article class="ux5-panel ux5-bag-value">
            <p class="eyebrow">Bag Value</p><h2>Value data not available yet</h2>
            <p>Retail, resale and trade estimates appear only after GAL has a governed valuation method and current source data.</p>
            <a href="/portal/bag">View My Bag</a>
          </article>
        </aside>
      </div>

      <section class="ux5-dashboard-support" aria-label="My GAL equipment tools">
        <article class="ux5-panel"><p class="eyebrow">Bag User's Guide</p><h2>How My Bag Works</h2><p>Status markers distinguish what GAL knows, what needs attention, and what still needs evidence. Missing information is never treated as a good fit.</p><a href="/portal/bag#bag-guide">Open Guide</a></article>
        <article class="ux5-panel"><p class="eyebrow">Quick Actions</p><h2>Keep your equipment current</h2><div class="quick-actions"><a href="/portal/bag">Update Equipment</a><a href="/portal/guides">Browse Guides</a><a href="/portal/profile">Golfer Profile</a></div></article>
        <article class="ux5-panel"><p class="eyebrow">Recent Insight</p><h2>${hasDriverOpportunity ? 'Driver deserves review' : 'No active governed insight'}</h2><p>${driverMessage || 'When GAL has enough evidence to identify a material equipment opportunity, it will appear here.'}</p>${hasDriverOpportunity ? '<a href="/portal/insights?fit=driver">View Insight</a>' : ''}</article>
        <article class="ux5-panel"><p class="eyebrow">Progress at a Glance</p><h2>Equipment progress builds over time</h2><p>No aggregate progress score is shown. GAL records evidence-backed equipment changes, outcomes, resolutions, and recurring issues.</p><a href="/portal/progress">View Progress</a></article>
      </section>

      ${howItWorks()}

      <section class="ux5-every-club" aria-label="Works for Every Club">
        <div><p class="eyebrow">Works for Every Club</p><h2>One intelligence pattern across your entire bag.</h2></div>
        <div class="ux5-club-list"><span>3 Wood</span><span>Hybrid</span><span>Irons</span><span>Wedges</span><span>Putter</span><span>Ball</span></div>
      </section>
    </section>
  `;
}
