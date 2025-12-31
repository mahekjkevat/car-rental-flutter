import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/custom_toast.dart';
import 'forgot_password.dart';
import 'sign_up_page.dart';
import 'package:car_rental_admin/home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _carAdminIdController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _carAdminIdFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimationTitle;
  late Animation<Offset> _slideAnimationFields;
  late Animation<double> _scaleAnimationButton;

  @override
  void initState() {
    super.initState();
    // Animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _slideAnimationTitle = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimationFields = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimationButton = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Add focus listeners for validation on focus
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) _formKey.currentState?.validate();
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) _formKey.currentState?.validate();
    });
    _carAdminIdFocus.addListener(() {
      if (_carAdminIdFocus.hasFocus) _formKey.currentState?.validate();
    });

    // Add text listeners for real-time validation
    _emailController.addListener(() => _formKey.currentState?.validate());
    _passwordController.addListener(() => _formKey.currentState?.validate());
    _carAdminIdController.addListener(() => _formKey.currentState?.validate());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _carAdminIdController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _carAdminIdFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: 'Please correct the errors in the form.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Retry authentication up to 2 times
      int maxRetries = 2;
      int attempt = 0;
      UserCredential? userCredential;

      while (attempt < maxRetries && userCredential == null) {
        attempt++;
        print('Authentication attempt $attempt with email: ${_emailController.text.trim().toLowerCase()}');
        try {
          userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text.trim(),
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Authentication timed out on attempt $attempt');
            },
          );
        } on FirebaseAuthException catch (e) {
          if (attempt == maxRetries) rethrow; // Final attempt, rethrow error
          print('Retryable auth error on attempt $attempt: ${e.code}');
          await Future.delayed(const Duration(seconds: 1)); // Delay before retry
        }
      }

      final userId = userCredential?.user?.uid;
      if (userId == null) {
        throw Exception('User ID is null after authentication');
      }
      print('Authenticated successfully, User ID: $userId');

      // Fetch user data from Firestore
      print('Fetching Firestore data for CarAdmin/$userId');
      final doc = await FirebaseFirestore.instance
          .collection('CarAdmin')
          .doc(userId)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Firestore fetch timed out'),
      );

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final storedAdminId = data['adminId']?.toString();
        final storedEmail = data['email']?.toString()?.toLowerCase();

        print('Firestore data: email=$storedEmail, adminId=$storedAdminId');
        print(
          'Input: email=${_emailController.text.trim().toLowerCase()}, adminId=${_carAdminIdController.text.trim()}',
        );

        if (_emailController.text.trim().toLowerCase() == storedEmail &&
            _carAdminIdController.text.trim() == storedAdminId) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
          );

          CustomToast.show(
            context,
            message: 'Admin Login successfully $storedEmail',
          );
          print('Navigating to HomePage');

        } else {
          await FirebaseAuth.instance.signOut();
          Fluttertoast.showToast(
            msg:
            'Email or CarAdminID does not match! Stored: Email=$storedEmail, AdminID=$storedAdminId',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.9),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          print('Mismatch: Input email=${_emailController.text.trim()}, adminId=${_carAdminIdController.text.trim()}');
        }
      } else {
        await FirebaseAuth.instance.signOut();
        Fluttertoast.showToast(
          msg: 'User data not found in Firestore for User ID: $userId',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print('No Firestore document found for CarAdmin/$userId');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('FirebaseAuthException: $e, Code: ${e.code}');
    } on TimeoutException catch (e) {
      Fluttertoast.showToast(
        msg: 'Request timed out. Please check your network and try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('TimeoutException: $e');
    } catch (e, stackTrace) {

      print('Unexpected error: $e, StackTrace: $stackTrace');
    } finally {
      print("Finally block executed");
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                backgroundColor: Colors.black.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Exit Sign In',
                  style: GoogleFonts.poppins(
                    color: Colors.yellow,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: Text(
                  'Are you sure you want to cancel sign-in?',
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
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage()),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Animated background gradient
              AnimatedContainer(
                duration: const Duration(seconds: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.grey[900]!.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              // Background image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/car.png',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            Container(color: Colors.black),
                  ),
                ),
              ),
              // Form content
              SafeArea(
                child: FocusScope(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 30.0,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          SlideTransition(
                            position: _slideAnimationTitle,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.yellow.withOpacity(0.6),
                                      offset: const Offset(0, 3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Subtitle
                          SlideTransition(
                            position: _slideAnimationTitle,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Access your Car Rental Admin account',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Form Fields
                          SlideTransition(
                            position: _slideAnimationFields,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    label: 'Email',
                                    hint: 'Enter your email',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(
                                      Icons.email,
                                      color: Colors.yellow,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                      ).hasMatch(value)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    obscureText: _obscurePassword,
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Colors.yellow,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.grey[400],
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscurePassword =
                                                    !_obscurePassword,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _carAdminIdController,
                                    focusNode: _carAdminIdFocus,
                                    label: 'CarAdminID',
                                    hint:
                                        'Enter your CarAdminID (e.g., CARADMIN2025)',
                                    prefixIcon: const Icon(
                                      Icons.badge,
                                      color: Colors.yellow,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'CarAdminID is required';
                                      }
                                      if (value != 'CARADMIN2025') {
                                        return 'Invalid CarAdminID';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Forgot Password
                          SlideTransition(
                            position: _slideAnimationFields,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const ForgotPasswordPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.poppins(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Sign In Button
                          ScaleTransition(
                            scale: _scaleAnimationButton,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: GradientButton(
                                onPressed: _isLoading ? null : _signIn,
                                child:
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 4,
                                        )
                                        : Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Sign Up Link
                          SlideTransition(
                            position: _slideAnimationFields,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const SignUpPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.poppins(
                                        color: Colors.yellow,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
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
            color: Colors.grey[300],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.yellow, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
            ),
            errorStyle: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
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

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors = const [Colors.yellow, Colors.amber],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: Colors.yellow.withOpacity(0.6),
          backgroundColor: Colors.transparent, // Remove white background
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey[700];
            }
            return null;
          }),
        ),
        child: AnimatedScale(
          scale: onPressed != null ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: onPressed != null ? colors : [Colors.grey[700]!, Colors.grey[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
