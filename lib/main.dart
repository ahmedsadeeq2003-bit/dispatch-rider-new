import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/track_order_screen.dart';
import 'screens/active_deliveries_screen.dart';
import 'screens/dispatch_order_screen.dart';
import 'screens/confirm_delivery_screen.dart';
import 'screens/rider_details_screen.dart';
import 'screens/rider_dashboard_screen.dart';
import 'screens/pending_deliveries_screen.dart';
import 'screens/completed_deliveries_screen.dart';
import 'screens/rider_auth_screen.dart';
import 'screens/rider_login_screen.dart';
import 'screens/rider_register_screen.dart';
import 'screens/rider_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService.initialize();

  runApp(const DispatchRiderApp());
}

class DispatchRiderApp extends StatelessWidget {
  const DispatchRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dispatch Rider App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/trackorder': (context) => TrackOrderScreen(),
        '/activedeliveries': (context) => ActiveDeliveriesScreen(),
        '/dispatch': (context) => DispatchOrderScreen(),
        '/confirmdelivery': (context) => ConfirmDeliveryScreen(),
        '/riderdetails': (context) => RiderDetailsScreen(),
        '/rider': (context) => RiderAuthScreen(),
        '/rider-verification': (context) => RiderVerificationScreen(),
        '/rider-dashboard': (context) => RiderDashboardScreen(),
        '/rider-login': (context) => RiderLoginScreen(),
        '/rider-register': (context) => RiderRegisterScreen(),
        '/pending-deliveries': (context) => PendingDeliveriesScreen(),
        '/completed-deliveries': (context) => CompletedDeliveriesScreen(),
      },
    );
  }
}
