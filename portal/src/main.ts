import './styles/portal.css';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from './branding';
import { resolvePortalRoute, type PortalRoute } from './router';

const NAV_ITEMS: Array<{ route: PortalRoute; label: string }> = [
  { route: 'today', label: 'Today' },
  { route: 'bag', label: 'My Bag' },
  { route: 'insights', label: 'Insights' },
  { route: 'guides', label: 'Guides' },
  { route: 'progress', label: 'Progress' },
];

function routeHref(route: PortalRoute): string {
  return route === 'today' ? '/portal/' : `/portal/${route}`;
}

function renderShell(): void {
  const app = document.querySelector<HTMLElement>('#app');
  if (!app) throw new Error('My GAL app mount is missing');

  document.documentElement.style.fontFamily = BRAND_FONT_FAMILY;
  const currentRoute = resolvePortalRoute(window.location.pathname);
  const currentLabel = NAV_ITEMS.find((item) => item.route === currentRoute)?.label ?? 'Today';

  app.innerHTML = `
    <div class="my-gal-shell">
      <header class="my-gal-header">
        <div class="my-gal-header-inner">
          <a class="my-gal-brand" href="/portal/" aria-label="My GAL home">
            <img class="my-gal-brand-logo" src="${BRAND_LOGO_SRC}" alt="${BRAND_LOGO_ALT}">
          </a>
          <div class="my-gal-product-name">
            <strong>My GAL</strong>
            <small>Your Equipment Intelligence Center</small>
          </div>
        </div>
      </header>
      <nav class="my-gal-nav" aria-label="My GAL primary navigation">
        ${NAV_ITEMS.map((item) => `<a href="${routeHref(item.route)}"${item.route === currentRoute ? ' aria-current="page"' : ''}>${item.label}</a>`).join('')}
      </nav>
      <main class="my-gal-main" id="main-content">
        <p class="eyebrow">Equipment Intelligence</p>
        <h1>${currentLabel}</h1>
        <p class="intro">My GAL will show what deserves your attention, why it matters, and what to do next using governed equipment intelligence.</p>
        <section class="my-gal-state" aria-labelledby="building-title">
          <h2 id="building-title">Your equipment intelligence is being prepared.</h2>
          <p>This first release shell is ready for authenticated data and the Equipment Brief in the next implementation tasks.</p>
        </section>
      </main>
    </div>
  `;
}

renderShell();
