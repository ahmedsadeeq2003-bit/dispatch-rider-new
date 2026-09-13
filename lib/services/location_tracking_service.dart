import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  Timer? _trackingTimer;
  String? _currentDeliveryId;
  StreamSubscription<Position>? _positionStream;

  // Tracking configuration
  static const Duration _updateInterval = Duration(seconds: 30);
  static const LocationAccuracy _accuracy = LocationAccuracy.high;

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

  /// Update current location to Supabase
  Future<void> _updateLocation() async {
    if (_currentDeliveryId == null) return;

    final riderId = _client.auth.currentUser?.id;
    if (riderId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      // Store delivery location update
      await _client.from('delivery_locations').insert({
        'delivery_id': _currentDeliveryId,
        'rider_id': riderId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed, // meters per second
        'accuracy': position.accuracy,
      });

      // Update rider's current position on their profile
      await _client.from('profiles').update({
        'last_lat': position.latitude,
        'last_lng': position.longitude,
        'last_location_at': DateTime.now().toIso8601String(),
      }).eq('id', riderId);

      print(
          'Location updated for delivery $_currentDeliveryId: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Get the latest location for a delivery
  Future<Map<String, dynamic>?> getLatestLocation(String deliveryId) async {
    try {
      final rows = await _client
          .from('delivery_locations')
          .select()
          .eq('delivery_id', deliveryId)
          .order('recorded_at', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        return rows.first;
      }
    } catch (e) {
      print('Error getting latest location: $e');
    }
    return null;
  }

  /// Stream of location updates for a delivery (for real-time tracking)
  Stream<List<Map<String, dynamic>>> getLocationUpdates(String deliveryId) {
    return _client
        .from('delivery_locations')
        .stream(primaryKey: ['id'])
        .eq('delivery_id', deliveryId)
        .order('recorded_at', ascending: false)
        .limit(10); // Keep last 10 updates for efficiency
  }

  /// Check if currently tracking a delivery
  bool get isTracking => _currentDeliveryId != null;

  /// Get current delivery being tracked
  String? get currentDeliveryId => _currentDeliveryId;
}
