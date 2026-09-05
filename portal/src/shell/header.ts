import { BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';
import type { PortalRoute } from '../router';

export const UX10_PRIMARY_NAV: Array<{ route: Exclude<PortalRoute, 'profile'>; label: string }> = [
  { route: 'today', label: 'Today' },
  { route: 'bag', label: 'My Bag' },
  { route: 'insights', label: 'Insights' },
  { route: 'guides', label: 'Guides' },
  { route: 'progress', label: 'Progress' },
];

export function ux10RouteHref(route: Exclude<PortalRoute, 'profile'>): string {
  return route === 'today' ? '/portal/' : `/portal/${route}`;
}

export function renderUx10SharedHeader(currentRoute: PortalRoute): string {
  return `<header class="my-gal-header ux10-app-header" data-ux10-shared-header="true">
    <div class="my-gal-header-inner ux10-app-header-inner">
      <a class="my-gal-brand ux10-brand" href="/portal/" aria-label="My GAL home">
        <img class="my-gal-brand-logo ux10-brand-logo" src="${BRAND_LOGO_SRC}" alt="${BRAND_LOGO_ALT}">
      </a>
      <div class="my-gal-product-name ux10-product-name">
        <strong>My GAL</strong>
        <small>Your Equipment Intelligence Center</small>
      </div>
      <nav class="my-gal-nav ux10-primary-nav" aria-label="My GAL primary navigation">
        ${UX10_PRIMARY_NAV.map((item) => `<a href="${ux10RouteHref(item.route)}"${item.route === currentRoute ? ' aria-current="page"' : ''}>${item.label}</a>`).join('')}
      </nav>
      <a class="profile-access ux10-profile-access" href="/portal/profile" aria-label="Golfer Profile"${currentRoute === 'profile' ? ' aria-current="page"' : ''}>Golfer Profile</a>
    </div>
  </header>`;
}
