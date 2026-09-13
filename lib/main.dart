import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'supabase_config.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

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
import 'screens/rate_rider_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is kept ONLY for push notifications (FCM) — never let a failure
  // here (e.g. web's known authDomain mismatch, see FORENSIC_AUDIT.md) stop
  // the rest of the app from launching. The app works fully without it;
  // only push notifications would be affected.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase.initializeApp failed (continuing without it): $e\n$st');
  }

  // Supabase is the database/auth/storage backend — required, but a failure
  // here should still show the app (with visible errors in each screen's own
  // error state) rather than leave a permanently blank white page.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (e, st) {
    debugPrint('Supabase.initialize failed: $e\n$st');
  }

  // Push notifications — no-ops on web (see NotificationService.initialize).
  try {
    await NotificationService.initialize();
  } catch (e, st) {
    debugPrint('NotificationService.initialize failed (continuing): $e\n$st');
  }

  runApp(const DispatchRiderApp());
}

class DispatchRiderApp extends StatelessWidget {
  const DispatchRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dispatch Rider App',
      theme: AppTheme.light,
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
        '/rate-rider': (context) => const RateRiderScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
