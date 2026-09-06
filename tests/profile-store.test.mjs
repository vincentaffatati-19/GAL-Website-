import test from 'node:test';
import assert from 'node:assert/strict';
import { createProfileStore } from '../portal/profile-store.mjs';

function createMockSupabase({ user = { id: 'auth-a', email: 'a@example.test' }, authError = null } = {}) {
  const calls = [];
  const galUser = { id: 'gal-a', gal_user_id: 'GAL-USR-A', account_status: 'ACTIVE' };
  const profileRows = [{ id: 'fact-1', user_id: 'gal-a', fact_key: 'profile.handedness', fact_value: 'Right', scope: 'global' }];

  function builder(table) {
    const state = { table, op: null, filters: [], payload: null, options: null, select: null, orders: [] };
    const api = {
      select(columns = '*') { state.select = columns; if (!state.op) state.op = 'select'; return api; },
      eq(column, value) { state.filters.push([column, value]); return api; },
      order(column) { state.orders.push(column); return api; },
      upsert(payload, options) { state.op = 'upsert'; state.payload = payload; state.options = options; return api; },
      delete() { state.op = 'delete'; return api; },
      async maybeSingle() {
        calls.push(structuredClone(state));
        if (table !== 'gal_users') throw new Error('unexpected maybeSingle table');
        return { data: galUser, error: null };
      },
      then(resolve, reject) {
        calls.push(structuredClone(state));
        let result;
        if (table === 'gal_profile_facts' && state.op === 'select') result = { data: profileRows, error: null };
        else if (table === 'gal_profile_facts' && state.op === 'upsert') result = { data: state.payload, error: null };
        else if (table === 'gal_profile_facts' && state.op === 'delete') result = { data: [], error: null };
        else result = { data: null, error: new Error(`unhandled ${table}:${state.op}`) };
        return Promise.resolve(result).then(resolve, reject);
      },
    };
    return api;
  }

  return {
    calls,
    auth: {
      async getUser() {
        calls.push({ op: 'auth.getUser' });
        return { data: { user: authError ? null : user }, error: authError };
      }
    },
    from(table) { return builder(table); }
  };
}

test('rejects unauthenticated profile access', async () => {
  const supabase = createMockSupabase({ user: null });
  const store = createProfileStore(supabase);
  await assert.rejects(() => store.getAuthenticatedContext(), /AUTH_REQUIRED/);
});

test('resolves verified auth identity to one active GAL user', async () => {
  const supabase = createMockSupabase();
  const store = createProfileStore(supabase);
  const ctx = await store.getAuthenticatedContext();
  assert.equal(ctx.authUser.id, 'auth-a');
  assert.equal(ctx.galUser.id, 'gal-a');
  const lookup = supabase.calls.find(c => c.table === 'gal_users');
  assert.deepEqual(lookup.filters, [['auth_user_id', 'auth-a'], ['account_status', 'ACTIVE']]);
});

test('loads only the resolved golfer profile facts', async () => {
  const supabase = createMockSupabase();
  const store = createProfileStore(supabase);
  const rows = await store.loadProfileFacts();
  assert.equal(rows[0].user_id, 'gal-a');
  const load = supabase.calls.find(c => c.table === 'gal_profile_facts' && c.op === 'select');
  assert.deepEqual(load.filters, [['user_id', 'gal-a']]);
  assert.deepEqual(load.orders, ['fact_key', 'scope']);
});

test('saveFacts overwrites caller user_id and uses the canonical atomic conflict key', async () => {
  const supabase = createMockSupabase();
  const store = createProfileStore(supabase);
  const saved = await store.saveFacts([{
    user_id: 'gal-b', fact_key: 'game.primary_goal', fact_value: 'Consistency', scope: 'global',
    source: 'USER_REPORTED', source_category: 'SELF_REPORTED', confidence: 1,
    user_confirmed: true, stale_after_days: null, observed_at: '2026-09-06T15:00:00Z', source_reference: null
  }]);
  assert.equal(saved[0].user_id, 'gal-a');
  const upsert = supabase.calls.find(c => c.table === 'gal_profile_facts' && c.op === 'upsert');
  assert.equal(upsert.payload[0].user_id, 'gal-a');
  assert.equal(upsert.options.onConflict, 'user_id,fact_key,scope');
});

test('deleteFacts always includes resolved user ownership plus fact key and scope', async () => {
  const supabase = createMockSupabase();
  const store = createProfileStore(supabase);
  await store.deleteFacts([
    { factKey: 'profile.weight_lb', scope: 'global' },
    { factKey: 'swing.club_speed_mph', scope: 'driver' }
  ]);
  const deletes = supabase.calls.filter(c => c.table === 'gal_profile_facts' && c.op === 'delete');
  assert.equal(deletes.length, 2);
  assert.deepEqual(deletes[0].filters, [
    ['user_id', 'gal-a'], ['fact_key', 'profile.weight_lb'], ['scope', 'global']
  ]);
  assert.deepEqual(deletes[1].filters, [
    ['user_id', 'gal-a'], ['fact_key', 'swing.club_speed_mph'], ['scope', 'driver']
  ]);
});
