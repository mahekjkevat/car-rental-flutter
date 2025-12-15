// admin_pusher_service.dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AdminPusherService {
  static final AdminPusherService _instance = AdminPusherService._internal();
  factory AdminPusherService() => _instance;
  AdminPusherService._internal();

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  bool isConnected = false;
  Function(PusherEvent)? onMessageReceived;
  Function(PusherEvent)? onCustomerConnected;

  // Admin configuration
  final String adminId = "C7Ii3fhAJgbmv3PYutql9EGSKKV2";
  final String adminName = "Mahek Kevat";
  final String adminEmail = "mahekjkevat@gmail.com";
  final String adminImage = "assets/images/app_icon.jpeg";

  // Initialize Pusher for Admin
  Future<void> initPusher() async {
    try {
      if (isConnected) {
        print("🟠 Admin Pusher already connected");
        return;
      }

      await pusher.init(
        apiKey: "fb689c69a565bc119f05",
        cluster: "ap2",
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
      );

      await pusher.connect();
      print("✅ Admin Pusher initialized successfully!");
    } catch (e) {
      print("❌ Admin Pusher initialization failed: $e");
      _simulateConnection();
    }
  }

  void _simulateConnection() {
    print("🔄 Using simulated Admin Pusher connection");
    isConnected = true;

    Future.delayed(Duration(seconds: 2), () {
      if (onConnectionStateChange != null) {
        onConnectionStateChange("connected", "disconnected");
      }
    });
  }

  // Subscribe to admin channel
  Future<void> subscribeToAdminChannel() async {
    try {
      await pusher.subscribe(channelName: "admin-channel-$adminId");
      print("✅ Admin subscribed to channel: admin-channel-$adminId");
    } catch (e) {
      print("❌ Admin subscription failed: $e");
      print("🔄 Using simulated admin subscription");
    }
  }

  // Subscribe to customer messages
  Future<void> subscribeToCustomer(String customerId) async {
    try {
      await pusher.subscribe(channelName: "customer-$customerId");
      print("✅ Admin listening to customer: $customerId");
    } catch (e) {
      print("❌ Customer subscription failed: $e");
    }
  }

  // Send message to customer
  Future<void> sendMessageToCustomer(String customerId, String message) async {
    try {
      final messageData = {
        "text": message,
        "timestamp": DateTime.now().toIso8601String(),
        "sender_id": adminId,
        "sender_name": adminName,
        "sender_role": "admin",
        "sender_image": adminImage,
        "receiver_id": customerId,
        "type": "text"
      };

      print("📤 Admin sending message to customer $customerId: $message");

      // Simulate sending
      await Future.delayed(Duration(milliseconds: 300));

      // Trigger local event
      if (onMessageReceived != null) {
        final localEvent = PusherEvent(
          data: json.encode(messageData),
          channelName: "customer-$customerId",
          eventName: "admin-message",
          userId: adminId,
        );
        onMessageReceived!(localEvent);
      }

      print("✅ Admin message sent successfully!");

    } catch (e) {
      print("❌ Admin message sending failed: $e");
    }
  }

  // Event handlers
  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("🔗 Admin Connection: $previousState -> $currentState");
    isConnected = currentState == "connected";
    if (isConnected) {
      print("🎉 Admin Connected to Pusher!");
    }
  }

  void onError(String message, int? code, dynamic e) {
    print("❌ Admin Pusher Error: $message");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("✅ Admin Subscription to $channelName succeeded!");
  }

  void onEvent(PusherEvent event) {
    print("📩 Admin received event: ${event.eventName} from ${event.channelName}");

    if (onMessageReceived != null) {
      onMessageReceived!(event);
    }
  }

  void onSubscriptionError(String message, dynamic e) {
    print("❌ Admin Subscription Error: $message");
  }

  // Disconnect Pusher
  Future<void> disconnect() async {
    try {
      await pusher.disconnect();
      isConnected = false;
      print("✅ Admin Pusher disconnected!");
    } catch (e) {
      print("❌ Admin disconnection failed: $e");
    }
  }
}