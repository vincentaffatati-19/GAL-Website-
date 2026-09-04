import { describe, expect, it } from 'vitest';
import { entitlementsFor, preserveAnalyticalOrder } from '../entitlements/model';

describe('registered/subscriber invariants', () => {
  it('changes capabilities without changing analytical order', () => {
    const candidates = [{ id:'a' },{ id:'b' },{ id:'c' }];
    const registered = preserveAnalyticalOrder(candidates, entitlementsFor('REGISTERED'));
    const subscriber = preserveAnalyticalOrder(candidates, entitlementsFor('SUBSCRIBER'));
    expect(registered.map((x)=>x.id)).toEqual(['a','b','c']);
    expect(subscriber.map((x)=>x.id)).toEqual(['a','b','c']);
    expect(entitlementsFor('SUBSCRIBER').advancedExplanations).toBe(true);
  });
});
