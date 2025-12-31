import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_go/CustomNotificationClass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart'; // Localization

import 'HomePage.dart';
import 'SignUpPage.dart';
import 'main.dart';
import 'EmailService.dart'; // Import EmailService

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Language code, default to 'en'

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    _passwordFocusNode.addListener(_onPasswordFocus);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.removeListener(_onPasswordFocus);
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _onPasswordFocus() {
    if (_passwordFocusNode.hasFocus) {
      String email = _emailController.text.trim();
      if (email.isNotEmpty && !email.contains('@')) {
        _emailController.text = "$email@gmail.com";
      }
    }
  }

  Future<void> _signInWithEmail() async {
    final localizations = AppLocalizations.of(context)!;
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showAlert(localizations.alert_please_fill);
      return;
    }

    if (!_isValidEmail(email)) {
      _showAlert(localizations.alert_valid_email);
      return;
    }

    if (password.length < 6) {
      _showAlert(localizations.alert_password_length);
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;
      String time = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

      // Save notification to Firestore
      await _firestore.collection('Users').doc(userId).collection('Notification').add({
        'title': "Welcome Back!",
        'description': "You've successfully logged in.",
        'time': time,
      });

      // Send login success email
      await _sendLoginSuccessEmail(email);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
            (Route<dynamic> route) => false,
      );

      CustomNotificationClass.MahekCustomNotification(
        context,
        "Login Successful",
        "Welcome back! You have logged in successfully.",
        HomePage(),
        logoIcon: Icons.check_circle,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = localizations.error_user_not_found;
          break;
        case 'wrong-password':
          errorMessage = localizations.error_wrong_password;
          break;
        case 'invalid-email':
          errorMessage = localizations.error_invalid_email;
          break;
        default:
          errorMessage = "${localizations.error_occurred}: ${e.message}";
      }
      _showAlert(errorMessage);
    } catch (e) {
      _showAlert(localizations.error_unexpected);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendLoginSuccessEmail(String userEmail) async {
    try {
      final success = await EmailService.sendEmail(
        recipientEmail: userEmail,
        subject: '🔐 Login Successful - GearGo',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Login Successful</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            line-height: 1.6; 
            color: #333; 
            max-width: 600px; 
            margin: 0 auto; 
            padding: 20px; 
            background: #f8f9fa;
        }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            padding: 30px; 
            text-align: center; 
            border-radius: 10px 10px 0 0; 
            color: white;
        }
        .content { 
            background: white; 
            padding: 30px; 
            border-radius: 0 0 10px 10px;
        }
        .success-box { 
            background: #d4edda; 
            padding: 15px; 
            border-radius: 5px; 
            margin: 20px 0;
            border-left: 4px solid #28a745;
        }
        .info-box { 
            background: #e7f3ff; 
            padding: 15px; 
            border-radius: 5px; 
            margin: 20px 0;
            border-left: 4px solid #007bff;
        }
        .footer { 
            text-align: center; 
            margin-top: 30px; 
            padding-top: 20px; 
            border-top: 1px solid #ddd; 
            color: #666; 
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚗 GearGo</h1>
        <p>Car Rental Service</p>
    </div>
    
    <div class="content">
        <h2>Login Successful!</h2>
        <p>Hello valued customer,</p>
        
        <div class="success-box">
            <h3 style="color: #155724; margin: 0 0 10px 0;">✅ Security Alert</h3>
            <p style="color: #155724; margin: 0;">
                Your account was successfully accessed on <strong>${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}</strong>.
            </p>
        </div>
        
        <div class="info-box">
            <h3 style="color: #004085; margin: 0 0 10px 0;">📱 Login Details</h3>
            <p style="color: #004085; margin: 0;">
                <strong>Email:</strong> $userEmail<br>
                <strong>Time:</strong> ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}<br>
                <strong>Status:</strong> Successful
            </p>
        </div>
        
        <p><strong>If this was you:</strong></p>
        <p>You can safely ignore this email. Thank you for using GearGo!</p>
        
        <p><strong>If this wasn't you:</strong></p>
        <p>Please secure your account immediately by changing your password and contact our support team.</p>
        
        <div style="background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p style="color: #856404; margin: 0;">
                <strong>🔒 Security Tip:</strong><br>
                Always keep your password secure and never share it with anyone.
            </p>
        </div>
        
        <p>Happy driving! 🚗</p>
    </div>
    
    <div class="footer">
        <p>Best regards,<br><strong>The GearGo Team</strong></p>
        <p>© ${DateTime.now().year} GearGo. All rights reserved.</p>
        <p>This is an automated security notification. Please do not reply to this email.</p>
    </div>
</body>
</html>
        ''',
      );

      if (success) {
        print('✅ Login success email sent to: $userEmail');
      } else {
        print('❌ Failed to send login success email');
      }
    } catch (e) {
      print('❌ Error sending login email: $e');
      // Don't show error to user for email failures
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _resetPassword() async {
    final localizations = AppLocalizations.of(context)!;
    String email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      _showAlert(localizations.alert_enter_valid_email);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showAlert(localizations.alert_reset_sent);
    } catch (e) {
      _showAlert("${localizations.error_failed_send} $e");
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Alert"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language),
            onSelected: (String value) {
              Locale newLocale;
              switch (value) {
                case 'en':
                  newLocale = Locale('en');
                  break;
                case 'hi':
                  newLocale = Locale('hi');
                  break;
                case 'gu':
                  newLocale = Locale('gu');
                  break;
                default:
                  newLocale = Locale('en');
              }
              // Call the global setLocale method
              MyApp.setLocale(context, newLocale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'hi', child: Text('Hindi')),
              PopupMenuItem(value: 'gu', child: Text('Gujarati')),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Background shapes omitted for brevity
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 40.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localizations.welcome_back,
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Text(
                          localizations.sign_in_to_continue,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 50),
                        _buildInputField(
                          controller: _emailController,
                          label: localizations.email,
                          icon: Icons.email,
                          obscureText: false,
                        ),
                        SizedBox(height: 25),
                        _buildInputField(
                          controller: _passwordController,
                          label: localizations.password,
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          focusNode: _passwordFocusNode,
                        ),
                        SizedBox(height: 35),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            localizations.sign_in,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextButton(
                          onPressed: _resetPassword,
                          child: Text(
                            localizations.forgot_password,
                            style: GoogleFonts.poppins(
                              color: Colors.blue[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.no_account,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SignUpPage()),
                                );
                              },
                              child: Text(
                                localizations.register,
                                style: GoogleFonts.poppins(
                                  color: Colors.blue[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
