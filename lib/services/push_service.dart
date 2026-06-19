import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../screens/shared/chat_screen.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'reply_action' && notificationResponse.input != null) {
    try {
      await dotenv.load(fileName: ".env");
      await SupabaseService.initialize();
      
      final String inputMessage = notificationResponse.input!;
      final conversationId = notificationResponse.payload;
      
      if (conversationId != null && conversationId.isNotEmpty) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('messages').insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': inputMessage,
          });
        }
      }
    } catch (e) {
      debugPrint('Background reply error: $e');
    }
  }
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
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

        if (message.notification != null || message.data.containsKey('title') || message.data.containsKey('body')) {
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
    final title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    StyleInformation? styleInfo;
    if (body != null) {
      final lines = body.split('\n').map((line) {
        if (line.startsWith('__SYSTEM__:')) return line.replaceFirst('__SYSTEM__:', '');
        if (line.startsWith('You: __SYSTEM__:')) return line.replaceFirst('You: __SYSTEM__:', 'You: ');
        if (line.startsWith('__TASK_CARD__:')) return 'Sent a Task Card';
        if (line.startsWith('You: __TASK_CARD__:')) return 'You: Sent a Task Card';
        if (line.startsWith('__QUOTE__:')) return 'Sent a Custom Quote';
        if (line.startsWith('You: __QUOTE__:')) return 'You: Sent a Custom Quote';
        if (line.startsWith('__COUNTER__:')) return 'Sent a Counter-Offer';
        if (line.startsWith('You: __COUNTER__:')) return 'You: Sent a Counter-Offer';
        if (line == '__REQUEST_LOC__') return 'Requested your Location';
        if (line == 'You: __REQUEST_LOC__') return 'You: Requested your Location';
        return line;
      }).toList();

      body = lines.first; // The first line is the newest message now

      if (lines.length > 1) {
        styleInfo = InboxStyleInformation(
          lines,
          contentTitle: title,
          summaryText: '${lines.length} new messages',
        );
      } else {
        styleInfo = BigTextStyleInformation(body);
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
      icon: '@mipmap/ic_launcher',
      styleInformation: styleInfo,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'reply_action',
          'Reply',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Type a message...',
            ),
          ],
        ),
      ],
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Group notifications by conversation or gig ID so they replace each other
    final String tagId = message.data['conversation_id'] ?? message.data['gig_id'] ?? message.hashCode.toString();

    await _localNotifications.show(
      id: tagId.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: message.data['conversation_id'],
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
