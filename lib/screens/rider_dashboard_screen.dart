import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_tile.dart';

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
    User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // User not logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  void _registerFCMToken() async {
    try {
      User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        String? token = await NotificationService.getFCMToken();
        if (token != null) {
          await DeliveryService.registerRiderToken(user.id, token);
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
      if (snapshot.isNotEmpty) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rider Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Let's get you a job! 🏍️", style: AppText.h1),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Manage deliveries and your rider profile',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
                children: [
                  ActionTile(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending Deliveries',
                    color: AppColors.accentYellow,
                    onTap: () {
                      Navigator.pushNamed(context, '/pending-deliveries');
                    },
                  ),
                  ActionTile(
                    icon: Icons.delivery_dining_rounded,
                    label: 'Active Deliveries',
                    color: AppColors.accentBlue,
                    onTap: () {
                      Navigator.pushNamed(context, '/activedeliveries');
                    },
                  ),
                  ActionTile(
                    icon: Icons.check_circle_rounded,
                    label: 'Completed Deliveries',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pushNamed(context, '/completed-deliveries');
                    },
                  ),
                  ActionTile(
                    icon: Icons.person_rounded,
                    label: 'Rider Details',
                    color: AppColors.accentPurple,
                    onTap: () {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        Navigator.pushNamed(context, '/riderdetails',
                            arguments: {
                              'riderName':
                                  user.userMetadata?['full_name'] ?? 'Rider',
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
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to dispatch order screen to add new delivery
          Navigator.pushNamed(context, '/dispatch');
        },
        backgroundColor: AppColors.secondary,
        tooltip: 'Add New Delivery',
        child: const Icon(Icons.add),
      ),
    );
  }
}
