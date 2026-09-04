import { getCurrentSession } from '../auth/session';
import { getSupabaseClient } from '../supabase/client';

export interface ReusedProfileFact {
  key: string;
  value: unknown;
  source: string;
  observedAt: string;
  staleAfterDays: number | null;
}

const DRIVER_FACT_KEYS = ['handedness','driver_club_speed','driver_carry','shot_shape','common_miss'];

export async function fetchDriverReusableProfileFacts(): Promise<ReusedProfileFact[]> {
  const session = await getCurrentSession();
  if (!session) return [];
  const supabase = getSupabaseClient();
  const { data: user, error: userError } = await supabase.from('gal_users').select('id').eq('auth_user_id', session.user.id).single();
  if (userError || !user?.id) return [];
  const { data, error } = await supabase
    .from('gal_profile_facts')
    .select('fact_key,fact_value,source,observed_at,stale_after_days')
    .eq('user_id', user.id)
    .in('fact_key', DRIVER_FACT_KEYS)
    .order('updated_at', { ascending: false });
  if (error) throw new Error(error.message);
  const seen = new Set<string>();
  return (data ?? []).flatMap((row) => {
    if (seen.has(row.fact_key)) return [];
    seen.add(row.fact_key);
    return [{ key: row.fact_key, value: row.fact_value, source: row.source, observedAt: row.observed_at, staleAfterDays: row.stale_after_days }];
  });
}
