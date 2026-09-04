import './styles/portal.css';
import './styles/rcux3.css';
import './styles/ux5-mid.css';
import './styles/ux5-driver.css';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from './branding';
import { resolvePortalRoute, type PortalRoute } from './router';
import { renderMyBag } from './bag/render';
import { renderDriverFit } from './fitting/driver/render';
import { renderDriverGuide } from './guides/driver';
import { renderGolferProfile } from './profile/render';
import { renderTodaySurface } from './surfaces/today';
import { renderInsightsSurface } from './surfaces/insights';
import { renderProgressSurface } from './surfaces/progress';

const NAV_ITEMS: Array<{ route: Exclude<PortalRoute, 'profile'>; label: string }> = [
  { route: 'today', label: 'Today' },
  { route: 'bag', label: 'My Bag' },
  { route: 'insights', label: 'Insights' },
  { route: 'guides', label: 'Guides' },
  { route: 'progress', label: 'Progress' },
];

function routeHref(route: Exclude<PortalRoute, 'profile'>): string {
  return route === 'today' ? '/portal/' : `/portal/${route}`;
}

async function routeContent(route: PortalRoute): Promise<string> {
  const params = new URLSearchParams(window.location.search);
  if (route === 'profile') return renderGolferProfile();
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
    : NAV_ITEMS.find((item) => item.route === currentRoute)?.label ?? 'Today';

  app.innerHTML = `
    <div class="my-gal-shell ux5-shell" data-ux-version="GAL-UX5-MID-RC1">
      <header class="my-gal-header ux5-app-header">
        <div class="my-gal-header-inner ux5-app-header-inner">
          <a class="my-gal-brand ux5-brand" href="/portal/" aria-label="My GAL home">
            <img class="my-gal-brand-logo ux5-brand-logo" src="${BRAND_LOGO_SRC}" alt="${BRAND_LOGO_ALT}">
          </a>
          <div class="my-gal-product-name ux5-product-name">
            <strong>My GAL</strong>
            <small>Your Equipment Intelligence Center</small>
          </div>
          <nav class="my-gal-nav ux5-primary-nav" aria-label="My GAL primary navigation">
            ${NAV_ITEMS.map((item) => `<a href="${routeHref(item.route)}"${item.route === currentRoute ? ' aria-current="page"' : ''}>${item.label}</a>`).join('')}
          </nav>
          <a class="profile-access ux5-profile-access" href="/portal/profile" aria-label="Golfer Profile"${currentRoute === 'profile' ? ' aria-current="page"' : ''}>Golfer Profile</a>
        </div>
      </header>
      <main class="my-gal-main ux5-main${currentRoute === 'today' ? ' my-gal-main-today ux5-main-today' : ''}${currentRoute === 'profile' ? ' my-gal-main-profile ux5-main-profile' : ''}" id="main-content">
        ${currentRoute === 'today' || currentRoute === 'profile' ? '' : `<p class="eyebrow">Equipment Intelligence</p><h1>${currentLabel}</h1><p class="intro">My GAL shows what GAL knows, what deserves attention, why it matters, and what to do next without inventing fit claims.</p>`}
        <div id="route-content"><section class="my-gal-state"><h2>Loading your equipment intelligence…</h2></section></div>
      </main>
    </div>
  `;

  const routeMount = document.querySelector<HTMLElement>('#route-content');
  if (routeMount) routeMount.innerHTML = await routeContent(currentRoute);
}

void renderShell();
