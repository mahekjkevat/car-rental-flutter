import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // FIX 1: The issue with 'const' was previously resolved.
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Define the vibration pattern as a static final Int64List
  static final Int64List _vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

  static Future<void> initialize() async {
    print('🟡 Initializing Firebase Messaging...');

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔔 Notification permissions: ${settings.authorizationStatus}');

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification tapped: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Configure FCM
    await _configureFCM();

    // Get and save token
    await _getAndSaveToken();

    print('✅ Firebase Messaging initialized successfully');
  }

  static Future<void> _configureFCM() async {
    // Handle background messages (when app is completely closed)
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_firebaseForegroundMessageHandler);

    // Handle when app is in background and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle when app is terminated and opened via notification
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

    // Configure for iOS
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe to topics if needed
    await _firebaseMessaging.subscribeToTopic('admin_chats');
    print('📰 Subscribed to admin_chats topic');
  }

  static Future<void> _createNotificationChannel() async {
    // FIX 3 (Alternative): Use the non-null assertion operator (!) on the static final variable.
    // This tells the analyzer: "I know this is not null, trust me."
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'Notifications for new chat messages',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      vibrationPattern: _vibrationPattern, // This *should* work if the package and analyzer are compatible.
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('📱 Android notification channel created');
  }

  // Background message handler (app closed)
  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
    print('🌙 Background message received: ${message.messageId}');
    await _showNotification(message);
  }

  // Foreground message handler (app open)
  static Future<void> _firebaseForegroundMessageHandler(RemoteMessage message) async {
    print('📱 Foreground message received: ${message.messageId}');
    await _showNotification(message);
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        // FIX 4 (Alternative): Use the non-null assertion operator (!) on the static final variable.
        vibrationPattern: _vibrationPattern, // This *should* work.
        styleInformation: BigTextStyleInformation(
          message.notification?.body ?? '',
          htmlFormatBigText: true,
          contentTitle: message.notification?.title ?? 'New Message',
          htmlFormatContentTitle: true,
        ),
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? 'You have a new message',
        platformChannelSpecifics,
        payload: message.data['roomId'],
      );

      print('✅ Notification shown successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  static void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      print('🚀 App opened from terminated state via notification');
      _navigateToChat(message);
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔄 App opened from background via notification');
    _navigateToChat(message);
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      print('👆 Notification tapped with payload: $payload');
      // Navigate to chat room
    }
  }

  static void _navigateToChat(RemoteMessage message) {
    final String? roomId = message.data['roomId'];
    final String? senderId = message.data['senderId'];

    if (roomId != null) {
      print('📍 Should navigate to chat room: $roomId from sender: $senderId');
      // You'll implement navigation logic here
    }
  }

  static Future<void> _getAndSaveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("🔑 FCM Token: $token");

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('admin_tokens')
            .doc('RPJL3EKxuvWcxa9XDGONvoFGJpl1')
            .set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': 'android',
        }, SetOptions(merge: true));

        print('✅ FCM token saved to database');

        // Also print for debugging
        print('📋 Token saved to: admin_tokens/RPJL3EKxuvWcxa9XDGONvoFGJpl1');
      } else {
        print('❌ Failed to get FCM token');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Delete token when logging out
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await FirebaseFirestore.instance
          .collection('admin_tokens')
          .doc('RPJL3EKxuvWcxa9XDGONvoFGJpl1')
          .delete();
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}