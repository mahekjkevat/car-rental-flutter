import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahek_fooddelivery_admin/admin_signup_screen.dart';
import 'admin_dashboard.dart';
import 'admin_email_template.dart'; // Contains CallAdminMail class

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isOtpSent = false;
  bool _isVerifyingOtp = false;
  String _errorMessage = '';
  String _successMessage = '';
  String _generatedOtp = '';

  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightInputColor = const Color(0xFFFFFFFF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<bool> _isAdminUser(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Admin check error: $e');
      return false;
    }
  }

  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final otp = (random % 900000 + 100000).toString();
    print('Generated OTP: $otp');
    return otp;
  }

  Future<void> _sendOtpEmail(String email, String otp) async {
    try {
      // FIX: Correctly instantiate the CallAdminMail class and call its method
      final success = await CallAdminMail(
        subject: 'Mahek Admin - OTP Verification',
        bodyText:
            'Your OTP for admin login verification is: $otp\n\nThis OTP is valid for 10 minutes. Do not share this code with anyone.',
        buttonText: 'Verify OTP',
        recipientEmail: email,
      ).call(); // <-- FIX: Added .call() to resolve non_bool_condition error

      if (success) {
        print('OTP email sent successfully to: $email');
        setState(() {
          _successMessage = 'OTP sent to your email! Check your inbox.';
        });
      } else {
        throw Exception('Failed to send OTP email');
      }
    } catch (e) {
      print('OTP email error: $e');
      throw Exception('Failed to send OTP email: $e');
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      _generatedOtp = _generateOtp();
      await _sendOtpEmail(_emailController.text.trim(), _generatedOtp);

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to send OTP: ${e.toString().contains('Failed to send OTP email:') ? 'The email service failed to send the OTP.' : e.toString()}';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = '';
    });

    try {
      if (_otpController.text == _generatedOtp) {
        await _completeSignIn();
      } else {
        setState(() {
          _isVerifyingOtp = false;
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = 'Verification failed: $e';
      });
    }
  }

  Future<void> _completeSignIn() async {
    try {
      await _sendLoginEmail(_emailController.text.trim());

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (Route<dynamic> route) => false, // This predicate ensures all previous routes are removed
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = 'Error completing sign in: $e';
      });
    }
  }

  Future<void> _sendLoginEmail(String email) async {
    try {
      // FIX: Correctly instantiate the CallAdminMail class and call its method
      await CallAdminMail(
        subject: 'Admin Login Successful - Mahek Delivery',
        bodyText:
            'You have successfully logged into your Mahek Admin Panel. Welcome back!',
        buttonText: 'Go to Dashboard',
        recipientEmail: email,
      ).call(); // <-- FIX: Added .call() to resolve non_bool_condition error
      print('Login email sent to: $email');
    } catch (e) {
      print('Login email error: $e');
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      bool isAdmin = await _isAdminUser(email);
      if (!isAdmin) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Access denied. Admin privileges required.';
        });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      await _sendOtp();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getAuthErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _resendOtp() async {
    await _sendOtp();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No admin account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Sign in failed: ${e.message}';
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 16),
      prefixIcon: Icon(prefixIcon, color: primaryAppColor.withOpacity(0.7)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: lightInputColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primaryAppColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryAppColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: _buildInputDecoration(
            labelText: 'Enter 6-digit OTP',
            prefixIcon: Icons.sms_outlined,
          ),
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
        ),
        SizedBox(height: 10),
        Text(
          'Check your email for the OTP code',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryAppColor.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isOtpSent) {
              setState(() {
                _isOtpSent = false;
                _otpController.clear();
                _errorMessage = '';
                _successMessage = '';
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isOtpSent ? 'Verify OTP' : 'Admin Login',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isOtpSent ? Icons.verified_user : Icons.admin_panel_settings,
                  size: 40,
                  color: primaryAppColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                _isOtpSent ? 'Verify Admin Identity' : 'Welcome Admin!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _isOtpSent
                    ? 'Enter the 6-digit OTP sent to your email'
                    : 'Sign in to administrative control panel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 10),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_successMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            _successMessage,
                            style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (!_isOtpSent) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            labelText: 'Admin Email',
                            prefixIcon: Icons.email_outlined,
                          ),
                          style: GoogleFonts.poppins(
                            color: secondaryDarkColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter admin email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: secondaryDarkColor.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            color: secondaryDarkColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAppColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'SIGN IN & SEND OTP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],

                      if (_isOtpSent) ...[
                        _buildOtpInput(),
                        SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isVerifyingOtp ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: _isVerifyingOtp
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'VERIFY OTP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive OTP?",
                              style: GoogleFonts.poppins(
                                color: secondaryDarkColor.withOpacity(0.7),
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _resendOtp,
                              child: Text(
                                'Resend OTP',
                                style: GoogleFonts.poppins(
                                  color: primaryAppColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ADDED: Sign Up Text Link
              SizedBox(height: 30),

              if (!_isOtpSent) // Only show this if we are on the main login screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        //Call Admin Sign Up Screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminSignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "New Admin?",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Action: This should ideally navigate to an Admin Sign Up screen
                        // or open a prompt to contact the main administrator.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Admin registration requires contact with the system owner.',
                            ),
                            backgroundColor: primaryAppColor,
                          ),
                        );
                      },
                      child: Text(
                        'Contact for Access',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

              // END OF ADDED SECTION
            ],
          ),
        ),
      ),
    );
  }
}
