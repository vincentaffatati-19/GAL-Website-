import { getCurrentSession } from '../auth/session';
import { getSupabaseClient } from '../supabase/client';
import { EquipmentClientError } from './errors';
import { normalizeAiFitRows, normalizeGuideRows, type RpcRow } from './normalize';
import type { AiFitEquipmentRead, GuideEquipmentRead } from './types';

export async function fetchGuideEquipment(): Promise<GuideEquipmentRead[]> {
  const { data, error } = await getSupabaseClient().rpc('gal_public_equipment_guide');
  if (error) throw new EquipmentClientError('GUIDE_RPC_FAILED', error.message);
  return normalizeGuideRows((data ?? []) as RpcRow[]);
}

export async function fetchAiFitEquipment(): Promise<AiFitEquipmentRead[]> {
  const session = await getCurrentSession();
  if (!session) {
    throw new EquipmentClientError('AUTH_REQUIRED', 'Authenticated fitting requires a signed-in golfer');
  }

  const { data, error } = await getSupabaseClient().rpc('gal_authenticated_equipment_ai_fit');
  if (error) throw new EquipmentClientError('AI_FIT_RPC_FAILED', error.message);
  return normalizeAiFitRows((data ?? []) as RpcRow[]);
}
