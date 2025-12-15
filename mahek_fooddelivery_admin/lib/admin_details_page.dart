import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'edit_admin_profile_page.dart';

class AdminDetailsPage extends StatefulWidget {
  final String adminName;
  final String adminEmail;
  final String? profileImage;
  final String? phone;
  final String? role;

  const AdminDetailsPage({
    super.key,
    required this.adminName,
    required this.adminEmail,
    this.profileImage,
    this.phone,
    this.role,
  });

  @override
  State<AdminDetailsPage> createState() => _AdminDetailsPageState();
}

class _AdminDetailsPageState extends State<AdminDetailsPage> {
  void _navigateToEditProfile(BuildContext context) async {
    // Get current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated!')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdminProfilePage(
          adminId: user.uid, // Use Firebase Auth UID
          currentName: widget.adminName,
          currentProfileImage: widget.profileImage,
          adminEmail: widget.adminEmail,
        ),
      ),
    );

    // Update the UI if profile was edited
    if (result != null && mounted) {
      // You can refresh the data here or use a state management solution
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      // If you're using a state management solution, you would update the state here
      // For example, if using Provider:
      // context.read<AdminProvider>().refreshAdminData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryAppColor = const Color(0xFFF96D0A);
    final Color secondaryDarkColor = const Color(0xFF333333);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Admin Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade100,
                image: const DecorationImage(
                  image: AssetImage('assets/icon/app_logo.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Profile Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryAppColor.withOpacity(0.1),
                      backgroundImage: widget.profileImage != null
                          ? NetworkImage(widget.profileImage!)
                          : null,
                      child: widget.profileImage == null
                          ? Icon(
                        Icons.person,
                        size: 50,
                        color: primaryAppColor,
                      )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Admin Name
                    Text(
                      widget.adminName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: secondaryDarkColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role
                    if (widget.role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryAppColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.role!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryAppColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Details Section
                    _buildDetailRow(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: widget.adminEmail,
                    ),
                    const SizedBox(height: 16),

                    if (widget.phone != null)
                      Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            title: 'Phone Number',
                            value: widget.phone!,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    _buildDetailRow(
                      icon: Icons.security_outlined,
                      title: 'Account Type',
                      value: 'Administrator',
                    ),
                    const SizedBox(height: 16),

                    _buildDetailRow(
                      icon: Icons.access_time_outlined,
                      title: 'Last Login',
                      value: 'Just now',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Quick Actions
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: secondaryDarkColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionChip(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          onTap: () {
                            _navigateToEditProfile(context);
                          },
                        ),
                        _buildActionChip(
                          icon: Icons.security_outlined,
                          label: 'Security',
                          onTap: () {
                            // Add security settings
                          },
                        ),
                        _buildActionChip(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () {
                            // Add notification settings
                          },
                        ),
                        _buildActionChip(
                          icon: Icons.help_outline,
                          label: 'Help & Support',
                          onTap: () {
                            // Add help functionality
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFF96D0A),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFFF96D0A)),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFFF96D0A).withOpacity(0.1),
      onPressed: onTap,
    );
  }
}