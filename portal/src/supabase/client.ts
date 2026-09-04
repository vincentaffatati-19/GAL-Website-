import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { getPortalConfig } from '../config';

let client: SupabaseClient | undefined;

export function getSupabaseClient(): SupabaseClient {
  if (!client) {
    const { supabaseUrl, supabasePublishableKey } = getPortalConfig();
    client = createClient(supabaseUrl, supabasePublishableKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    });
  }

  return client;
}

export function resetSupabaseClientForTests(): void {
  if (import.meta.env.MODE !== 'test') return;
  client = undefined;
}
