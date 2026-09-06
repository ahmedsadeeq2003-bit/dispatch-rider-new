import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dispatch_rider_new/screens/welcome_screen.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify key texts exist
      expect(find.text('Senditt'), findsOneWidget);
      expect(find.text('Deliveries Made Simple'), findsOneWidget);
      expect(
          find.text('Fast, safe, and reliable dispatch service for everyone.'),
          findsOneWidget);
    });

    testWidgets('has Login, Sign Up and Rider buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign Up'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Rider'), findsOneWidget);
    });

    testWidgets('Login button navigates to /login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/login': (_) => const Scaffold(body: Text('Login Page')),
          },
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Sign Up button navigates to /register',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/register': (_) => const Scaffold(body: Text('Register Page')),
          },
        ),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Register Page'), findsOneWidget);
    });

    testWidgets('Rider button navigates to /rider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/rider': (_) => const Scaffold(body: Text('Rider Page')),
          },
        ),
      );

      final riderButton = find.widgetWithText(OutlinedButton, 'Rider');
      await tester.ensureVisible(riderButton);
      await tester.pump();
      await tester.tap(riderButton);
      await tester.pumpAndSettle();

      expect(find.text('Rider Page'), findsOneWidget);
    });
  });
}
