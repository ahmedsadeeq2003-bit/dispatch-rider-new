import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // 🔹 Register user (client)
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'client',
          'full_name': name,
        },
      );

      if (!context.mounted) return null;
      // ✅ Redirect to Client Dashboard (Dispatch)
      Navigator.pushReplacementNamed(context, '/dispatch');
      return null; // success
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Error: ${e.message}')),
        );
      }
      return e.message;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
      }
      return e.toString();
    }
  }

  // 🔹 Register rider
  Future<String?> registerRider({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      // Get current location for rider
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Location services are disabled. Please enable them to register as a rider.')),
            );
          }
          return 'Location services disabled';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Location permissions are denied. Please allow location access to register as a rider.')),
              );
            }
            return 'Location permissions denied';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Location permissions are permanently denied. Please enable them in settings to register as a rider.')),
            );
          }
          return 'Location permissions permanently denied';
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting location: $e')),
          );
        }
        return 'Location error: $e';
      }

      final userCredential = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'rider',
          'full_name': name,
        },
      );

      final uid = userCredential.user?.id;
      if (uid != null) {
        // handle_new_user() trigger already created the profile row with
        // role/company_id; fill in the location fields the trigger doesn't set.
        await _client.from('profiles').update({
          'last_lat': position.latitude,
          'last_lng': position.longitude,
          'last_location_at': DateTime.now().toIso8601String(),
        }).eq('id', uid);
      }

      if (!context.mounted) return null;
      // ✅ Redirect to Rider Verification
      Navigator.pushReplacementNamed(context, '/rider-verification');
      return null; // success
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Error: ${e.message}')),
        );
      }
      return e.message;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
      }
      return e.toString();
    }
  }

  // 🔹 Login user (client)
  Future<String?> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);

      final uid = _client.auth.currentUser!.id;
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      if (!context.mounted) return null;

      final role = profile?['role'] as String? ?? 'client';

      // ✅ Redirect based on role
      if (role == 'rider') {
        Navigator.pushReplacementNamed(context, '/rider');
      } else {
        Navigator.pushReplacementNamed(context, '/dispatch');
      }

      return null; // success
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Error: ${e.message}')));
      }
      return e.message;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
      }
      return e.toString();
    }
  }

  // 🔹 Login rider
  Future<String?> loginRider({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);

      final uid = _client.auth.currentUser!.id;
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      if (!context.mounted) return null;

      final role = profile?['role'] as String? ?? 'rider';

      // ✅ Redirect to Rider Dashboard if role is rider
      if (role == 'rider') {
        Navigator.pushReplacementNamed(context, '/rider');
      } else {
        return 'Access denied: Not a rider account.';
      }

      return null; // success
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Error: ${e.message}')));
      }
      return e.message;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
      }
      return e.toString();
    }
  }

  // 🔹 Submit rider verification
  Future<String?> submitRiderVerification({
    required String nin,
    required String address,
    required String proofOfAddress,
    required String fullName,
    required String nextOfKin,
    required String nextOfKinPhone,
    required String nextOfKinRelationship,
    required File documentImage,
    required BuildContext context,
  }) async {
    try {
      final uid = _client.auth.currentUser!.id;

      String? documentUrl;
      if (documentImage.path.isNotEmpty && await documentImage.exists()) {
        final ext = documentImage.path.split('.').last;
        final path =
            '$uid/document-${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _client.storage
            .from('rider-verification')
            .upload(path, documentImage);
        documentUrl = path;
      }

      await _client.from('rider_verifications').upsert({
        'rider_id': uid,
        'nin': nin,
        'address': address,
        'full_name': fullName,
        'proof_of_address': proofOfAddress,
        'next_of_kin': nextOfKin,
        'next_of_kin_phone': nextOfKinPhone,
        'next_of_kin_relationship': nextOfKinRelationship,
        'document_url': documentUrl,
        'status': 'pending',
      });

      return null; // success
    } catch (e) {
      return 'Verification submission failed: $e';
    }
  }

  // 🔹 Logout user
  Future<void> signOut(BuildContext context) async {
    await _client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
