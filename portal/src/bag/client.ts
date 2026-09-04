import { getCurrentSession } from '../auth/session';
import { fetchAiFitEquipment } from '../equipment/client';
import { getSupabaseClient } from '../supabase/client';
import { projectBagItems, type BagEquipmentView, type BagItemRow } from './model';

export async function fetchMyBag(): Promise<BagEquipmentView[]> {
  const session = await getCurrentSession();
  if (!session) throw new Error('AUTH_REQUIRED');
  const supabase = getSupabaseClient();
  const { data: user, error: userError } = await supabase
    .from('gal_users')
    .select('id')
    .eq('auth_user_id', session.user.id)
    .single();
  if (userError || !user?.id) throw new Error(userError?.message ?? 'GAL_USER_NOT_FOUND');

  const { data: bag, error: bagError } = await supabase
    .from('gal_bags')
    .select('id')
    .eq('user_id', user.id)
    .eq('is_active', true)
    .limit(1)
    .maybeSingle();
  if (bagError) throw new Error(bagError.message);
  if (!bag) return [];

  const { data: rows, error: itemError } = await supabase
    .from('gal_bag_items')
    .select('id,bag_item_id,category,slot_label,display_snapshot,equipment_configuration_id')
    .eq('bag_id', bag.id)
    .order('created_at', { ascending: true });
  if (itemError) throw new Error(itemError.message);

  let aiFit = [];
  try { aiFit = await fetchAiFitEquipment(); } catch { aiFit = []; }
  return projectBagItems((rows ?? []) as BagItemRow[], aiFit);
}
