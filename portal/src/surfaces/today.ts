import { escapeHtml } from '../render/escape';
import { fetchGolferInsights, type GolferInsightRow } from './insights';

export function isDriverInsight(row: GolferInsightRow): boolean {
  return [row.insight_domain,row.subject_type,row.subject_key,row.scope_key].join(' ').toLowerCase().includes('driver');
}

export async function renderTodaySurface(): Promise<string> {
  try {
    const rows = await fetchGolferInsights();
    const driver = rows.find((row) => row.status === 'ACTIVE' && isDriverInsight(row));
    if (!driver) return '<section class="my-gal-state"><h2>Your Equipment Brief</h2><p>No governed Driver opportunity is active right now. GAL will not create one from missing data alone.</p><a class="button" href="/portal/bag">Review My Bag</a></section>';
    return `<section class="equipment-card"><p class="eyebrow">Needs Attention</p><h2>GAL Sees a Driver Opportunity</h2><p>${escapeHtml(driver.golfer_message)}</p><a class="button" href="/portal/insights?fit=driver">Review Driver Opportunity</a></section>`;
  } catch {
    return '<section class="my-gal-state"><h2>Your Equipment Brief is temporarily unavailable.</h2></section>';
  }
}
