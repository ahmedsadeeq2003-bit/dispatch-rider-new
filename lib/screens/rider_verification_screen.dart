import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

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
      appBar: AppBar(
        title: const Text('Rider Verification'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide the following information for verification:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // NIN
            TextField(
              controller: _ninController,
              decoration: InputDecoration(
                labelText: 'National Identification Number (NIN)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Address
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Proof of Address
            TextField(
              controller: _proofOfAddressController,
              decoration: InputDecoration(
                labelText: 'Proof of Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Next of Kin
            TextField(
              controller: _nextOfKinController,
              decoration: InputDecoration(
                labelText: 'Next of Kin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Next of Kin Phone
            TextField(
              controller: _nextOfKinPhoneController,
              decoration: InputDecoration(
                labelText: 'Next of Kin Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Next of Kin Relationship
            TextField(
              controller: _nextOfKinRelationshipController,
              decoration: InputDecoration(
                labelText: 'Next of Kin Relationship',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Document Upload
            const Text(
              'Upload Document (Driver\'s License or Voter\'s Card):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickDocumentImage,
              icon: const Icon(Icons.upload),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            if (_documentImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child:
                    Text('Selected: ${_documentImage!.path.split('/').last}'),
              ),
            const SizedBox(height: 30),

            // Submit Button
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Verification',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
