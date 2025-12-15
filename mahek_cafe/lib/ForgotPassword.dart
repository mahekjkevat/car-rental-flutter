// file: lib/ForgotPassword.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in.dart'; // Make sure to import the SignIn screen for the "Back to Sign In" button

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _message = '';
  bool _isLoading = false;
  bool _isEmailValid = false;

  // --- UPDATED Colors for Mahek Food Delivery (Vibrant Orange Theme) ---
  final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
  final Color secondaryDarkColor = const Color(0xFF333333); // Dark background/text
  final Color lightInputColor = const Color(0xFFFFFFFF); // White for fields

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
        await _auth.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        setState(() {
          _message = 'Password reset link sent! Check your email.';
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'invalid-email':
              _message = 'Invalid email format.';
              break;
            case 'user-not-found':
              _message = 'No user found with this email.';
              break;
            default:
              _message = 'An error occurred: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _message = 'An unexpected error occurred: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (UPDATED to food-related)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/food_delivery_bg.jpg'), // Use the food asset
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Gradient Overlay (UPDATED dark color)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  secondaryDarkColor.withOpacity(0.8), // Use the themed dark color
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100), // Increased space for centering
                    // Logo/Circle (UPDATED icon and color)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryAppColor.withOpacity(0.7), // Primary App Color
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_reset, // Changed icon to a lock reset symbol
                          size: 45,
                          color: lightInputColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Trouble Signing In?', // Updated Text
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: lightInputColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your registered email address to receive a link to reset your password.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error/Success Message Display
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _message,
                          style: GoogleFonts.poppins(
                            color: _message.contains('sent') ? Colors.green[300] : Colors.red[300],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Text Field (UPDATED colors and style)
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address', // Updated label
                              labelStyle: GoogleFonts.poppins(color: secondaryDarkColor.withOpacity(0.7)),
                              filled: true,
                              fillColor: lightInputColor.withOpacity(0.9), // White fill
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: primaryAppColor, // Primary Color Icon
                              ),
                            ),
                            style: GoogleFonts.poppins(color: secondaryDarkColor), // Dark text color
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            onChanged: _validateEmail,
                          ),
                          const SizedBox(height: 32),

                          // Send Reset Link Button (UPDATED color)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading || !_isEmailValid ? null : _sendPasswordResetEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryAppColor, // Primary App Color
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                disabledBackgroundColor: primaryAppColor.withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                'SEND RESET LINK',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: lightInputColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back to Sign In Button (UPDATED Border Color)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // Pop to go back, but if you want to ensure it navigates to the SignIn root:
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignIn()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryAppColor, width: 2), // Themed border color
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'BACK TO SIGN IN',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: lightInputColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}