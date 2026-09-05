import { escapeHtml } from '../render/escape';
import { fetchProfileFacts } from './client';
import type { ProfileFactRow } from './types';
import {
  MISS_DIRECTIONS,
  MISS_SHAPES,
  PROFILE_HOME_AREAS,
  STRIKE_LOCATIONS,
  dataQualityLabel,
  factsMatching,
  firstFactMatching,
  hasExternalSource,
  profileWorkspaceFromParams,
  type ProfileWorkspace,
} from './model';

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

function titleFromKey(key: string): string {
  return key.replaceAll('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function freshnessLabel(fact: ProfileFactRow): string {
  const date = fact.observed_at ?? fact.updated_at;
  if (!date) return 'Date not recorded';
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) return 'Date not recorded';
  const ageDays = Math.max(0, Math.floor((Date.now() - parsed.getTime()) / 86_400_000));
  if (fact.stale_after_days != null && ageDays > fact.stale_after_days) return `Stale · ${parsed.toLocaleDateString()}`;
  return `Updated ${parsed.toLocaleDateString()}`;
}

function sourceLabel(fact: ProfileFactRow): string {
  return fact.source || fact.source_category || 'Source not recorded';
}

function dataQualityClass(label: string): string {
  return label.toLowerCase().replaceAll(' / ', '-').replaceAll(' ', '-');
}

function factTile(fact: ProfileFactRow, label?: string): string {
  const quality = dataQualityLabel(fact);
  return `<article class="ux10-profile-fact">
    <span class="ux10-profile-fact-label">${escapeHtml(label ?? titleFromKey(fact.fact_key))}</span>
    <strong>${escapeHtml(valueText(fact.fact_value))}</strong>
    <span class="ux10-quality-chip ${escapeHtml(dataQualityClass(quality))}">${escapeHtml(quality)}</span>
    <small>${escapeHtml(sourceLabel(fact))} · ${escapeHtml(freshnessLabel(fact))}</small>
  </article>`;
}

function missingTile(label: string, guidance: string): string {
  return `<article class="ux10-profile-fact is-missing"><span class="ux10-profile-fact-label">${escapeHtml(label)}</span><strong>Not provided</strong><small>${escapeHtml(guidance)}</small></article>`;
}

function qualityLegend(): string {
  const rows = [
    ['Measured', 'Instrument or approved measurement source'],
    ['Observed', 'On-course or session evidence'],
    ['Self-Reported', 'Information you provided'],
    ['Inferred / Estimated', 'Model-derived only when governance allows'],
  ];
  return `<aside class="ux10-data-quality" aria-label="Data quality legend"><strong>Data quality</strong>${rows.map(([label, detail]) => `<span><i class="${escapeHtml(dataQualityClass(label))}" aria-hidden="true"></i><b>${escapeHtml(label)}</b><small>${escapeHtml(detail)}</small></span>`).join('')}</aside>`;
}

function workspaceHeader(title: string, subtitle: string): string {
  return `<header class="ux10-profile-workspace-header"><a href="/portal/profile" class="ux10-profile-back" aria-label="Back to Golfer Profile">←</a><div><p class="eyebrow">Golfer Profile</p><h1>${escapeHtml(title)}</h1><p>${escapeHtml(subtitle)}</p></div></header>`;
}

const AREA_TERMS: Record<Exclude<ProfileWorkspace, 'home' | 'connected'>, string[]> = {
  you: ['height', 'wrist', 'hand_size', 'handed', 'glove', 'gender', 'age'],
  game: ['handicap', 'score', 'goal', 'priority', 'frequency', 'skill', 'experience'],
  swing: ['speed', 'ball_speed', 'launch', 'spin', 'carry', 'attack', 'path', 'tempo', 'transition'],
  miss: ['miss', 'shape', 'strike', 'dispersion', 'curve', 'finish'],
  environment: ['environment', 'elevation', 'temperature', 'wind', 'firmness', 'location', 'course', 'altitude'],
};

function areaFacts(facts: ProfileFactRow[], key: keyof typeof AREA_TERMS): ProfileFactRow[] {
  return factsMatching(facts, AREA_TERMS[key]);
}

function connectedFacts(facts: ProfileFactRow[]): ProfileFactRow[] {
  return facts.filter(hasExternalSource);
}

function initials(displayName: string): string {
  return displayName.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]?.toUpperCase() ?? '').join('') || 'G';
}

function renderProfileHome(facts: ProfileFactRow[]): string {
  const nameFact = firstFactMatching(facts, ['display_name', 'full_name', 'golfer_name', 'name']);
  const handedFact = firstFactMatching(facts, ['handedness', 'handed']);
  const displayName = nameFact ? valueText(nameFact.fact_value) : 'Golfer';
  const handedness = handedFact ? valueText(handedFact.fact_value) : 'Handedness not provided';

  const counts: Record<string, number> = {
    you: areaFacts(facts, 'you').length,
    game: areaFacts(facts, 'game').length,
    swing: areaFacts(facts, 'swing').length,
    miss: areaFacts(facts, 'miss').length,
    environment: areaFacts(facts, 'environment').length,
    connected: connectedFacts(facts).length,
  };
  const started = PROFILE_HOME_AREAS.filter((area) => counts[area.key] > 0).length;

  const links: Record<Exclude<ProfileWorkspace, 'home'>, string> = {
    you: '/portal/profile?section=you',
    game: '/portal/profile?section=game',
    swing: '/portal/profile?section=swing',
    miss: '/portal/profile?section=miss',
    environment: '/portal/profile?section=environment',
    connected: '/portal/profile?section=connected',
  };

  return `<section class="ux10-profile-home" aria-labelledby="profile-home-title">
    <header class="ux10-profile-home-hero">
      <div class="ux10-profile-identity">
        <span class="ux10-profile-avatar" aria-hidden="true">${escapeHtml(initials(displayName))}</span>
        <div><p class="eyebrow">My Golfer Profile</p><h1 id="profile-home-title">${escapeHtml(displayName)}</h1><p>${escapeHtml(handedness)}</p><strong>Tell GAL Once. Connect It Once. Use It Everywhere.</strong></div>
      </div>
      <div class="ux10-profile-coverage"><strong>${started} of 6</strong><span>profile areas started</span><small>Coverage only — not golfer quality or fitting confidence.</small></div>
    </header>
    <div class="ux10-profile-area-list" aria-label="Profile areas">
      ${PROFILE_HOME_AREAS.map((area) => `<a class="ux10-profile-area-card" href="${links[area.key]}">
        <span><strong>${escapeHtml(area.label)}</strong><small>${escapeHtml(area.description)}</small></span>
        <span class="ux10-area-state ${counts[area.key] > 0 ? 'has-data' : 'needs-data'}">${counts[area.key] > 0 ? `${counts[area.key]} known` : 'Add information'}</span><b aria-hidden="true">›</b>
      </a>`).join('')}
    </div>
    ${qualityLegend()}
  </section>`;
}

function renderYou(facts: ProfileFactRow[]): string {
  const all = areaFacts(facts, 'you');
  const height = firstFactMatching(all, ['height']);
  const wrist = firstFactMatching(all, ['wrist']);
  const hand = firstFactMatching(all, ['hand_size', 'hand size']);
  const handed = firstFactMatching(all, ['handedness', 'handed']);
  return `<section class="ux10-profile-workspace ux10-profile-you">
    ${workspaceHeader('You / Measurements', 'Body measurements made simple and reusable across GAL.')}
    <div class="ux10-measurement-layout">
      <div class="ux10-measurement-visual" role="img" aria-label="Body measurement guidance"><span>Height</span><div class="ux10-measurement-line"></div><span>Wrist-to-floor</span><small>Use the How to Measure guidance before entering or updating a measurement.</small></div>
      <div class="ux10-profile-fact-grid">
        ${height ? factTile(height, 'Height') : missingTile('Height', 'Add your height when ready.')}
        ${wrist ? factTile(wrist, 'Wrist-to-Floor') : missingTile('Wrist-to-Floor', 'Measure from wrist crease to the floor.')}
        ${hand ? factTile(hand, 'Hand Size') : missingTile('Hand Size', 'Add hand size for grip and fitting context.')}
        ${handed ? factTile(handed, 'Handedness') : missingTile('Handedness', 'Tell GAL which side you play from.')}
      </div>
    </div>
    <div class="ux10-profile-actions"><button type="button" disabled aria-disabled="true">Update Measurements</button><a href="#how-to-measure">How to Measure</a></div>
    <section id="how-to-measure" class="ux10-profile-note"><strong>How to measure wrist-to-floor</strong><p>Stand naturally on level ground in golf shoes or similar footwear, let your arms hang naturally, and measure vertically from the wrist crease to the floor.</p></section>
    ${qualityLegend()}
  </section>`;
}

function renderGame(facts: ProfileFactRow[]): string {
  const all = areaFacts(facts, 'game');
  return `<section class="ux10-profile-workspace">
    ${workspaceHeader('Your Game', 'Scoring context and goals help GAL keep equipment advice relevant.')}
    <div class="ux10-profile-fact-grid">${all.length ? all.map((fact) => factTile(fact)).join('') : missingTile('Your Game', 'Add handicap, scoring context, goals or priorities when available.')}</div>
    ${qualityLegend()}
  </section>`;
}

function swingMetric(facts: ProfileFactRow[], label: string, terms: string[]): string {
  const fact = firstFactMatching(facts, terms);
  return fact ? factTile(fact, label) : missingTile(label, 'No current governed value.') ;
}

function renderSwing(facts: ProfileFactRow[], params: URLSearchParams): string {
  const club = (params.get('club') ?? 'driver').toLowerCase() === '7-iron' ? '7-iron' : 'driver';
  const allSwing = areaFacts(facts, 'swing');
  const clubSpecific = allSwing.filter((fact) => {
    const key = fact.fact_key.toLowerCase();
    if (club === '7-iron') return key.includes('7_iron') || key.includes('7-iron') || key.includes('seven_iron');
    return key.includes('driver') || (!key.includes('iron') && !key.includes('hybrid') && !key.includes('wood'));
  });
  const metrics = clubSpecific.length ? clubSpecific : allSwing;
  return `<section class="ux10-profile-workspace ux10-profile-swing">
    ${workspaceHeader('Your Swing', 'Key swing and ball-flight data, with source and freshness preserved.')}
    <nav class="ux10-segmented" aria-label="Swing club"><a href="/portal/profile?section=swing&club=driver"${club === 'driver' ? ' aria-current="page"' : ''}>Driver</a><a href="/portal/profile?section=swing&club=7-iron"${club === '7-iron' ? ' aria-current="page"' : ''}>7-Iron</a></nav>
    <div class="ux10-swing-layout">
      <div class="ux10-swing-visual"><strong>${club === 'driver' ? 'Driver' : '7-Iron'} data</strong><p>${metrics.length ? 'GAL is showing only the current sourced facts available for this swing view.' : 'GAL needs more current swing information for this club.'}</p></div>
      <div class="ux10-profile-fact-grid ux10-swing-metrics">
        ${swingMetric(metrics, 'Club Speed', ['club_speed', 'driver_speed', 'speed'])}
        ${swingMetric(metrics, 'Ball Speed', ['ball_speed'])}
        ${swingMetric(metrics, 'Launch', ['launch'])}
        ${swingMetric(metrics, 'Spin Rate', ['spin'])}
        ${swingMetric(metrics, 'Carry', ['carry'])}
        ${swingMetric(metrics, 'Attack Angle', ['attack'])}
        ${swingMetric(metrics, 'Club Path', ['path'])}
      </div>
    </div>
    <div class="ux10-profile-actions"><a class="ux10-primary-action" href="/portal/profile?section=swing&club=${club}&view=all">View All Swing Data</a><a href="/portal/profile?section=connected">Connect / Import Golf Data</a></div>
    ${qualityLegend()}
  </section>`;
}

function renderMiss(facts: ProfileFactRow[]): string {
  const all = areaFacts(facts, 'miss');
  const existing = all.length ? `<div class="ux10-existing-facts"><strong>What GAL currently knows</strong>${all.slice(0, 4).map((fact) => factTile(fact)).join('')}</div>` : '<p class="ux10-profile-missing-copy">No current miss profile is stored. Choose what best represents your typical miss.</p>';
  return `<section class="ux10-profile-workspace ux10-profile-miss">
    ${workspaceHeader('Your Miss', 'Show GAL your typical finish direction, shot shape and strike location.')}
    ${existing}
    <fieldset class="ux10-miss-step"><legend>1. Where does your driver ball usually finish?</legend><div class="ux10-choice-grid ux10-direction-grid">${MISS_DIRECTIONS.map((choice) => `<button type="button" data-miss-direction="${choice.toLowerCase()}">${choice}</button>`).join('')}</div></fieldset>
    <fieldset class="ux10-miss-step"><legend>2. What shape does it usually take?</legend><div class="ux10-choice-grid">${MISS_SHAPES.map((choice) => `<button type="button" data-miss-shape="${choice.toLowerCase()}">${choice}</button>`).join('')}</div></fieldset>
    <fieldset class="ux10-miss-step"><legend>3. Where do you usually strike the face?</legend><div class="ux10-clubface" aria-label="Strike location"><span class="face-grooves" aria-hidden="true"></span>${STRIKE_LOCATIONS.map((choice) => `<button type="button" class="strike-${choice.toLowerCase()}" data-strike-location="${choice.toLowerCase()}">${choice}</button>`).join('')}</div></fieldset>
    <button class="ux10-primary-action" type="button" disabled aria-disabled="true">Save My Miss Profile</button><small class="ux10-action-note">Profile editing will activate only with the governed write path; this review does not pretend a disabled action has saved data.</small>
    ${qualityLegend()}
  </section>`;
}

function renderEnvironment(facts: ProfileFactRow[]): string {
  const all = areaFacts(facts, 'environment');
  return `<section class="ux10-profile-workspace">
    ${workspaceHeader('Where You Play', 'Your usual playing environment is context, separate from any specific fitting session.')}
    <div class="ux10-profile-fact-grid">${all.length ? all.map((fact) => factTile(fact)).join('') : missingTile('Playing Context', 'Add location, altitude, typical temperature, wind or firmness when available.')}</div>
    <div class="ux10-profile-actions"><button type="button" disabled aria-disabled="true">Update Playing Conditions</button></div>
    ${qualityLegend()}
  </section>`;
}

function renderConnected(facts: ProfileFactRow[]): string {
  const sourced = connectedFacts(facts);
  const providers = [
    ['GHIN', 'Handicap and scoring context'],
    ['Arccos', 'Rounds, shots and club-distance evidence'],
    ['TrackMan', 'Launch-monitor measurements'],
    ['Garmin Golf', 'Rounds and performance data'],
    ['Other Launch Monitor', 'Import data from another supported source'],
  ];
  return `<section class="ux10-profile-workspace ux10-profile-connected">
    ${workspaceHeader('Connected Golf', 'Connect approved sources so GAL can learn without asking you for the same information again.')}
    <div class="ux10-connection-list">${providers.map(([name, detail]) => `<article class="ux10-connection-card"><span class="ux10-provider-mark" aria-hidden="true">${escapeHtml(name.slice(0, 2).toUpperCase())}</span><div><strong>${escapeHtml(name)}</strong><p>${escapeHtml(detail)}</p><small>Not connected</small></div><button type="button" disabled aria-disabled="true">Unavailable in this review</button></article>`).join('')}</div>
    <article class="ux10-gal-learned"><span aria-hidden="true">◎</span><div><strong>What GAL Learned</strong><p>${sourced.length ? `${sourced.length} sourced profile fact${sourced.length === 1 ? '' : 's'} currently carry external provenance. GAL preserves their source and freshness.` : 'No externally sourced profile facts are available yet.'}</p></div></article>
    ${qualityLegend()}
  </section>`;
}

export async function renderGolferProfile(params: URLSearchParams = new URLSearchParams()): Promise<string> {
  try {
    const facts = await fetchProfileFacts();
    const workspace = profileWorkspaceFromParams(params);
    if (workspace === 'you') return renderYou(facts);
    if (workspace === 'game') return renderGame(facts);
    if (workspace === 'swing') return renderSwing(facts, params);
    if (workspace === 'miss') return renderMiss(facts);
    if (workspace === 'environment') return renderEnvironment(facts);
    if (workspace === 'connected') return renderConnected(facts);
    return renderProfileHome(facts);
  } catch {
    return '<section class="my-gal-state"><p class="eyebrow">Golfer Profile</p><h2>Your profile is temporarily unavailable.</h2><p>GAL will not substitute invented profile information while governed data cannot be loaded.</p></section>';
  }
}
