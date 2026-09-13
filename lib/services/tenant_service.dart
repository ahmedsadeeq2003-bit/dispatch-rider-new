import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal tenant context provider.
///
/// Assumption for this repo:
/// - `profiles.id` (== auth uid) has `company_id`.
/// - `deliveries.company_id` scopes tenant isolation (enforced by RLS).
class TenantService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Returns the currently signed-in user's companyId.
  static Future<String?> getCurrentCompanyId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final profile = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', uid)
        .maybeSingle();

    return profile?['company_id'] as String?;
  }

  /// Returns the currently signed-in user's companyId, throwing if unset.
  static Future<String> requireCurrentCompanyId() async {
    final companyId = await getCurrentCompanyId();
    if (companyId == null || companyId.trim().isEmpty) {
      throw StateError('Missing companyId for the current user.');
    }
    return companyId;
  }
}
