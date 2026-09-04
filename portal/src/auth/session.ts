import type { Session } from '@supabase/supabase-js';
import { getSupabaseClient } from '../supabase/client';

export async function getCurrentSession(): Promise<Session | null> {
  const { data, error } = await getSupabaseClient().auth.getSession();
  if (error) throw error;
  return data.session;
}
