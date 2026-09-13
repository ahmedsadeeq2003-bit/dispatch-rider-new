import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) {
      // Push isn't wired up for web in this project: flutter_local_notifications
      // has no web platform implementation (initialize() would throw
      // MissingPluginException), and Firebase Messaging on web additionally
      // needs a firebase-messaging-sw.js service worker + VAPID key that
      // don't exist here yet. Skip entirely rather than throw and block
      // app startup (this was causing a blank page on `flutter run -d chrome`
      // — main() awaited this with no error handling). See FORENSIC_AUDIT.md.
      debugPrint('NotificationService: skipping init on web (not configured).');
      return;
    }

    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    await _showLocalNotification(message);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message: ${message.messageId}');
    _showLocalNotification(message);
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    // Handle navigation based on message data
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Notifications',
      channelDescription: 'Notifications for new delivery requests',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Delivery Request',
      message.notification?.body ?? 'A new delivery request is available',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Show local notification for new delivery
  static Future<void> showNewDeliveryNotification({
    required String deliveryId,
    required String pickupLocation,
    required String destination,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Notifications',
      channelDescription: 'Notifications for new delivery requests',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      deliveryId.hashCode,
      'New Delivery Request!',
      'Pickup: $pickupLocation\nDestination: $destination',
      details,
    );
  }
}
