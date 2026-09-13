import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin client for the admin-* Supabase Edge Functions
/// (supabase/functions/admin-verifications, admin-companies). Every call
/// carries the signed-in user's session JWT automatically (functions.invoke
/// attaches it); the functions themselves re-check `profiles.role == 'admin'`
/// server-side, so isCurrentUserAdmin() here is only a UI gate, not security.
class AdminService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<bool> isCurrentUserAdmin() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return profile?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> _invoke(
      String function, Map<String, dynamic> body) async {
    try {
      final res = await _client.functions.invoke(function, body: body);
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['error'] != null) {
          throw Exception(map['error'].toString());
        }
        return map;
      }
      return {};
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> listPendingVerifications() async {
    final data = await _invoke(
        'admin-verifications', {'action': 'list', 'status': 'pending'});
    return List<Map<String, dynamic>>.from(data['verifications'] ?? []);
  }

  static Future<void> reviewVerification(String id, String decision) async {
    await _invoke(
        'admin-verifications', {'action': 'review', 'id': id, 'decision': decision});
  }

  static Future<List<Map<String, dynamic>>> listCompanies() async {
    final data = await _invoke('admin-companies', {'action': 'list'});
    return List<Map<String, dynamic>>.from(data['companies'] ?? []);
  }

  static Future<void> createCompany(String code, String name) async {
    await _invoke(
        'admin-companies', {'action': 'create', 'code': code, 'name': name});
  }
}
