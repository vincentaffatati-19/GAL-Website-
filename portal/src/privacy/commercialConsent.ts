import { getCurrentSession } from '../auth/session';
import { getSupabaseClient } from '../supabase/client';

export type CommercialConsentDecision = 'ACCEPTED' | 'DECLINED' | 'WITHDRAWN';
export interface CommercialConsentState {
  decision: CommercialConsentDecision;
  recordedAt: string;
}

const CONSENT_TYPE = 'COMMERCIAL_AGGREGATE';
const POLICY_VERSION = 'commercial-aggregate-v1';
const SOURCE = 'MY_GAL_PORTAL';

async function getCurrentGalUserId(): Promise<string> {
  const session = await getCurrentSession();
  if (!session) throw new Error('AUTH_REQUIRED');
  const { data, error } = await getSupabaseClient()
    .from('gal_users')
    .select('id')
    .eq('auth_user_id', session.user.id)
    .single();
  if (error || !data?.id) throw new Error(error?.message ?? 'GAL_USER_NOT_FOUND');
  return data.id as string;
}

export async function getCommercialAggregateConsent(): Promise<CommercialConsentState | null> {
  const userId = await getCurrentGalUserId();
  const { data, error } = await getSupabaseClient()
    .from('gal_consent_records')
    .select('status,recorded_at')
    .eq('user_id', userId)
    .eq('consent_type', CONSENT_TYPE)
    .order('recorded_at', { ascending: false })
    .order('id', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) return null;
  return { decision: data.status as CommercialConsentDecision, recordedAt: data.recorded_at as string };
}

export async function recordCommercialAggregateConsent(decision: CommercialConsentDecision): Promise<void> {
  const userId = await getCurrentGalUserId();
  const { error } = await getSupabaseClient().from('gal_consent_records').insert({
    user_id: userId,
    consent_type: CONSENT_TYPE,
    status: decision,
    policy_version: POLICY_VERSION,
    source: SOURCE,
  });
  if (error) throw new Error(error.message);
}
