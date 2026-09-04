import { getCurrentSession } from '../auth/session';
import { getSupabaseClient } from '../supabase/client';
import type { ProfileFactRow } from './types';

async function currentGalUserId(): Promise<string | null> {
  const session = await getCurrentSession();
  if (!session) return null;
  const { data, error } = await getSupabaseClient()
    .from('gal_users')
    .select('id')
    .eq('auth_user_id', session.user.id)
    .single();
  if (error) throw new Error(error.message);
  return data?.id ?? null;
}

export async function fetchProfileFacts(): Promise<ProfileFactRow[]> {
  const userId = await currentGalUserId();
  if (!userId) return [];

  const { data, error } = await getSupabaseClient()
    .from('gal_profile_facts')
    .select('fact_key,fact_value,source,source_category,confidence,user_confirmed,scope,stale_after_days,observed_at,updated_at,source_reference')
    .eq('user_id', userId)
    .order('updated_at', { ascending: false });

  if (error) throw new Error(error.message);
  return (data ?? []) as ProfileFactRow[];
}
