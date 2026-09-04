import { escapeHtml } from '../render/escape';
import { fetchGolferInsights, insightLabel } from './insights';

export async function renderProgressSurface(): Promise<string> {
  try {
    const rows = await fetchGolferInsights();
    const progress = rows.filter((row) => ['RESOLVED','REGRESSED','EVIDENCE_PENDING','INEFFECTIVE'].includes(row.status));
    if (!progress.length) return '<section class="my-gal-state"><h2>No equipment outcomes recorded yet.</h2><p>Progress appears after a recommendation or equipment change has governed outcome evidence.</p></section>';
    return `<section class="equipment-list">${progress.map((row)=>`<article class="equipment-card"><p class="eyebrow">${escapeHtml(insightLabel(row.status) ?? '')}</p><h2>${escapeHtml(row.headline)}</h2><p>${escapeHtml(row.golfer_message)}</p></article>`).join('')}</section>`;
  } catch {
    return '<section class="my-gal-state"><h2>Progress is temporarily unavailable.</h2></section>';
  }
}
