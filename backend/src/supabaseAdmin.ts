import { createClient } from '@supabase/supabase-js';
import { config } from './config';

/**
 * Service-role Supabase client. Bypasses RLS entirely — this is the
 * equivalent of the old Firebase Admin SDK key. Never expose this client or
 * its key to the Flutter app or any untrusted caller.
 */
export const supabaseAdmin = createClient(
  config.supabaseUrl,
  config.supabaseServiceRoleKey,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

/**
 * A client configured to verify end-user JWTs. Uses the same project but
 * relies on Supabase Auth's own token verification (auth.getUser), so it
 * doesn't need the project's JWT signing secret managed separately.
 */
export async function getUserFromToken(accessToken: string) {
  const { data, error } = await supabaseAdmin.auth.getUser(accessToken);
  if (error || !data.user) return null;
  return data.user;
}

export async function getProfile(userId: string) {
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('id, role, company_id, full_name, fcm_token')
    .eq('id', userId)
    .maybeSingle();
  if (error) throw error;
  return data;
}
