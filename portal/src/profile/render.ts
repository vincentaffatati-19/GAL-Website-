import { escapeHtml } from '../render/escape';
import { fetchProfileFacts } from './client';
import { completedProfileAreaCount, summarizeProfileAreas, type ProfileFactRow } from './types';

function valueText(value: unknown): string {
  if (value == null) return 'Not provided';
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') return String(value);
  if (Array.isArray(value)) return value.map(valueText).join(', ');
  if (typeof value === 'object') {
    const values = Object.values(value as Record<string, unknown>).filter((entry) => entry != null);
    return values.length ? values.map(valueText).join(' · ') : 'Provided';
  }
  return 'Provided';
}

function freshnessLabel(fact: ProfileFactRow): string {
  const date = fact.observed_at ?? fact.updated_at;
  if (!date) return 'Date not recorded';
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) return 'Date not recorded';
  const ageDays = Math.max(0, Math.floor((Date.now() - parsed.getTime()) / 86_400_000));
  if (fact.stale_after_days != null && ageDays > fact.stale_after_days) return `Stale · observed ${parsed.toLocaleDateString()}`;
  return `Observed ${parsed.toLocaleDateString()}`;
}

function factCard(fact: ProfileFactRow): string {
  const source = fact.source || fact.source_category || 'Golfer provided';
  return `<li class="profile-fact"><strong>${escapeHtml(fact.fact_key.replaceAll('_', ' '))}</strong><span>${escapeHtml(valueText(fact.fact_value))}</span><small>${escapeHtml(source)} · ${escapeHtml(freshnessLabel(fact))}</small></li>`;
}

function areaCard(label: string, key: string, facts: ProfileFactRow[]): string {
  const factList = facts.length
    ? `<ul class="profile-facts">${facts.slice(0, 4).map(factCard).join('')}</ul>`
    : '<p class="profile-missing">GAL needs more information here.</p>';
  return `<article class="profile-area profile-area-${key}" data-profile-area="${key}"><p class="eyebrow">${escapeHtml(label)}</p><h2>${facts.length ? `${facts.length} known input${facts.length === 1 ? '' : 's'}` : 'Not started'}</h2>${factList}<a href="#${key}-details">Review ${escapeHtml(label)}</a></article>`;
}

function measurementGuidance(): string {
  return `<section class="profile-deep-dive" id="you-details"><div><p class="eyebrow">You · Measurement</p><h2>Wrist-to-floor</h2><p>Stand naturally on a level floor in normal golf shoes or similar footwear. Let your arms hang naturally and measure vertically from the wrist crease to the floor.</p></div><div class="measurement-figure" aria-label="Wrist-to-floor measurement illustration"><span class="measure-person" aria-hidden="true"></span><span class="measure-line" aria-hidden="true"></span><small>Wrist crease → floor</small></div></section>`;
}

function missGuidance(): string {
  return `<section class="profile-deep-dive miss-capture" id="miss-details"><div><p class="eyebrow">Your Miss</p><h2>Show GAL what the miss looks like</h2><p>Graphical capture keeps shot shape and strike tendency separate from equipment conclusions.</p></div><div><div class="shot-shape-lane" aria-label="Shot-shape selection example"><span>Left</span><span>Draw</span><span>Straight</span><span>Fade</span><span>Slice</span></div><div class="strike-grid" aria-label="Clubface strike-zone example">${Array.from({ length: 9 }, (_, index) => `<span aria-label="Strike zone ${index + 1}"></span>`).join('')}</div></div></section>`;
}

function environmentGuidance(): string {
  return `<section class="profile-deep-dive" id="environment-details"><div><p class="eyebrow">Where You Play</p><h2>Your normal environment is context—not every test condition</h2><p>GAL can learn elevation, temperature, wind and firmness as your usual playing context while preserving the actual conditions of each fitting or test session separately.</p></div><div class="environment-grid"><span>Elevation</span><span>Temperature</span><span>Wind</span><span>Firmness</span></div></section>`;
}

function connectGolf(): string {
  const groups = [
    ['On-Course', 'Rounds, dispersion and club-use evidence'],
    ['Launch Monitors', 'Measured speed, launch, spin and delivery'],
    ['Handicap', 'Authoritative scoring context when approved'],
    ['Fitness / Body', 'Fitting-relevant physical measurements only'],
    ['Weather / Location', 'Environment evidence with permission'],
  ];
  return `<section class="connect-golf" aria-labelledby="connect-golf-title"><div class="section-heading"><div><p class="eyebrow">Connect Your Golf</p><h2 id="connect-golf-title">Tell GAL Once — or Connect It Once.</h2><p>Approved connections can feed the shared GAL Evidence Layer. Examples below are illustrative until technical and commercial access is approved.</p></div></div><div class="connect-golf-grid">${groups.map(([name, detail]) => `<article><span class="connection-state">Illustrative connection</span><h3>${escapeHtml(name)}</h3><p>${escapeHtml(detail)}</p><button type="button" disabled aria-disabled="true">Not connected</button></article>`).join('')}</div></section>`;
}

export async function renderGolferProfile(): Promise<string> {
  try {
    const facts = await fetchProfileFacts();
    const areas = summarizeProfileAreas(facts);
    const completed = completedProfileAreaCount(facts);

    return `<section class="golfer-profile" aria-label="Build Your GAL Golfer">
      <header class="profile-hero"><div><p class="eyebrow">Build Your GAL Golfer</p><h1>The more GAL understands your game, the better we can fit your equipment.</h1><p><strong>Tell GAL Once.</strong> GAL responsibly reuses valid, semantically compatible information and asks again only when data is missing, stale, or genuinely context-specific.</p></div><div class="profile-completeness"><strong>${completed} of 5</strong><span>Profile completeness · data coverage</span><small>This measures known profile areas, not golfer quality or fitting confidence.</small></div></header>

      <div class="golfer-profile-hub">
        <div class="golfer-figure" role="img" aria-label="Adaptive golfer representation placeholder"><span class="golfer-head"></span><span class="golfer-body"></span><span class="golfer-club"></span><small>Representation adapts only from known age-band, presentation and handedness data.</small></div>
        ${areas.map((area) => areaCard(area.label, area.key, area.facts)).join('')}
      </div>

      ${measurementGuidance()}
      ${missGuidance()}
      ${environmentGuidance()}
      ${connectGolf()}

      <section class="profile-trust"><p class="eyebrow">Your data, with context</p><h2>Source, freshness and control travel with the value.</h2><p>Measured, self-reported, imported and missing values remain distinguishable. You can update a value when it no longer represents your game.</p></section>
    </section>`;
  } catch {
    return '<section class="my-gal-state"><p class="eyebrow">Golfer Profile</p><h2>Your profile is temporarily unavailable.</h2><p>GAL will not substitute invented profile information while the governed data cannot be loaded.</p></section>';
  }
}
