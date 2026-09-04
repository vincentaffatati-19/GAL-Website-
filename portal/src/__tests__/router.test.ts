import { describe, expect, it } from 'vitest';
import { resolvePortalRoute } from '../router';

describe('resolvePortalRoute', () => {
  it('uses Today as the default My GAL route', () => {
    expect(resolvePortalRoute('/portal/')).toBe('today');
    expect(resolvePortalRoute('/portal')).toBe('today');
  });

  it.each([
    ['/portal/today', 'today'],
    ['/portal/bag', 'bag'],
    ['/portal/insights', 'insights'],
    ['/portal/guides', 'guides'],
    ['/portal/progress', 'progress'],
  ] as const)('maps %s to %s', (path, route) => {
    expect(resolvePortalRoute(path)).toBe(route);
  });

  it('fails safely to Today for unknown portal paths', () => {
    expect(resolvePortalRoute('/portal/not-a-real-route')).toBe('today');
  });
});
