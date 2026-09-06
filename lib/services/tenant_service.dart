import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Minimal tenant context provider.
///
/// Assumption for this repo:
/// - `users/{uid}` contains `companyId`.
/// - `deliveries/{deliveryId}` contains `companyId`.
class TenantService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the currently signed-in user's companyId.
  static Future<String?> getCurrentCompanyId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;
    return data['companyId'] as String?;
  }

  /// Returns the currently signed-in user's companyId (cached once per call site).
  ///
  /// Note: keep this simple; a more advanced approach would cache in memory.
  static Future<String> requireCurrentCompanyId() async {
    final companyId = await getCurrentCompanyId();
    if (companyId == null || companyId.trim().isEmpty) {
      throw StateError('Missing companyId for the current user.');
    }
    return companyId;
  }
}
