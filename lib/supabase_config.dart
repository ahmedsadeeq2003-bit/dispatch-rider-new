/// Supabase project connection details.
///
/// The publishable key is safe to ship in the client — it is the equivalent
/// of Firebase's client `apiKey` and is designed to be public. Row Level
/// Security (see supabase/migrations/) is what actually protects data, not
/// secrecy of this key.
///
/// Project: dispatch-rider (bvztrnekmjaulwsjymcc), region eu-west-2.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://bvztrnekmjaulwsjymcc.supabase.co';
  static const String publishableKey =
      'sb_publishable_S1BLCHQoCkUvgjA51Mobgg_ItG6-1sn';
}
