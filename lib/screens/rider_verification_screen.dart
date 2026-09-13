import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_textfield.dart';

class RiderVerificationScreen extends StatefulWidget {
  const RiderVerificationScreen({super.key});

  @override
  State<RiderVerificationScreen> createState() =>
      _RiderVerificationScreenState();
}

class _RiderVerificationScreenState extends State<RiderVerificationScreen> {
  final _authService = AuthService();
  final _ninController = TextEditingController();
  final _addressController = TextEditingController();
  final _proofOfAddressController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nextOfKinController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();
  final _nextOfKinRelationshipController = TextEditingController();
  File? _documentImage;
  bool _loading = false;

  Future<void> _pickDocumentImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _documentImage = File(pickedFile.path);
      });
    }
  }

  void _submitVerification() async {
    // For now, allow submission without image for testing
    // In production, require image

    setState(() => _loading = true);
    final error = await _authService.submitRiderVerification(
      nin: _ninController.text.trim(),
      address: _addressController.text.trim(),
      proofOfAddress: _proofOfAddressController.text.trim(),
      fullName: _fullNameController.text.trim(),
      nextOfKin: _nextOfKinController.text.trim(),
      nextOfKinPhone: _nextOfKinPhoneController.text.trim(),
      nextOfKinRelationship: _nextOfKinRelationshipController.text.trim(),
      documentImage: _documentImage ?? File(''), // Placeholder
      context: context,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/rider-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rider Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide the following information for verification:',
              style: AppText.h3,
            ),
            const SizedBox(height: AppSpacing.lg),

            CustomTextField(
              controller: _ninController,
              label: 'National Identification Number (NIN)',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _proofOfAddressController,
              label: 'Proof of Address',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _nextOfKinController,
              label: 'Next of Kin',
              icon: Icons.people_outline,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _nextOfKinPhoneController,
              label: 'Next of Kin Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _nextOfKinRelationshipController,
              label: 'Next of Kin Relationship',
              icon: Icons.diversity_3_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              "Upload Document (Driver's License or Voter's Card):",
              style: AppText.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickDocumentImage,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Select Image'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            if (_documentImage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Selected: ${_documentImage!.path.split('/').last}',
                  style: AppText.bodyMuted,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitVerification,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
