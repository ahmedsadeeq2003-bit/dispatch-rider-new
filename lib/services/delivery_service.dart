import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'location_tracking_service.dart';

class DeliveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new delivery request
  static Future<String> createDeliveryRequest({
    required String clientId,
    required String pickupLocation,
    required String destination,
    required double weight,
    required String packageType,
    required double price,
    required String paymentMethod,
    required String companyId,
    double? pickupLat,
    double? pickupLon,
    double? destLat,
    double? destLon,
  }) async {
    try {
      // Create delivery document
      DocumentReference deliveryRef =
          await _firestore.collection('deliveries').add({
        'clientId': clientId,
        'pickupLocation': pickupLocation,
        'destination': destination,
        'weight': weight,
        'packageType': packageType,
        'price': price,
        'pickupLat': pickupLat,
        'pickupLon': pickupLon,
        'destLat': destLat,
        'destLon': destLon,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'riderId': null,
      });

      // Send notification to nearest rider
      await _notifyRidersOfNewDelivery(
          deliveryRef.id, pickupLocation, destination, pickupLat, pickupLon);

      return deliveryRef.id;
    } catch (e) {
      print('Error creating delivery request: $e');
      throw e;
    }
  }

  // Smart notify: online riders within radius, prefer near/high-rated
  static Future<void> _notifyRidersOfNewDelivery(
      String deliveryId,
      String pickup,
      String destination,
      double? pickupLat,
      double? pickupLon) async {
    try {
      if (pickupLat == null || pickupLon == null) {
        await _notifyAllOnlineRiders(deliveryId, pickup, destination);
        return;
      }

      // Get online riders with location
      QuerySnapshot ridersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('isOnline', isEqualTo: true)
          .where('latitude', isNotEqualTo: null)
          .where('longitude', isNotEqualTo: null)
          .get();

      List<Map<String, dynamic>> candidates = [];
      for (var doc in ridersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = data['latitude'] as double?;
        final lon = data['longitude'] as double?;
        final rating = (data['rating'] ?? 5.0) as double;
        if (lat != null && lon != null) {
          final distance = _calculateDistance(pickupLat, pickupLon, lat, lon);
          candidates.add({
            'id': doc.id,
            'distance': distance,
            'rating': rating,
            'fcmToken': data['fcmToken'] ?? '',
          });
        }
      }

      // Filter/sort by radius + score
      List<Map<String, dynamic>> topCandidates = [];
      for (final radius in [10.0, 15.0]) {
        topCandidates =
            candidates.where((c) => c['distance'] <= radius).toList()
              ..sort((a, b) {
                final scoreA = a['rating'] - a['distance'] / 10;
                final scoreB = b['rating'] - b['distance'] / 10;
                return scoreB.compareTo(scoreA); // desc rating, asc distance
              });
        if (topCandidates.length >= 3) break;
      }

      final tokens = topCandidates
          .take(5)
          .where((c) => c['fcmToken'].isNotEmpty)
          .map((c) => c['fcmToken'] as String)
          .toList();
      if (tokens.isNotEmpty) {
        await _sendNotificationToRiders(
            tokens, deliveryId, pickup, destination);
      } else {
        await _notifyAllOnlineRiders(deliveryId, pickup, destination);
      }
    } catch (e) {
      print('Error notifying riders: $e');
      await _notifyAllOnlineRiders(deliveryId, pickup, destination);
    }
  }

  // Fallback: Notify all online riders
  static Future<void> _notifyAllOnlineRiders(
      String deliveryId, String pickup, String destination) async {
    try {
      QuerySnapshot ridersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('isOnline', isEqualTo: true)
          .get();

      List<String> riderTokens = [];
      for (var doc in ridersSnapshot.docs) {
        String? token = doc['fcmToken'];
        if (token != null && token.isNotEmpty) {
          riderTokens.add(token);
        }
      }

      if (riderTokens.isNotEmpty) {
        await _sendNotificationToRiders(
            riderTokens, deliveryId, pickup, destination);
      }
    } catch (e) {
      print('Error notifying all online riders: $e');
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Send FCM notification to riders
  static Future<void> _sendNotificationToRiders(List<String> tokens,
      String deliveryId, String pickup, String destination) async {
    // Note: In a real implementation, you would send this from your backend server
    // For now, we'll show a local notification to simulate the notification
    // In production, use Firebase Cloud Functions or your backend to send FCM messages

    print(
        'Sending notification to ${tokens.length} riders for delivery $deliveryId');

    // Show local notification for demo purposes
    // In production, this would be sent server-side via FCM
    await NotificationService.showNewDeliveryNotification(
      deliveryId: deliveryId,
      pickupLocation: pickup,
      destination: destination,
    );
  }

  // Accept delivery (rider accepts a delivery request)
  static Future<void> acceptDelivery(String deliveryId, String riderId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'riderId': riderId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Start location tracking for this delivery
      await LocationTrackingService().startTracking(deliveryId);

      // Notify client that delivery was accepted
      await _notifyClientDeliveryAccepted(deliveryId);
    } catch (e) {
      print('Error accepting delivery: $e');
      throw e;
    }
  }

  // Notify client that delivery was accepted
  static Future<void> _notifyClientDeliveryAccepted(String deliveryId) async {
    try {
      DocumentSnapshot deliveryDoc =
          await _firestore.collection('deliveries').doc(deliveryId).get();
      String clientId = deliveryDoc['clientId'];

      // Get client FCM token from users collection
      DocumentSnapshot clientDoc =
          await _firestore.collection('users').doc(clientId).get();
      String? clientToken = clientDoc['fcmToken'];

      if (clientToken != null && clientToken.isNotEmpty) {
        // Send notification to client
        await _sendNotificationToClient(clientToken, deliveryId);
      }
    } catch (e) {
      print('Error notifying client: $e');
    }
  }

  // Send notification to client
  static Future<void> _sendNotificationToClient(
      String token, String deliveryId) async {
    // Similar to rider notification, this should be done server-side in production
    print('Sending notification to client for delivery $deliveryId');
  }

  // Get pending deliveries for riders
  static Stream<QuerySnapshot> getPendingDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get active deliveries for a rider
  static Stream<QuerySnapshot> getActiveDeliveries(String uid) {
    return _firestore
        .collection('deliveries')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .orderBy('acceptedAt', descending: true)
        .snapshots();
  }

  // Get client's deliveries (active + completed)
  static Stream<QuerySnapshot> getClientDeliveries(String clientId) {
    return _firestore
        .collection('deliveries')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get completed deliveries for a rider
  static Stream<QuerySnapshot> getCompletedDeliveries(String riderId) {
    return _firestore
        .collection('deliveries')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  // Update delivery status
  static Future<void> updateDeliveryStatus(
      String deliveryId, String status) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
      };

      if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .update(updateData);
    } catch (e) {
      print('Error updating delivery status: $e');
      throw e;
    }
  }

  // Update rider rating after completion
  static Future<void> updateRiderRating(String riderId, double rating) async {
    try {
      await _firestore.collection('users').doc(riderId).update({
        'totalRatings': FieldValue.increment(rating),
        'totalDeliveries': FieldValue.increment(1),
      });
      // Recalc rating via cloud function or client-side avg
    } catch (e) {
      print('Error updating rider rating: $e');
    }
  }

  // Register rider FCM token (updates users/{uid})
  static Future<void> registerToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error registering FCM token: $e');
      throw e;
    }
  }
}
