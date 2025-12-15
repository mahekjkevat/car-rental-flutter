import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ImageKit.dart';
import 'email_template.dart'; // Import the new template file

class EmailDemoScreen extends StatefulWidget {
  const EmailDemoScreen({super.key});

  @override
  State<EmailDemoScreen> createState() => _EmailDemoScreenState();
}

class _EmailDemoScreenState extends State<EmailDemoScreen> {
  // Use colors from your theme
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);

  String _statusMessage = 'Ready to send confirmation.';
  bool _isLoading = false;

  void _sendSampleEmail() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      setState(() {
        _statusMessage = 'Error: No authenticated user found with an email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending email to ${user.email}...';
    });

    // --- Prepare Email Content ---
    const subject = '🎉 Your Mahek Order Has Been Confirmed!';
    final bodyText =
        'Dear ${user.email ?? 'Customer'},\n\n'
        'We are delighted to confirm your recent order (ID: #MHK12345). '
        'Your delicious meal is currently being prepared and will be dispatched soon. '
        'Thank you for your patience and patronage!';

    // --- Call the centralized function ---
    final success = await CallMahekForeverMail(
      subject: subject,
      bodyText: bodyText,
      buttonText: 'Track Your Delivery',
      buttonLink: 'https://mahekfood.com/track/MHK12345',
      // recipientEmail is left null here, so it automatically uses user.email!
    );

    setState(() {
      _isLoading = false;
      if (success) {
        _statusMessage = 'Success! Confirmation email sent to ${user.email}!';
      } else {
        _statusMessage = 'Failed to send email. Check console for details.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mahek Email Demo', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryAppColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mail_outline, size: 80, color: primaryAppColor),
              const SizedBox(height: 20),
              Text(
                'Simulate Order Confirmation',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryDarkColor),
              ),
              const SizedBox(height: 10),
              if (user != null)
                Text(
                  'Current User: ${user.email ?? 'No Email (Anonymous)'}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: secondaryDarkColor.withOpacity(0.7)),
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendSampleEmail,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isLoading ? 'Sending...' : 'Send Confirmation Email',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAppColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 40),
              //Call ImageKitUploader File
              ElevatedButton(
                onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  ImageKitUploader()),
                );
                },
                child: Text('Upload Image'),
              ),

              const SizedBox(height: 30),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: _statusMessage.contains('Success') ? Colors.green[700] : secondaryDarkColor
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
