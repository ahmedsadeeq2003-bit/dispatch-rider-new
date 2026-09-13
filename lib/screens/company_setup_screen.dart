import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_textfield.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Company Setup')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your logistics company code to join.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.md),
            CustomTextField(
              controller: _companyCodeController,
              label: 'Company code',
              icon: Icons.qr_code_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _joinCompany,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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
