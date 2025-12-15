import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahek_fooddelivery_admin/EmailService.dart'; // Adjust path if needed
import 'package:mahek_fooddelivery_admin/admin_mahek_toast.dart'; // Adjust path if needed
import 'package:mahek_fooddelivery_admin/customer_models.dart'; // IMPORTANT: This model is needed to fetch emails

class InformToUserForNewsPage extends StatefulWidget {
  const InformToUserForNewsPage({super.key});

  @override
  State<InformToUserForNewsPage> createState() => _InformToUserForNewsPageState();
}

class _InformToUserForNewsPageState extends State<InformToUserForNewsPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  final Color primaryAppColor = const Color(0xFFF96D0A);

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Helper to build a simple, attractive HTML template for the news
  String _buildNewsEmailHtml(String subject, String description) {
    // This is a basic HTML template for a professional announcement email
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>$subject</title>
    <style>
        body { font-family: 'Poppins', Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1); }
        .header { background-color: #F96D0A; padding: 25px; text-align: center; color: #ffffff; }
        .header h1 { margin: 0; font-size: 24px; font-weight: 600; }
        .content { padding: 30px; line-height: 1.6; color: #333333; }
        .content h2 { color: #F96D0A; font-size: 20px; border-bottom: 2px solid #F96D0A; padding-bottom: 10px; margin-top: 0; }
        .footer { background-color: #eeeeee; color: #666666; padding: 20px; text-align: center; font-size: 12px; border-top: 1px solid #dddddd; }
        .message-box { background-color: #fff6f0; border-left: 5px solid #F96D0A; padding: 15px; margin-top: 15px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Mahek Food Delivery News</h1>
        </div>
        <div class="content">
            <h2>$subject</h2>
            <p>Dear Customer,</p>
            <div class="message-box">
                <p>${description.replaceAll('\n', '<br>')}</p>
            </div>
            <p>Thank you for being a valued customer!</p>
        </div>
        <div class="footer">
            <p>&copy; ${DateTime.now().year} Mahek Delivery. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  Future<void> _sendNewsEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    final htmlBody = _buildNewsEmailHtml(subject, description);

    // 1. Fetch all user emails from the 'users' collection
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      // Filter out invalid/empty emails using the AppUser model
      final userEmails = snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc).email)
          .where((email) => email != 'N/A' && email.isNotEmpty)
          .toList();

      if (userEmails.isEmpty) {
        AdminMahekToast.showWarning(context, 'No valid user emails found to send to.');
        print('Warning: No valid user emails found.');
        setState(() => _isSending = false);
        return;
      }

      print('Total users found for email blast: ${userEmails.length}');

      // 2. Send email to all users
      int successCount = 0;
      int failureCount = 0;

      for (String email in userEmails) {
        // Calling the static sendEmail method from EmailService
        bool success = await EmailService.sendEmail(
          recipientEmail: email,
          subject: subject,
          htmlBody: htmlBody,
        );

        if (success) {
          successCount++;
          print('✅ Successfully sent email to: $email');
        } else {
          failureCount++;
          print('❌ Failed to send email to: $email');
        }
      }

      // 3. Show Toast and Print Summary
      final message = 'Email blast completed: $successCount success, $failureCount failures.';

      if (failureCount == 0 && successCount > 0) {
        AdminMahekToast.showSuccess(context, 'All emails sent successfully! $successCount recipients.');
      } else if (successCount > 0) {
        AdminMahekToast.showWarning(context, message);
      } else {
        AdminMahekToast.showError(context, 'Failed to send any emails. Check console logs.');
      }

      print('🚀 Final Summary: $message');


    } catch (e) {
      AdminMahekToast.showError(context, 'An unexpected error occurred: $e');
      print('🚨 Global Error during email blast: $e');
    }

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcast News to Users', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryAppColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Announcement',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Divider(height: 30),

              // Subject Field
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g., Exciting new offers inside!',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Description / Body Content',
                  hintText: 'Write the full announcement details here...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 150),
                    child: Icon(Icons.description),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the body content.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNewsEmail,
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending to all users...' : 'Send to All Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAppColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}