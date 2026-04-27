import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Register user (client)
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      // Check if email is already registered (either as client or rider)
      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        String errorMessage = 'This email is already registered in the system. '
            'Each email can only be used for one account type (client or rider).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return errorMessage;
      }

      // Create user with email & password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Get the user's UID
      String uid = userCredential.user!.uid;

      // Save user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Redirect to Client Dashboard (Dispatch)
      Navigator.pushReplacementNamed(context, '/dispatch');

      return null; // success
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Error: ${e.message}')),
      );
      return e.message;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
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
      // Check if email is already registered (either as client or rider)
      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        String errorMessage = 'This email is already registered in the system. '
            'Each email can only be used for one account type (client or rider).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return errorMessage;
      }

      // Get current location for rider
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location services are disabled. Please enable them to register as a rider.')),
          );
          return 'Location services disabled';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Location permissions are denied. Please allow location access to register as a rider.')),
            );
            return 'Location permissions denied';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permissions are permanently denied. Please enable them in settings to register as a rider.')),
          );
          return 'Location permissions permanently denied';
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
        return 'Location error: $e';
      }

      // Create user with email & password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Get the user's UID
      String uid = userCredential.user!.uid;

      // Save user details to Firestore with location
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'rider',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Redirect to Rider Verification
      Navigator.pushReplacementNamed(context, '/rider-verification');

      return null; // success
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Error: ${e.message}')),
      );
      return e.message;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Fetch user role from Firestore
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Check if user document exists
      if (!userDoc.exists) {
        // Create user document if it doesn't exist (for existing users)
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': email.split('@')[0], // Use email prefix as name
          'email': email,
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacementNamed(context, '/dispatch');
        return null;
      }

      String role = userDoc['role'] ?? 'client';

      // ✅ Redirect based on role
      if (role == 'rider') {
        Navigator.pushReplacementNamed(context, '/rider');
      } else {
        Navigator.pushReplacementNamed(context, '/dispatch');
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login Error: ${e.message}')));
      return e.message;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Fetch user role from Firestore
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Check if user document exists
      if (!userDoc.exists) {
        // Create user document if it doesn't exist (for existing users)
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': email.split('@')[0], // Use email prefix as name
          'email': email,
          'role': 'rider',
          'createdAt': FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacementNamed(context, '/rider');
        return null;
      }

      String role = userDoc['role'] ?? 'rider';

      // ✅ Redirect to Rider Dashboard if role is rider
      if (role == 'rider') {
        Navigator.pushReplacementNamed(context, '/rider');
      } else {
        return 'Access denied: Not a rider account.';
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login Error: ${e.message}')));
      return e.message;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected Error: $e')));
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
      String uid = _auth.currentUser!.uid;

      // Upload document image to Firebase Storage (simplified - in production, use Firebase Storage)
      // For now, we'll just store the file path or base64, but ideally upload to cloud storage

      // Update user document with verification details
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verification': {
          'nin': nin,
          'address': address,
          'proofOfAddress': proofOfAddress,
          'fullName': fullName,
          'nextOfKin': nextOfKin,
          'nextOfKinPhone': nextOfKinPhone,
          'nextOfKinRelationship': nextOfKinRelationship,
          'documentPath': documentImage
              .path, // In production, upload to Firebase Storage and store URL
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'pending', // pending, approved, rejected
        },
      });

      return null; // success
    } catch (e) {
      return 'Verification submission failed: $e';
    }
  }

  // 🔹 Logout user
  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
