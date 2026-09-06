import 'package:cloud_firestore/cloud_firestore.dart';

class CompaniesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch company settings/branding for UI (optional for now).
  static Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}
