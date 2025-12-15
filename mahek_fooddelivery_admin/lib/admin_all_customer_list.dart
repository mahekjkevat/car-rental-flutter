// admin_all_customer_list.dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'admin_chat_screen.dart';
import 'app_theme.dart';
import 'back4app_service.dart';
import 'customer_model.dart';

class AdminAllCustomerList extends StatefulWidget {
  const AdminAllCustomerList({super.key});

  @override
  State<AdminAllCustomerList> createState() => _AdminAllCustomerListState();
}

class _AdminAllCustomerListState extends State<AdminAllCustomerList> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print("🟠 Loading customers from Back4App...");
      final customers = await Back4AppService.fetchCustomers();

      setState(() {
        _customers = customers;
        _isLoading = false;
      });

      print("✅ Loaded ${customers.length} customers successfully");
    } catch (e) {
      print("❌ Error loading customers: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(Customer customer) {
    print("🟠 Navigating to chat with ${customer.name}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatScreen(customer: customer),
      ),
    );
  }

  void _refreshCustomers() {
    print("🟠 Refreshing customer list...");
    _loadCustomers();
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('dd/MM/yy').format(dateTime);
  }

  Widget _buildCustomerCard(Customer customer, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: brownColor,
          backgroundImage: customer.profilePhoto != null && customer.profilePhoto!.isNotEmpty
              ? NetworkImage(customer.profilePhoto!)
              : AssetImage('assets/icon/user_placeholder.png') as ImageProvider,
          child: customer.profilePhoto == null || customer.profilePhoto!.isEmpty
              ? Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          customer.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: darkGrayText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              customer.lastMessage ?? 'No messages yet',
              style: TextStyle(color: grayText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              customer.email,
              style: TextStyle(fontSize: 12, color: grayText),
            ),
            if (customer.mobile != null) ...[
              SizedBox(height: 2),
              Text(
                '📱 ${customer.mobile}',
                style: TextStyle(fontSize: 11, color: grayText),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(customer.lastMessageTime),
              style: TextStyle(fontSize: 12, color: grayText),
            ),
            if (customer.unreadCount > 0) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  customer.unreadCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () => _navigateToChat(customer),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryOrange),
          SizedBox(height: 16),
          Text(
            'Loading Customers...',
            style: TextStyle(fontSize: 16, color: grayText),
          ),
          SizedBox(height: 8),
          Text(
            'Fetching from Back4App',
            style: TextStyle(color: grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Failed to load customers',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your connection',
            style: TextStyle(color: grayText),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshCustomers,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: grayText),
          SizedBox(height: 16),
          Text(
            'No Customers Found',
            style: TextStyle(fontSize: 18, color: grayText),
          ),
          Text(
            'Customer messages will appear here',
            style: TextStyle(color: grayText),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshCustomers,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Messages (${_customers.length})'),
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              print("🟠 Search customers");
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : _customers.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadCustomers,
        color: primaryOrange,
        child: ListView.builder(
          itemCount: _customers.length,
          itemBuilder: (context, index) {
            return _buildCustomerCard(_customers[index], index);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshCustomers,
        backgroundColor: primaryOrange,
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh Customers',
      ),
    );
  }
}