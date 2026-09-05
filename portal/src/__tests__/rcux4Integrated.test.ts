import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { entitlementsFor, preserveAnalyticalOrder } from '../entitlements/model';
import { resolvePortalRoute } from '../router';

const here = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(here, '..');
const main = readFileSync(resolve(srcRoot, 'main.ts'), 'utf8');
const bag = readFileSync(resolve(srcRoot, 'bag/render.ts'), 'utf8');
const profile = readFileSync(resolve(srcRoot, 'profile/render.ts'), 'utf8');
const driver = readFileSync(resolve(srcRoot, 'fitting/driver/render.ts'), 'utf8');

describe('shared analytical contracts retained through GAL UX10.02', () => {
  it('keeps the connected golfer journey and route contracts intact', () => {
    for (const label of ['Today', 'My Bag', 'Insights', 'Guides', 'Progress', 'Golfer Profile']) {
      expect(main).toContain(label);
    }
    expect(profile).toContain('My Golfer Profile');
    expect(profile).toContain('Connected Golf');
    expect(profile).toContain('Tell GAL Once');
    expect(bag).toContain('How My Bag Works');
    expect(driver).toContain('Target Characteristics');
    expect(driver).toContain('Characteristics Before Brands');

    expect(resolvePortalRoute('/portal/profile')).toBe('profile');
    expect(resolvePortalRoute('/portal/bag')).toBe('bag');
    expect(resolvePortalRoute('/portal/insights')).toBe('insights');
  });

  it('keeps registered and subscriber analytical truth identical while capabilities remain additive', () => {
    const candidates = [{ id: 'keep' }, { id: 'adjust' }, { id: 'replace' }];
    const registeredEntitlements = entitlementsFor('REGISTERED');
    const subscriberEntitlements = entitlementsFor('SUBSCRIBER');

    expect(preserveAnalyticalOrder(candidates, registeredEntitlements)).toEqual(candidates);
    expect(preserveAnalyticalOrder(candidates, subscriberEntitlements)).toEqual(candidates);
    expect(subscriberEntitlements.advancedExplanations).toBe(true);
    expect(registeredEntitlements.advancedExplanations).toBe(false);
  });
});
