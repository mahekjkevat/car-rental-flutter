import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_login_screen.dart';
import 'admin_email_template.dart';

class AdminSignUpScreen extends StatefulWidget {
  const AdminSignUpScreen({super.key});

  @override
  State<AdminSignUpScreen> createState() => _AdminSignUpScreenState();
}

class _AdminSignUpScreenState extends State<AdminSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _otpController = TextEditingController();

  String _generatedOtp = '';
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isRegistrationComplete = false;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _errorMessage = '';
  String _successMessage = '';

  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightInputColor = const Color(0xFFFFFFFF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _adminCodeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final otp = (random % 900000 + 100000).toString();
    print('🔐 [OTP] Generated OTP: $otp');
    return otp;
  }

  Future<void> _sendOtpEmail(String email, String otp) async {
    try {
      final success = await CallAdminMail(
        subject: 'Mahek Admin - OTP Verification',
        bodyText: 'Your OTP for admin registration is: $otp. This OTP is valid for 10 minutes.',
        buttonText: 'Verify OTP',
        recipientEmail: email,
      ).call();

      if (success) {
        print('✅ [OTP] OTP email sent successfully to: $email');
        setState(() {
          _successMessage = 'OTP sent to your email!';
        });
      } else {
        throw Exception('Failed to send OTP email');
      }
    } catch (e) {
      print('❌ [OTP] Error sending OTP email: $e');
      throw Exception('Failed to send OTP email');
    }
  }

  Future<void> _sendRegistrationSuccessEmail(String email, String name) async {
    try {
      final success = await CallAdminMail(
        subject: 'Mahek Admin - Registration Successful',
        bodyText: 'Dear $name, your registration as an administrator has been completed successfully. You now have access to the admin panel.',
        buttonText: 'Access Dashboard',
        recipientEmail: email,
      ).call();

      if (success) {
        print('✅ [EMAIL] Registration success email sent to: $email');
      } else {
        print('❌ [EMAIL] Failed to send registration success email');
      }
    } catch (e) {
      print('❌ [EMAIL] Error sending registration success email: $e');
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter OTP';
      });
      return;
    }

    if (enteredOtp.length != 6) {
      setState(() {
        _errorMessage = 'OTP must be 6 digits';
      });
      return;
    }

    if (enteredOtp == _generatedOtp) {
      setState(() {
        _isOtpVerified = true;
        _errorMessage = '';
        _successMessage = 'OTP verified successfully!';
      });
      print('✅ [OTP] OTP verified successfully');
    } else {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
      });
      print('❌ [OTP] Invalid OTP entered');
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final newOtp = _generateOtp();
      setState(() {
        _generatedOtp = newOtp;
      });

      await _sendOtpEmail(_emailController.text.trim(), newOtp);

      setState(() {
        _successMessage = 'New OTP sent to your email!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check admin code
    if (_adminCodeController.text.trim() != 'MAHEK202003') {
      setState(() {
        _errorMessage = 'Invalid admin registration code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final String email = _emailController.text.trim();

      bool isAdmin = await _isAdminUser(email);
      if (isAdmin) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This email is already registered as an admin.';
        });
        return;
      }

      final otp = _generateOtp();
      setState(() {
        _generatedOtp = otp;
      });

      await _sendOtpEmail(email, otp);

      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
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

  Future<void> _completeRegistration() async {
    if (!_isOtpVerified) {
      setState(() {
        _errorMessage = 'Please verify OTP first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      final String name = _nameController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'administrator',
        'createdAt': Timestamp.now(),
        'permissions': ['manage_users', 'manage_orders', 'view_reports'],
      });

      await _sendRegistrationSuccessEmail(email, name);

      setState(() {
        _isLoading = false;
        _isRegistrationComplete = true;
        _successMessage = 'Admin registration completed successfully!';
      });

      print('✅ [REGISTRATION] Admin registration completed successfully');

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

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Registration failed: ${e.message}';
    }
  }

  void _resetFlow() {
    setState(() {
      _isOtpSent = false;
      _isOtpVerified = false;
      _isRegistrationComplete = false;
      _otpController.clear();
      _errorMessage = '';
      _successMessage = '';
    });
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
        borderSide: BorderSide(color: primaryAppColor.withOpacity(0.1), width: 1.5),
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

  Widget _buildRegistrationForm() {
    return Column(
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

        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.text,
          maxLength: 20,
          decoration: _buildInputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icons.person_outline,
          ),
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) {
            final trimmedValue = value?.trim() ?? '';
            if (trimmedValue.isEmpty) {
              return 'Please enter your name';
            }
            if (trimmedValue.length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        TextFormField(
          controller: _adminCodeController,
          obscureText: true,
          decoration: _buildInputDecoration(
            labelText: 'Admin Registration Code',
            prefixIcon: Icons.security,
          ),
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter admin code';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icons.email_outlined,
          ),
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
        SizedBox(height: 20),

        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: _buildInputDecoration(
            labelText: 'Password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: _buildInputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: secondaryDarkColor.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
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
              'SEND OTP',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerification() {
    return Column(
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

        Text(
          'Enter the 6-digit OTP sent to:',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 5),
        Text(
          _emailController.text.trim(),
          style: GoogleFonts.poppins(
            color: primaryAppColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 20),

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
        SizedBox(height: 25),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'VERIFY OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _resendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(Icons.refresh),
              ),
            ),
          ],
        ),

        if (_isOtpVerified) ...[
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'COMPLETE REGISTRATION',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegistrationComplete() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            size: 50,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Registration Successful!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Your admin account has been created successfully. You can now access the admin panel.',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor.withOpacity(0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAppColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: Text(
              'GO TO LOGIN',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
            if (_isOtpSent || _isOtpVerified || _isRegistrationComplete) {
              _resetFlow();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isRegistrationComplete
              ? 'Registration Complete'
              : _isOtpSent
              ? 'Verify OTP'
              : 'Admin Registration',
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
                  _isRegistrationComplete
                      ? Icons.verified_user
                      : _isOtpSent
                      ? Icons.verified
                      : Icons.admin_panel_settings,
                  size: 40,
                  color: primaryAppColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                _isRegistrationComplete
                    ? 'Welcome Admin!'
                    : _isOtpSent
                    ? 'Verify Your Email'
                    : 'Create Admin Account',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _isRegistrationComplete
                    ? 'Your account is ready to use'
                    : _isOtpSent
                    ? 'Enter the OTP sent to your email'
                    : 'Register as an administrator',
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
                  child: _isRegistrationComplete
                      ? _buildRegistrationComplete()
                      : _isOtpSent
                      ? _buildOtpVerification()
                      : _buildRegistrationForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}