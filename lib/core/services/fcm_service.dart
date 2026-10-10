import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDPxeTQjE-MDRgF8c1TEK7heYiEStvSj_E",
          appId: "1:440288284956:android:3880a92ac2ed082cfc6ad9",
          messagingSenderId: "440288284956",
          projectId: "repairhub-9b688",
        ),
      );
    }
  } catch (_) {}
  debugPrint('[FCM Background Message]: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final NotificationRepository _repository = NotificationRepository();
  bool _isInitialized = false;

  /// Initialize FCM token registration and listener handlers.
  Future<void> initialize(BuildContext? context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyDPxeTQjE-MDRgF8c1TEK7heYiEStvSj_E",
              appId: "1:440288284956:android:3880a92ac2ed082cfc6ad9",
              messagingSenderId: "440288284956",
              projectId: "repairhub-9b688",
            ),
          );
        }
      } catch (_) {
        try {
          await Firebase.initializeApp();
        } catch (_) {}
      }

      // Register top-level background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get device FCM token and send to server DB
      final String? token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM Token]: Obtained FCM Token -> ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        await _repository.sendFcmToken(token);
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          debugPrint('[FCM Token Refresh]: Updated token -> ${newToken.substring(0, newToken.length > 20 ? 20 : newToken.length)}...');
          await _repository.sendFcmToken(newToken);
        }
      });

      // 1. App Terminated / Closed: Check if app was opened by tapping a push notification
      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && context != null && context.mounted) {
        openNotificationsScreen(context);
      }

      // 2. App Background: Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (context != null && context.mounted) {
          openNotificationsScreen(context);
        }
      });

      // 3. App Foreground: Show notification banner with direct View action when message arrives
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (context != null && context.mounted) {
          final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
          final body = message.notification?.body ?? message.data['body'] ?? '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (body.isNotEmpty) Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => openNotificationsScreen(context),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('[FCM Service Error]: ${e.toString()}');
    }
  }

  /// Helper to open notifications screen when user taps on push banner.
  static void openNotificationsScreen(BuildContext context) {
    NotificationsScreen.show(context);
  }
}
