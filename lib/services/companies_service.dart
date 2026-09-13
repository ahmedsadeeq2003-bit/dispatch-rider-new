import 'package:supabase_flutter/supabase_flutter.dart';

class CompaniesService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Fetch company settings/branding for UI (optional for now).
  static Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    return await _client
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();
  }
}
