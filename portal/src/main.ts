import './styles/portal.css';
import './styles/rcux3.css';
import './styles/ux10.css';
import './styles/ux10-step1-header.css';
import './styles/ux10-dashboard-step2.css';
import './styles/ux10-profile.css';
import './styles/ux10-step3-profile-home.css';
import { BRAND_FONT_FAMILY } from './branding';
import { resolvePortalRoute, type PortalRoute } from './router';
import { renderMyBag } from './bag/render';
import { renderDriverFit } from './fitting/driver/render';
import { renderDriverGuide } from './guides/driver';
import { renderGolferProfile } from './profile/render';
import { renderTodaySurface } from './surfaces/today';
import { renderInsightsSurface } from './surfaces/insights';
import { renderProgressSurface } from './surfaces/progress';
import { renderUx10SharedHeader, UX10_PRIMARY_NAV } from './shell/header';
import { bindUx10Personalization } from './ux10/bind';

async function routeContent(route: PortalRoute): Promise<string> {
  const params = new URLSearchParams(window.location.search);
  if (route === 'profile') return renderGolferProfile(params);
  if (route === 'bag') return renderMyBag();
  if (route === 'guides' && (params.get('category') ?? 'driver').toLowerCase() === 'driver') return renderDriverGuide();
  if (route === 'insights' && params.get('fit')?.toLowerCase() === 'driver') return renderDriverFit();
  if (route === 'insights') return renderInsightsSurface();
  if (route === 'progress') return renderProgressSurface();
  return renderTodaySurface();
}

async function renderShell(): Promise<void> {
  const app = document.querySelector<HTMLElement>('#app');
  if (!app) throw new Error('My GAL app mount is missing');

  document.documentElement.style.fontFamily = BRAND_FONT_FAMILY;
  const currentRoute = resolvePortalRoute(window.location.pathname);
  const currentLabel = currentRoute === 'profile'
    ? 'Golfer Profile'
    : UX10_PRIMARY_NAV.find((item) => item.route === currentRoute)?.label ?? 'Today';

  app.innerHTML = `
    <div class="my-gal-shell ux10-shell" data-ux-version="GAL-UX10.02-RC1">
      ${renderUx10SharedHeader(currentRoute)}
      <main class="my-gal-main ux10-main${currentRoute === 'today' ? ' my-gal-main-today ux10-main-today' : ''}${currentRoute === 'profile' ? ' my-gal-main-profile ux10-main-profile' : ''}" id="main-content">
        ${currentRoute === 'today' || currentRoute === 'profile' ? '' : `<p class="eyebrow">Equipment Intelligence</p><h1>${currentLabel}</h1><p class="intro">My GAL shows what GAL knows, what deserves attention, why it matters, and what to do next without inventing fit claims.</p>`}
        <div id="route-content"><section class="my-gal-state"><h2>Loading your equipment intelligence…</h2></section></div>
      </main>
    </div>
  `;

  const routeMount = document.querySelector<HTMLElement>('#route-content');
  if (routeMount) {
    routeMount.innerHTML = await routeContent(currentRoute);
    bindUx10Personalization(routeMount);
  }
}

void renderShell();
