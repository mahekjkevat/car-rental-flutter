// back4app_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'customer_model.dart';

class Back4AppService {
  static const String baseUrl = 'https://parseapi.back4app.com';
  static const String applicationId = 'etG3xjCDarBJ9p2Pk6RgeZSbt4THZRGSXifODgBH';
  static const String restApiKey = 'HELCVUH9SNT04axydCvyadADkWFLJXJ8G5bLoC1v';

  static Map<String, String> get headers {
    return {
      'X-Parse-Application-Id': applicationId,
      'X-Parse-REST-API-Key': restApiKey,
      'Content-Type': 'application/json',
    };
  }

  // Fetch all customers from Back4App
  static Future<List<Customer>> fetchCustomers() async {
    try {
      print("🟠 Fetching customers from Back4App...");

      final response = await http.get(
        Uri.parse('$baseUrl/classes/Customer'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        print("✅ Successfully fetched ${results.length} customers");

        return results.map((customerData) {
          return Customer.fromJson(customerData);
        }).toList();
      } else {
        print("❌ Failed to fetch customers: ${response.statusCode}");
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error fetching customers: $e");
      // Return sample data for demo purposes
      return _getSampleCustomers();
    }
  }

  // Fetch customer by ID
  static Future<Customer?> fetchCustomerById(String customerId) async {
    try {
      print("🟠 Fetching customer: $customerId");

      final response = await http.get(
        Uri.parse('$baseUrl/classes/Customer/$customerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> customerData = json.decode(response.body);
        print("✅ Successfully fetched customer: ${customerData['name']}");
        return Customer.fromJson(customerData);
      } else {
        print("❌ Failed to fetch customer: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching customer: $e");
      return null;
    }
  }

  // Create a new customer (for testing)
  static Future<bool> createCustomer(Customer customer) async {
    try {
      print("🟠 Creating customer: ${customer.name}");

      final response = await http.post(
        Uri.parse('$baseUrl/classes/Customer'),
        headers: headers,
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 201) {
        print("✅ Customer created successfully");
        return true;
      } else {
        print("❌ Failed to create customer: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error creating customer: $e");
      return false;
    }
  }

  // Update customer's last message
  static Future<bool> updateCustomerLastMessage(
      String customerId,
      String message,
      int unreadCount
      ) async {
    try {
      print("🟠 Updating customer last message: $customerId");

      final updateData = {
        'last_message': message,
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_count': unreadCount,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/classes/Customer/$customerId'),
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        print("✅ Customer last message updated");
        return true;
      } else {
        print("❌ Failed to update customer: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error updating customer: $e");
      return false;
    }
  }

  // Sample data for demo purposes
  static List<Customer> _getSampleCustomers() {
    print("🔄 Using sample customer data");
    return [
      Customer(
        objectId: 'customer1',
        name: 'KRISHNA KEVAT',
        email: 'mahekforever2003@gmail.com',
        mobile: '9537803676',
        profilePhoto: 'https://ik.imagekit.io/fsp5dxfxe/profile_images/profile_1762074233607_F5IM0a8hx.jpg',
        createdAt: DateTime(2025, 10, 20),
        updatedAt: DateTime(2025, 10, 20),
        lastMessage: 'Hello, I want to order food',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
        unreadCount: 2,
      ),
      Customer(
        objectId: 'customer2',
        name: 'John Doe',
        email: 'john@example.com',
        mobile: '9876543210',
        profilePhoto: '',
        createdAt: DateTime(2025, 10, 15),
        updatedAt: DateTime(2025, 10, 15),
        lastMessage: 'What are today\'s specials?',
        lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
        unreadCount: 0,
      ),
      Customer(
        objectId: 'customer3',
        name: 'Jane Smith',
        email: 'jane@example.com',
        mobile: '9123456789',
        profilePhoto: '',
        createdAt: DateTime(2025, 10, 10),
        updatedAt: DateTime(2025, 10, 10),
        lastMessage: 'My order is delayed',
        lastMessageTime: DateTime.now().subtract(Duration(days: 2)),
        unreadCount: 1,
      ),
      Customer(
        objectId: 'customer4',
        name: 'Mike Johnson',
        email: 'mike@example.com',
        mobile: '9988776655',
        profilePhoto: '',
        createdAt: DateTime(2025, 10, 5),
        updatedAt: DateTime(2025, 10, 5),
        lastMessage: 'Can I get extra sauce?',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 5)),
        unreadCount: 0,
      ),
    ];
  }
}