export type PortalRoute = 'today' | 'bag' | 'insights' | 'guides' | 'progress';

const ROUTES = new Set<PortalRoute>(['today', 'bag', 'insights', 'guides', 'progress']);

export function resolvePortalRoute(pathname: string): PortalRoute {
  const normalized = pathname.replace(/\/+$/, '');
  const segment = normalized.split('/').filter(Boolean)[1]?.toLowerCase() as PortalRoute | undefined;
  return segment && ROUTES.has(segment) ? segment : 'today';
}
