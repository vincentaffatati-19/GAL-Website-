import { escapeHtml } from '../render/escape';
import { fetchGolferInsights, type GolferInsightRow } from './insights';

export function isDriverInsight(row: GolferInsightRow): boolean {
  return [row.insight_domain,row.subject_type,row.subject_key,row.scope_key].join(' ').toLowerCase().includes('driver');
}

function categoryMarker(label: string, key: string): string {
  return `<a class="bag-marker bag-marker-${key}" href="/portal/bag" aria-label="${label}: GAL needs more information"><span>${label}</span><small>Not evaluated</small></a>`;
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

  const nextOpportunity = driverMessage
    ? `<p class="eyebrow">Needs Attention</p><h2>GAL Sees a Driver Opportunity</h2><p>${driverMessage}</p><a class="button" href="/portal/insights?fit=driver">See Why</a>`
    : `<p class="eyebrow">Learning Your Bag</p><h2>Next Opportunity</h2><p><strong>GAL needs more information</strong> before identifying a governed equipment opportunity.</p><a class="button" href="/portal/bag">Review My Bag</a>`;

  return `
    <section class="tee-box-hero" aria-label="My GAL equipment intelligence overview">
      <div class="tee-box-content">
        <article class="tee-panel tee-panel-status">
          <p class="eyebrow">Bag Status</p>
          <h2>GAL is learning your equipment</h2>
          <p>GAL needs more information before it can describe the whole bag as evaluated or optimized.</p>
          <a href="/portal/bag">Review My Bag</a>
        </article>

        <div class="bag-stage" aria-label="Interactive equipment categories">
          ${categoryMarker('Driver', 'driver')}
          ${categoryMarker('Fairway', 'fairway')}
          ${categoryMarker('Hybrid', 'hybrid')}
          ${categoryMarker('Irons', 'irons')}
          ${categoryMarker('Wedges', 'wedges')}
          ${categoryMarker('Putter', 'putter')}
          ${categoryMarker('Ball', 'ball')}
          <div class="bag-hero" role="img" aria-label="GAL bag intelligence summary"></div>
        </div>

        <article class="tee-panel tee-panel-opportunity">
          ${nextOpportunity}
        </article>
      </div>
    </section>

    <section class="today-support-grid" aria-label="My GAL equipment tools">
      <article class="today-card"><p class="eyebrow">Bag Value</p><h2>Value data not available yet</h2><p>GAL will show retail, resale, or trade estimates only after a governed valuation method and current source data are available.</p><a href="/portal/bag">View My Bag</a></article>
      <article class="today-card"><p class="eyebrow">Bag User's Guide</p><h2>How My Bag Works</h2><p>Status markers distinguish what GAL knows, what needs attention, and what still needs evidence. Missing information is never treated as a good fit.</p><a href="/portal/bag">Open My Bag</a></article>
      <article class="today-card"><p class="eyebrow">Quick Actions</p><h2>Keep your equipment current</h2><div class="quick-actions"><a href="/portal/bag">Update Equipment</a><a href="/portal/guides">Browse Guides</a><a href="/portal/profile">Golfer Profile</a></div></article>
      <article class="today-card"><p class="eyebrow">Recent Insight</p><h2>${driverMessage ? 'Driver deserves review' : 'No active governed insight'}</h2><p>${driverMessage || 'When GAL has enough evidence to identify a material equipment opportunity, it will appear here.'}</p></article>
      <article class="today-card"><p class="eyebrow">Progress at a Glance</p><h2>Equipment progress builds over time</h2><p>No aggregate progress score is shown. GAL records evidence-backed equipment changes, outcomes, resolutions, and recurring issues.</p><a href="/portal/progress">View Progress</a></article>
    </section>
  `;
}
