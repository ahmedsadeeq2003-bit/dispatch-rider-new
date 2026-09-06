import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/delivery_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/delivery_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = false;
  String? _riderId;

  @override
  void initState() {
    super.initState();
    _riderId = FirebaseAuth.instance.currentUser?.uid;
    _loadOnlineStatus();
    _checkAuthentication();
    _registerFCMToken();
    _checkForPendingDeliveries();
  }

  Future<void> _loadOnlineStatus() async {
    if (_riderId == null) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_riderId!)
        .get();
    if (doc.exists) {
      setState(() {
        _isOnline = doc['isOnline'] ?? false;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_riderId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_riderId!)
          .update({
        'isOnline': !_isOnline,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isOnline = !_isOnline;
      });
    } catch (e) {
      print('Error toggling status: $e');
    }
  }

  @override
  void dispose() {
    // Auto set offline
    if (_riderId != null && _isOnline) {
      FirebaseFirestore.instance.collection('users').doc(_riderId!).update({
        'isOnline': false,
      });
    }
    super.dispose();
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
          await DeliveryService.registerToken(user.uid, token);
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().signOut(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Rider Dashboard'),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(_isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'contact_us':
                  Navigator.pushNamed(context, '/contact-us');
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                  break;
                case 'logout':
                  _showLogoutDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.deepPurple),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'contact_us',
                child: Row(
                  children: [
                    Icon(Icons.support_agent, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Contact Us'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleOnlineStatus,
        backgroundColor: _isOnline ? Colors.red : Colors.green,
        icon: Icon(_isOnline ? Icons.power_off : Icons.power),
        label: Text(_isOnline ? 'Go Offline' : 'Go Online'),
        tooltip: 'Toggle Online Status',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05)
              ],
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
