function fail(code, cause = null) {
  const error = new Error(code);
  error.code = code;
  if (cause) error.cause = cause;
  return error;
}

export function createProfileStore(supabase) {
  if (!supabase?.auth?.getUser || !supabase?.from) {
    throw fail('SUPABASE_CLIENT_REQUIRED');
  }

  let contextPromise = null;

  async function getAuthenticatedContext({ refresh = false } = {}) {
    if (refresh) contextPromise = null;
    if (!contextPromise) {
      contextPromise = (async () => {
        const { data: authData, error: authError } = await supabase.auth.getUser();
        const authUser = authData?.user;
        if (authError || !authUser?.id) throw fail('AUTH_REQUIRED', authError);

        const { data: galUser, error: galError } = await supabase
          .from('gal_users')
          .select('id,gal_user_id,account_status,preferred_market_code,preferred_units')
          .eq('auth_user_id', authUser.id)
          .eq('account_status', 'ACTIVE')
          .maybeSingle();

        if (galError) throw fail('GAL_USER_LOOKUP_FAILED', galError);
        if (!galUser?.id) throw fail('GAL_USER_NOT_FOUND');
        return { authUser, galUser };
      })().catch((error) => {
        contextPromise = null;
        throw error;
      });
    }
    return contextPromise;
  }

  async function loadProfileFacts() {
    const { galUser } = await getAuthenticatedContext();
    const { data, error } = await supabase
      .from('gal_profile_facts')
      .select('*')
      .eq('user_id', galUser.id)
      .order('fact_key')
      .order('scope');
    if (error) throw fail('PROFILE_LOAD_FAILED', error);
    return data || [];
  }

  async function saveFacts(rows = []) {
    if (!Array.isArray(rows)) throw fail('PROFILE_ROWS_REQUIRED');
    if (!rows.length) return [];
    const { galUser } = await getAuthenticatedContext();
    const ownedRows = rows.map(({ id: _id, created_at: _createdAt, updated_at: _updatedAt, ...row }) => ({
      ...row,
      user_id: galUser.id,
    }));
    const { data, error } = await supabase
      .from('gal_profile_facts')
      .upsert(ownedRows, { onConflict: 'user_id,fact_key,scope' })
      .select('*');
    if (error) throw fail('PROFILE_SAVE_FAILED', error);
    return data || ownedRows;
  }

  async function deleteFacts(keys = []) {
    if (!Array.isArray(keys)) throw fail('PROFILE_KEYS_REQUIRED');
    if (!keys.length) return [];
    const { galUser } = await getAuthenticatedContext();
    for (const key of keys) {
      const factKey = String(key?.factKey || '').trim();
      if (!factKey) continue;
      const scope = key?.scope || 'global';
      const { error } = await supabase
        .from('gal_profile_facts')
        .delete()
        .eq('user_id', galUser.id)
        .eq('fact_key', factKey)
        .eq('scope', scope);
      if (error) throw fail('PROFILE_DELETE_FAILED', error);
    }
    return keys;
  }

  return Object.freeze({
    getAuthenticatedContext,
    loadProfileFacts,
    saveFacts,
    deleteFacts,
  });
}
