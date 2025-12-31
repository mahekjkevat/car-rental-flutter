import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forgot_password.dart';
import 'sign_in_page.dart';
import 'set_location_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminIdController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimationTitle;
  late Animation<Offset> _slideAnimationFields;
  late Animation<Offset> _slideAnimationButton;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimationTitle = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _slideAnimationFields = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeOut)),
    );

    _slideAnimationButton = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9, curve: Curves.easeOut)),
    );

    _controller.forward();

    // Debounced email auto-fill
    _emailController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        String text = _emailController.text.trim();
        if (text.isNotEmpty && !text.contains('@')) {
          setState(() {
            _emailController.text = '$text@gmail.com';
            _emailController.selection = TextSelection.fromPosition(
              TextPosition(offset: _emailController.text.length - 10),
            );
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminIdController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      print('Sign-up started: Email: ${_emailController.text}');

      try {
        // Step 1: Create user with email and password
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('Authentication timed out');
        });
        final userId = userCredential.user!.uid;
        print('User created in Firebase Auth: User ID: $userId');

        // Step 2: Save user data to CarAdmin collection
        await FirebaseFirestore.instance.collection('CarAdmin').doc(userId).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _mobileController.text.trim(),
          'adminId': _adminIdController.text.trim(),
          'selectedLocation': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isAnonymous': false,
        }).timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('Firestore save timed out');
        });
        print('Firestore data saved to CarAdmin for User ID: $userId');

        // Step 3: Show success toast and navigate to SetLocationPage
        _showCustomToast('Sign Up Successful! Please set your location.', Colors.green);
        if (mounted) {
          print('Navigating to SetLocationPage with User ID: $userId');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SetLocationPage(userId: userId)),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'weak-password':
            errorMessage = 'The password is too weak.';
            break;
          default:
            errorMessage = 'Authentication error: ${e.message}';
        }
        print('Authentication error: $e');
        _showCustomToast(errorMessage, Colors.red);
      } on TimeoutException catch (e) {
        print('Timeout error: $e');
        _showCustomToast('Request timed out. Check your network.', Colors.red);
      } catch (e, stackTrace) {
        print('Unexpected error during sign-up: $e, Stack: $stackTrace');
        _showCustomToast('Unexpected error: $e', Colors.red);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          print('Sign-up process completed');
        }
      }
    } else {
      print('Form validation failed: Please fill all fields correctly');
      _showCustomToast('Please fill all fields correctly.', Colors.red);
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Exit Sign Up',
          style: GoogleFonts.poppins(
            color: Colors.yellow,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel sign-up?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Exit',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  void _showCustomToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor.withOpacity(0.9),
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: backgroundColor == Colors.green
          ? '#00FF00'
          : backgroundColor == Colors.orange
          ? '#FFA500'
          : '#FF0000',
      webPosition: 'center',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit) {
          print('Back button pressed: Navigating to SignInPage');
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignInPage()));
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/images/car.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),
              // Form content
              SafeArea(
                child: FocusScope(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          SlideTransition(
                            position: _slideAnimationTitle,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.yellow.withOpacity(0.5),
                                      offset: const Offset(2, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          SlideTransition(
                            position: _slideAnimationTitle,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Create a new Car Rental Admin account',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[300],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Form Fields
                          SlideTransition(
                            position: _slideAnimationFields,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hint: 'Enter your full name',
                                    keyboardType: TextInputType.text,
                                    prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter Full Name';
                                      if (value.contains(RegExp(r'[0-9]'))) return 'Name must not contain numbers';
                                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                        return 'Name must contain only alphabetic characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Enter your email',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(Icons.email, color: Colors.yellow),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter Email';
                                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                          .hasMatch(value)) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _mobileController,
                                    label: 'Mobile Number',
                                    hint: 'Enter your mobile number',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: const Icon(Icons.phone, color: Colors.yellow),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter Mobile Number';
                                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                        return 'Mobile Number must be exactly 10 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    obscureText: _obscurePassword,
                                    prefixIcon: const Icon(Icons.lock, color: Colors.yellow),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter Password';
                                      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$')
                                          .hasMatch(value)) {
                                        return 'Password must be 8+ chars with 1 uppercase, 1 lowercase, 1 special char';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Confirm your password',
                                    obscureText: _obscureConfirmPassword,
                                    prefixIcon: const Icon(Icons.lock, color: Colors.yellow),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please confirm Password';
                                      if (value != _passwordController.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _adminIdController,
                                    label: 'Car Owner Admin ID',
                                    hint: 'Enter ADMIN ID',
                                    prefixIcon: const Icon(Icons.badge, color: Colors.yellow),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter Admin ID';
                                      if (value != 'CARADMIN2025') return 'Invalid Admin ID';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Forgot Password
                          SlideTransition(
                            position: _slideAnimationButton,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    print('Forgot Password tapped: Navigating to ForgotPasswordPage');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.poppins(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Sign Up Button
                          SlideTransition(
                            position: _slideAnimationButton,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: GradientButton(
                                onPressed: _isLoading ? null : _signUp,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 4)
                                    : Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Sign In Link
                          SlideTransition(
                            position: _slideAnimationButton,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[300],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      print('Sign In tapped: Navigating to SignInPage');
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SignInPage()),
                                      );
                                    },
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.poppins(
                                        color: Colors.yellow,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                            strokeWidth: 6.0,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Creating Account...',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autofocus: false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.yellow, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
          keyboardType: keyboardType,
          obscureText: obscureText,
          cursorColor: Colors.yellow,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color> colors;
  final List<Color> disabledColors; // Add disabled colors

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors = const [Colors.yellow, Colors.amber],
    this.disabledColors = const [Colors.grey, Colors.grey], // Default disabled colors
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final List<Color> currentColors = isEnabled ? colors : disabledColors;

    return GestureDetector( // Using GestureDetector for simple tap
      onTap: isEnabled ? onPressed : null, // Only call onPressed if enabled
      child: AnimatedScale(
        scale: isEnabled ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 280, // Keep the width
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: currentColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: (isEnabled ? Colors.yellow : Colors.grey).withOpacity(0.3), // Adjust shadow color
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}