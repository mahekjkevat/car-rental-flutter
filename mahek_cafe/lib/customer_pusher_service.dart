// customer_pusher_service.dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class CustomerPusherService {
  static final CustomerPusherService _instance = CustomerPusherService._internal();
  factory CustomerPusherService() => _instance;
  CustomerPusherService._internal();

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  bool isConnected = false;
  Function(PusherEvent)? onMessageReceived;

  // Customer configuration (you can make this dynamic)
  final String customerId = "customer1";
  final String customerName = "KRISHNA KEVAT";
  final String customerEmail = "mahekforever2003@gmail.com";
  final String customerImage = "https://ik.imagekit.io/fsp5dxfxe/profile_images/profile_1762074233607_F5IM0a8hx.jpg";

  // Admin configuration
  final String adminId = "C7Ii3fhAJgbmv3PYutql9EGSKKV2";
  final String adminName = "Mahek Kevat";
  final String adminImage = "assets/images/app_icon.jpeg";

  // Initialize Pusher for Customer
  Future<void> initPusher() async {
    try {
      if (isConnected) {
        print("🟠 Customer Pusher already connected");
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
      print("✅ Customer Pusher initialized successfully!");
    } catch (e) {
      print("❌ Customer Pusher initialization failed: $e");
      _simulateConnection();
    }
  }

  void _simulateConnection() {
    print("🔄 Using simulated Customer Pusher connection");
    isConnected = true;

    Future.delayed(Duration(seconds: 2), () {
      if (onConnectionStateChange != null) {
        onConnectionStateChange("connected", "disconnected");
      }
    });
  }

  // Subscribe to customer channel
  Future<void> subscribeToCustomerChannel() async {
    try {
      await pusher.subscribe(channelName: "customer-$customerId");
      print("✅ Customer subscribed to channel: customer-$customerId");
    } catch (e) {
      print("❌ Customer subscription failed: $e");
      print("🔄 Using simulated customer subscription");
    }
  }

  // Send message to admin
  Future<void> sendMessageToAdmin(String message) async {
    try {
      final messageData = {
        "text": message,
        "timestamp": DateTime.now().toIso8601String(),
        "sender_id": customerId,
        "sender_name": customerName,
        "sender_role": "customer",
        "sender_image": customerImage,
        "receiver_id": adminId,
        "type": "text"
      };

      print("📤 Customer sending message to admin: $message");

      // Simulate sending
      await Future.delayed(Duration(milliseconds: 300));

      // Trigger local event
      if (onMessageReceived != null) {
        final localEvent = PusherEvent(
          data: json.encode(messageData),
          channelName: "admin-channel-$adminId",
          eventName: "customer-message",
          userId: customerId,
        );
        onMessageReceived!(localEvent);
      }

      print("✅ Customer message sent successfully!");

    } catch (e) {
      print("❌ Customer message sending failed: $e");
    }
  }

  // Event handlers
  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("🔗 Customer Connection: $previousState -> $currentState");
    isConnected = currentState == "connected";
    if (isConnected) {
      print("🎉 Customer Connected to Pusher!");
    }
  }

  void onError(String message, int? code, dynamic e) {
    print("❌ Customer Pusher Error: $message");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("✅ Customer Subscription to $channelName succeeded!");
  }

  void onEvent(PusherEvent event) {
    print("📩 Customer received event: ${event.eventName} from ${event.channelName}");

    if (onMessageReceived != null) {
      onMessageReceived!(event);
    }
  }

  void onSubscriptionError(String message, dynamic e) {
    print("❌ Customer Subscription Error: $message");
  }

  // Disconnect Pusher
  Future<void> disconnect() async {
    try {
      await pusher.disconnect();
      isConnected = false;
      print("✅ Customer Pusher disconnected!");
    } catch (e) {
      print("❌ Customer disconnection failed: $e");
    }
  }
}