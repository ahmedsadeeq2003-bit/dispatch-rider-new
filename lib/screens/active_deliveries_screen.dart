import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/delivery_service.dart';
import 'track_order_screen.dart';
import 'package:latlong2/latlong.dart';

class ActiveDeliveriesScreen extends StatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  State<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends State<ActiveDeliveriesScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Active Deliveries"),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text("Please log in to view active deliveries"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Deliveries"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DeliveryService.getActiveDeliveries(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final deliveries = snapshot.data?.docs ?? [];

          if (deliveries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No active deliveries",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your active deliveries will appear here",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index].data() as Map<String, dynamic>;
              final deliveryId = deliveries[index].id;

              return _buildDeliveryCard(delivery, deliveryId);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery, String deliveryId) {
    final pickupLocation =
        delivery['pickupLocation'] as String? ?? 'Unknown pickup';
    final destination =
        delivery['destination'] as String? ?? 'Unknown destination';
    final status = delivery['status'] as String? ?? 'accepted';
    final price = delivery['price'] as double? ?? 0.0;
    final weight = delivery['weight'] as double? ?? 0.0;
    final packageType = delivery['packageType'] as String? ?? 'Package';

    // Extract coordinates for tracking
    final pickupLat = delivery['pickupLat'] as double?;
    final pickupLon = delivery['pickupLon'] as double?;
    final destLat = delivery['destLat'] as double?;
    final destLon = delivery['destLon'] as double?;

    LatLng? pickupCoords;
    LatLng? destCoords;

    if (pickupLat != null && pickupLon != null) {
      pickupCoords = LatLng(pickupLat, pickupLon);
    }
    if (destLat != null && destLon != null) {
      destCoords = LatLng(destLat, destLon);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₦${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Package details
            Row(
              children: [
                const Icon(Icons.inventory, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '$packageType • ${weight.toStringAsFixed(1)}kg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Pickup location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'From: $pickupLocation',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To: $destination',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackOrderScreen(
                            orderId: deliveryId,
                            pickup: pickupCoords,
                            destination: destCoords,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Track Live'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAsCompleted(deliveryId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Complete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_transit':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _markAsCompleted(String deliveryId) async {
    try {
      await DeliveryService.updateDeliveryStatus(deliveryId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing delivery: $e')),
        );
      }
    }
  }
}
