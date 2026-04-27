import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/delivery_service.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _registerFCMToken();
    _checkForPendingDeliveries();
  }

  void _checkAuthentication() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  void _registerFCMToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await NotificationService.getFCMToken();
        if (token != null) {
          await DeliveryService.registerRiderToken(user.uid, token);
        }
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  void _checkForPendingDeliveries() async {
    try {
      // Check if there are pending deliveries and show notification
      // This is a simplified check - in production, you'd want to track which deliveries the rider has already seen
      final snapshot = await DeliveryService.getPendingDeliveries().first;
      if (snapshot.docs.isNotEmpty) {
        // Show a notification that there are pending deliveries
        await NotificationService.showNewDeliveryNotification(
          deliveryId: 'pending_check',
          pickupLocation: 'Multiple locations',
          destination: 'Various destinations',
        );
      }
    } catch (e) {
      print('Error checking pending deliveries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(
              context,
              icon: Icons.pending,
              title: 'Pending Deliveries',
              color: Colors.orange,
              onTap: () {
                // Navigate to pending deliveries screen
                Navigator.pushNamed(context, '/pending-deliveries');
              },
            ),
            _buildTile(
              context,
              icon: Icons.delivery_dining,
              title: 'Active Deliveries',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/activedeliveries');
              },
            ),
            _buildTile(
              context,
              icon: Icons.check_circle,
              title: 'Completed Deliveries',
              color: Colors.green,
              onTap: () {
                // Navigate to completed deliveries screen
                Navigator.pushNamed(context, '/completed-deliveries');
              },
            ),
            _buildTile(
              context,
              icon: Icons.person,
              title: 'Rider Details',
              color: Colors.purple,
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.pushNamed(context, '/riderdetails', arguments: {
                    'riderName': user.displayName ?? 'Rider',
                    'riderRating': 4.9,
                    'riderBike': 'Motorbike • KAV 2019',
                    'eta': 'N/A',
                    'pickup': 'N/A',
                    'destination': 'N/A',
                    'package': 'N/A',
                    'price': 0.0,
                    'weight': 0.0,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to view rider details'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to dispatch order screen to add new delivery
          Navigator.pushNamed(context, '/dispatch');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        tooltip: 'Add New Delivery',
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
