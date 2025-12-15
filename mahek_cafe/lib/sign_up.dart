import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // For generating the 6-digit OTP
import 'home_page.dart';

import 'sign_in.dart';
import 'email_template.dart'; // For sending emails (OTP and Success)

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController(); // New controller for OTP

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables for the two-step process
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _generatedOtp; // Stored OTP for client-side verification

  // --- UPDATED Colors for Mahek Food Delivery (Vibrant Orange Theme) ---
  final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
  final Color secondaryDarkColor = const Color(0xFF333333); // Dark background/text
  final Color lightInputColor = const Color(0xFFFFFFFF); // White for fields

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Handles both sending OTP (Step 1) and verifying/final signup (Step 2)
  Future<void> _handleSignUpProcess() async {
    if (_isOtpSent) {
      await _verifyOtpAndFinalSignup();
    } else {
      await _sendOtp();
    }
  }

  Future<void> _sendOtp() async {
    // Only validate the initial fields in Step 1
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // --- 1. Generate and Send OTP ---
        final otp = (100000 + Random().nextInt(900000)).toString();
        _generatedOtp = otp;

        final emailSubject = 'Mahek Food: Your 6-digit Verification Code';
        final emailBody =
            'Your one-time verification code (OTP) for Mahek Food sign up is: <b>$otp</b>.'
            '<br><br>'
            'This code is valid for a short time. Please enter it on the sign-up screen to complete your registration.'
            '<br><br>'
            'If you did not request this code, please ignore this email.';

        // Use the imported email service
        final mailSuccess = await CallMahekForeverMail(
          subject: emailSubject,
          bodyText: emailBody,
          recipientEmail: _emailController.text.trim(),
        );

        if (mailSuccess) {
          setState(() {
            _isOtpSent = true;
            _errorMessage = 'OTP successfully sent to ${_emailController.text.trim()}. Please check your inbox.';
          });
          print('OTP Mail Sent Successfully!');
        } else {
          setState(() {
            _errorMessage = 'Failed to send OTP email. Please check your email address and try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtpAndFinalSignup() async {
    if (_otpController.text.trim() != _generatedOtp) {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again or resend.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // --- 2. Create User and Store Data ---
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'New Mahek User';
      final userEmail = _emailController.text.trim();
      final userMobile = _mobileController.text.trim();

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': userName,
        'email': userEmail,
        'mobile': userMobile,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // --- 3. Send Success Email ---
      final successSubject = '✨ Welcome to Mahek Food, $userName!';
      final successBody =
          'Congratulations, your account has been successfully created and secured!'
          '<br><br>'
          '<b>Your Details:</b>'
          '<ul>'
          '<li>Name: <b>$userName</b></li>'
          '<li>Email: <b>$userEmail</b></li>'
          '<li>Mobile: <b>$userMobile</b></li>'
          '</ul>'
          'We hope you enjoy the fastest food delivery service. Start ordering now!';

      await CallMahekForeverMail(
        subject: successSubject,
        bodyText: successBody,
        recipientEmail: userEmail,
      );
      print('Sign Up Success Mail Sent!');

      // --- 4. Navigate to HomePage and clear stack ---
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
      // Handle potential errors like email-already-in-use if the user was too fast
      setState(() {
        _errorMessage = 'Sign Up failed: ${e.message}';
        // Reset state so user can try again
        _isOtpSent = false;
        _generatedOtp = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred during final signup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Common InputDecoration for all text fields
  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    // Define the base border style
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: secondaryDarkColor.withOpacity(0.3), width: 1),
    );

    // Define the focused border style
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: primaryAppColor, width: 2), // Highlighted in primary color
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: GoogleFonts.poppins(color: secondaryDarkColor.withOpacity(0.7)),
      prefixIcon: Icon(prefixIcon, color: primaryAppColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: lightInputColor, // Solid white fill
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),

      // Apply custom border styles
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: focusedBorder,
      errorBorder: focusedBorder.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: focusedBorder.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // Widget to display the main sign-up fields (Step 1)
  Widget _buildStepOneFields() {
    return Column(
      children: [
        // Name Field
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          // *** UPDATED TEXT INPUT STYLE ***
          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: _buildInputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter Your Full Name',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Mobile Number Field
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          // *** UPDATED TEXT INPUT STYLE ***
          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: _buildInputDecoration(
            labelText: 'Mobile Number',
            hintText: 'Enter Your Mobile Number',
            prefixIcon: Icons.phone_android,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }
            // Simple check for digits
            if (!RegExp(r'^\d{7,15}$').hasMatch(value)) {
              return 'Please enter a valid mobile number (7-15 digits)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          // *** UPDATED TEXT INPUT STYLE ***
          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: _buildInputDecoration(
            labelText: 'Email',
            hintText: 'Enter Your Email',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          // *** UPDATED TEXT INPUT STYLE ***
          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: _buildInputDecoration(
            labelText: 'Password',
            hintText: 'Enter Your Password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: secondaryDarkColor.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          // *** UPDATED TEXT INPUT STYLE ***
          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: _buildInputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter Your Password',
            prefixIcon: Icons.lock_reset,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: secondaryDarkColor.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // Widget to display the OTP verification field (Step 2)
  Widget _buildStepTwoFields() {
    return Column(
      children: [
        // OTP Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          // *** UPDATED TEXT INPUT STYLE ***
          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
          decoration: _buildInputDecoration(
            labelText: 'Enter 6-digit OTP',
            hintText: 'e.g., 123456',
            prefixIcon: Icons.vpn_key_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 6 || int.tryParse(value) == null) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/food_delivery_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  secondaryDarkColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Main Content Area
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  // App Logo/Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryAppColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 60,
                        color: lightInputColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header Text
                  Text(
                    _isOtpSent ? 'Verify Your Account' : 'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: lightInputColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error Message Display
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: _isOtpSent ? Colors.green[300] : Colors.red[300], // Green for OTP success message
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
                        // Conditional fields based on step
                        _isOtpSent ? _buildStepTwoFields() : _buildStepOneFields(),

                        // Sign Up Button (Handles both steps)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUpProcess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAppColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              _isOtpSent ? 'Verify OTP & Complete Sign Up' : 'Sign Up to Mahek Food',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: lightInputColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Already Have An Account? Sign In
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already Have An Account? ',
                              style: GoogleFonts.poppins(color: lightInputColor),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignIn()),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  color: primaryAppColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
