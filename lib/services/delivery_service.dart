import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // Find and notify nearest rider about new delivery request
  static Future<void> _notifyRidersOfNewDelivery(
      String deliveryId,
      String pickup,
      String destination,
      double? pickupLat,
      double? pickupLon) async {
    try {
      if (pickupLat == null || pickupLon == null) {
        // Fallback to notifying all riders if no location data
        await _notifyAllRiders(deliveryId, pickup, destination);
        return;
      }

      // Get all riders with location data
      QuerySnapshot ridersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('latitude', isNotEqualTo: null)
          .where('longitude', isNotEqualTo: null)
          .get();

      if (ridersSnapshot.docs.isEmpty) {
        // No riders with location data, fallback to all riders
        await _notifyAllRiders(deliveryId, pickup, destination);
        return;
      }

      // Find nearest rider
      String? nearestRiderId;
      double minDistance = double.infinity;

      for (var doc in ridersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final riderLat = data['latitude'] as double?;
        final riderLon = data['longitude'] as double?;

        if (riderLat != null && riderLon != null) {
          final distance =
              _calculateDistance(pickupLat, pickupLon, riderLat, riderLon);
          if (distance < minDistance) {
            minDistance = distance;
            nearestRiderId = doc.id;
          }
        }
      }

      if (nearestRiderId != null) {
        // Get FCM token for nearest rider
        DocumentSnapshot riderDoc =
            await _firestore.collection('riders').doc(nearestRiderId).get();
        String? token = riderDoc.exists ? riderDoc['fcmToken'] : null;

        if (token != null && token.isNotEmpty) {
          await _sendNotificationToRiders(
              [token], deliveryId, pickup, destination);
        } else {
          // No FCM token, fallback to all riders
          await _notifyAllRiders(deliveryId, pickup, destination);
        }
      } else {
        // No nearest rider found, fallback to all riders
        await _notifyAllRiders(deliveryId, pickup, destination);
      }
    } catch (e) {
      print('Error notifying nearest rider: $e');
      // Fallback to all riders on error
      await _notifyAllRiders(deliveryId, pickup, destination);
    }
  }

  // Fallback: Notify all riders about new delivery request
  static Future<void> _notifyAllRiders(
      String deliveryId, String pickup, String destination) async {
    try {
      // Get all rider FCM tokens
      QuerySnapshot ridersSnapshot =
          await _firestore.collection('riders').get();

      List<String> riderTokens = [];
      for (var doc in ridersSnapshot.docs) {
        String? token = doc.data() as String?;
        if (token != null && token.isNotEmpty) {
          riderTokens.add(token);
        }
      }

      // Send push notification to all riders
      if (riderTokens.isNotEmpty) {
        await _sendNotificationToRiders(
            riderTokens, deliveryId, pickup, destination);
      }
    } catch (e) {
      print('Error notifying all riders: $e');
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

      // Get client FCM token
      DocumentSnapshot clientDoc =
          await _firestore.collection('clients').doc(clientId).get();
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
  static Stream<QuerySnapshot> getActiveDeliveries(String riderId) {
    return _firestore
        .collection('deliveries')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('acceptedAt', descending: true)
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

  // Register rider FCM token
  static Future<void> registerRiderToken(String riderId, String token) async {
    try {
      await _firestore.collection('riders').doc(riderId).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error registering rider token: $e');
      throw e;
    }
  }

  // Register client FCM token
  static Future<void> registerClientToken(String clientId, String token) async {
    try {
      await _firestore.collection('clients').doc(clientId).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error registering client token: $e');
      throw e;
    }
  }
}
