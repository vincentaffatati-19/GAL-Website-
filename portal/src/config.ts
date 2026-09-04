export type PortalConfig = {
  supabaseUrl: string;
  supabasePublishableKey: string;
};

export function getPortalConfig(): PortalConfig {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL?.trim();
  const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.trim();

  if (!supabaseUrl || !supabasePublishableKey) {
    throw new Error('Portal Supabase configuration is incomplete');
  }

  return { supabaseUrl, supabasePublishableKey };
}
