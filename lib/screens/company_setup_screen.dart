import 'package:flutter/material.dart';

/// Minimal placeholder UI.
///
/// This repo currently does not yet implement invite-code -> companyId provisioning.
/// In the next iteration we will:
/// - validate invite code against Firestore `companies`
/// - update `users/{uid}.companyId`
/// - then tenant-scope all queries.
class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _companyCodeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _companyCodeController.dispose();
    super.dispose();
  }

  void _joinCompany() {
    // TODO: implement invite code lookup + persist companyId to current user's doc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company join not implemented yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your logistics company code to join.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyCodeController,
              decoration: const InputDecoration(
                labelText: 'Company code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _joinCompany,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
