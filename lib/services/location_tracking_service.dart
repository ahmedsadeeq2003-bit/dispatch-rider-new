import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _trackingTimer;
  String? _currentDeliveryId;
  StreamSubscription<Position>? _positionStream;

  // Tracking configuration
  static const Duration _updateInterval = Duration(seconds: 30);
  static final LocationAccuracy _accuracy = LocationAccuracy.high;

  /// Check if location services are enabled and permissions are granted
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start tracking location for a specific delivery
  Future<void> startTracking(String deliveryId) async {
    // Stop any existing tracking
    await stopTracking();

    if (!await _checkPermissions()) {
      throw Exception('Location permissions not granted');
    }

    _currentDeliveryId = deliveryId;

    // Start periodic location updates
    _trackingTimer = Timer.periodic(_updateInterval, (timer) async {
      await _updateLocation();
    });

    // Also start immediate first update
    await _updateLocation();
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _positionStream?.cancel();
    _positionStream = null;
    _currentDeliveryId = null;
  }

  /// Update current location to Firestore
  Future<void> _updateLocation() async {
    if (_currentDeliveryId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      // Store delivery location update
      await _firestore
          .collection('deliveries')
          .doc(_currentDeliveryId!)
          .collection('locationUpdates')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'speed': position.speed,
        'accuracy': position.accuracy,
      });
      // Update rider's current position
      String? riderId = FirebaseAuth.instance.currentUser?.uid;
      if (riderId != null) {
        await _firestore.collection('users').doc(riderId).set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print(
          'Location updated for delivery $_currentDeliveryId: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Get the latest location for a delivery
  Future<Map<String, dynamic>?> getLatestLocation(String deliveryId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .collection('locationUpdates')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting latest location: $e');
    }
    return null;
  }

  /// Stream of location updates for a delivery (for real-time tracking)
  Stream<QuerySnapshot> getLocationUpdates(String deliveryId) {
    return _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .collection('locationUpdates')
        .orderBy('timestamp', descending: true)
        .limit(10) // Keep last 10 updates for efficiency
        .snapshots();
  }

  /// Check if currently tracking a delivery
  bool get isTracking => _currentDeliveryId != null;

  /// Get current delivery being tracked
  String? get currentDeliveryId => _currentDeliveryId;
}
