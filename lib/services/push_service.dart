import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/shared/chat_screen.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      
      // Request permissions (Required for iOS and Android 13+)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('notification');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(
        settings: initializationSettings,
      );

      // Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ngam_high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Explicitly ask for Android 13+ local notification permission
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      // Handle tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleTap(message);
      });

      // Handle tap when app was completely terminated
      final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMsg != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleTap(initialMsg);
        });
      }
    } catch (e) {
      debugPrint('Firebase not configured: $e');
      // User needs to add google-services.json
    }
  }

  static void _handleTap(RemoteMessage message) {
    if (message.data.containsKey('type')) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        // For chat messages or updates, route to the unified Chat/Messages list
        // where users can see their active conversations and gig chats
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    StyleInformation? styleInfo;
    if (message.notification?.body != null) {
      final lines = message.notification!.body!.split('\n');
      if (lines.length > 1) {
        styleInfo = InboxStyleInformation(
          lines,
          contentTitle: message.notification!.title,
          summaryText: '${lines.length} new messages',
        );
      } else {
        styleInfo = BigTextStyleInformation(message.notification!.body!);
      }
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ngam_high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: 'notification',
      styleInformation: styleInfo,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Group notifications by conversation or gig ID so they replace each other
    final String tagId = message.data['conversation_id'] ?? message.data['gig_id'] ?? message.hashCode.toString();

    await _localNotifications.show(
      id: tagId.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveTokenToSupabase(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        await SupabaseService.updateProfile(userId: userId, fcmToken: token);
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}
