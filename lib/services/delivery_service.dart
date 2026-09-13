import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'location_tracking_service.dart';

class DeliveryService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Create a new delivery request
  static Future<String> createDeliveryRequest({
    required String clientId,
    required String pickupLocation,
    required String destination,
    required double weight,
    required String packageType,
    required double price,
    required String paymentMethod,
    double? pickupLat,
    double? pickupLon,
    double? destLat,
    double? destLon,
  }) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('company_id')
          .eq('id', clientId)
          .single();
      final companyId = profile['company_id'] as String?;
      if (companyId == null) {
        throw Exception('Your account is not linked to a company yet.');
      }

      final row = await _client
          .from('deliveries')
          .insert({
            'client_id': clientId,
            'company_id': companyId,
            'pickup_address': pickupLocation,
            'dropoff_address': destination,
            'weight_kg': weight,
            'package_type': packageType,
            'price_naira': price,
            'payment_method': paymentMethod,
            'pickup_lat': pickupLat,
            'pickup_lng': pickupLon,
            'dropoff_lat': destLat,
            'dropoff_lng': destLon,
          })
          .select('id')
          .single();

      final deliveryId = row['id'] as String;

      // Send notification to nearest rider
      await _notifyRidersOfNewDelivery(deliveryId, pickupLocation, destination);

      return deliveryId;
    } catch (e) {
      print('Error creating delivery request: $e');
      rethrow;
    }
  }

  // Find and notify nearest rider about new delivery request.
  //
  // NOTE: this is client-side and best-effort (it only reaches riders whose
  // app is open right now, via a LOCAL notification on THIS device — see
  // MIGRATION_PHASE1_DESIGN.md §5). Real push fan-out to other riders'
  // devices requires the backend service (Phase 3 follow-up), which will
  // listen for `deliveries` inserts via a Database Webhook and call FCM
  // directly using ST_DWithin/ST_Distance against profiles.last_geog.
  static Future<void> _notifyRidersOfNewDelivery(
      String deliveryId, String pickup, String destination) async {
    try {
      await NotificationService.showNewDeliveryNotification(
        deliveryId: deliveryId,
        pickupLocation: pickup,
        destination: destination,
      );
    } catch (e) {
      print('Error notifying riders: $e');
    }
  }

  // Accept delivery (rider accepts a delivery request)
  static Future<void> acceptDelivery(String deliveryId, String riderId) async {
    try {
      await _client.from('deliveries').update({
        'rider_id': riderId,
        'status': 'accepted',
        // accepted_at is set server-side by enforce_delivery_transition()
      }).eq('id', deliveryId);

      // Start location tracking for this delivery
      await LocationTrackingService().startTracking(deliveryId);

      // Notify client that delivery was accepted (see NOTE above — local/
      // best-effort until the backend service exists)
      print('Delivery $deliveryId accepted by rider $riderId');
    } catch (e) {
      print('Error accepting delivery: $e');
      rethrow;
    }
  }

  // Get pending deliveries for riders (same-company pool — enforced by RLS)
  static Stream<List<Map<String, dynamic>>> getPendingDeliveries() {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  // Get active deliveries for a rider
  static Stream<List<Map<String, dynamic>>> getActiveDeliveries(
      String riderId) {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .map((rows) => rows.where((r) => r['status'] == 'accepted').toList()
          ..sort((a, b) => (b['accepted_at'] as String? ?? '')
              .compareTo(a['accepted_at'] as String? ?? '')));
  }

  // Get client's deliveries (all statuses)
  static Stream<List<Map<String, dynamic>>> getClientDeliveries(
      String clientId) {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
  }

  // Get completed deliveries for a rider
  static Stream<List<Map<String, dynamic>>> getCompletedDeliveries(
      String riderId) {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .map((rows) => rows.where((r) => r['status'] == 'completed').toList()
          ..sort((a, b) => (b['completed_at'] as String? ?? '')
              .compareTo(a['completed_at'] as String? ?? '')));
  }

  // Watch a single delivery (used while waiting for a rider to accept)
  static Stream<Map<String, dynamic>?> getDelivery(String deliveryId) {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('id', deliveryId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  // Update delivery status
  static Future<void> updateDeliveryStatus(
      String deliveryId, String status) async {
    try {
      await _client
          .from('deliveries')
          .update({'status': status})
          .eq('id', deliveryId);
      // completed_at/cancelled_at/accepted_at are all set server-side by
      // enforce_delivery_transition().
    } catch (e) {
      print('Error updating delivery status: $e');
      rethrow;
    }
  }

  // Cancel a delivery (client-initiated; a reason is required by the DB trigger)
  static Future<void> cancelDelivery(String deliveryId, String reason) async {
    try {
      await _client.from('deliveries').update({
        'status': 'cancelled',
        'cancel_reason': reason,
      }).eq('id', deliveryId);
    } catch (e) {
      print('Error cancelling delivery: $e');
      rethrow;
    }
  }

  // Rider releases an accepted job back to the pending pool
  static Future<void> releaseDelivery(String deliveryId) async {
    try {
      await _client.from('deliveries').update({
        'status': 'pending',
        'rider_id': null,
      }).eq('id', deliveryId);
    } catch (e) {
      print('Error releasing delivery: $e');
      rethrow;
    }
  }

  // Update rider rating after completion.
  // NOTE: this calls a backend-only RPC (service_role) — see
  // apply_rider_rating() in supabase/migrations. It is not directly callable
  // by end users, so this method is a placeholder until the backend service
  // exists to receive the rating and call the RPC itself.
  static Future<void> updateRiderRating(String riderId, double rating) async {
    print(
        'Rating submission for rider $riderId ($rating) — requires the backend service (not yet built) to call apply_rider_rating().');
  }

  // Register rider FCM token
  static Future<void> registerRiderToken(String riderId, String token) async {
    try {
      await _client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', riderId);
    } catch (e) {
      print('Error registering rider token: $e');
      rethrow;
    }
  }

  // Register client FCM token
  static Future<void> registerClientToken(
      String clientId, String token) async {
    try {
      await _client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', clientId);
    } catch (e) {
      print('Error registering client token: $e');
      rethrow;
    }
  }
}
