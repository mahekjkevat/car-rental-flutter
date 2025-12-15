import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahek_cafe/sign_up.dart';
import 'ForgotPassword.dart';
import 'home_page.dart';
import 'email_template.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Error message state
  String _errorMessage = '';
  bool _isLoading = false;

  // --- UPDATED Colors for Mahek Food Delivery (Vibrant Orange Theme) ---
  final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
  final Color secondaryDarkColor = const Color(0xFF333333); // Dark background/text
  final Color lightInputColor = const Color(0xFFFFFFFF); // White for fields

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_emailListener);
  }

  @override
  void dispose() {
    _emailController.removeListener(_emailListener);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- NEW: Email Auto-Append Logic ---
  void _emailListener() {
    final text = _emailController.text;
    const suffix = '@gmail.com';

    // Only proceed if the text is not empty and the user hasn't manually typed '@'
    if (text.isNotEmpty && !text.contains('@')) {
      // Check if the current text already contains the suffix we want to append
      final alreadyContainsSuffix = text.endsWith(suffix);

      if (!alreadyContainsSuffix) {
        // Use post-frame callback to safely update the controller without triggering an infinite loop
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Store the cursor position before we modify the text
          final originalSelection = _emailController.selection;

          // Replace current text with base text + suffix
          _emailController.value = _emailController.value.copyWith(
            text: text + suffix,
            // Restore selection to the original position (before the suffix)
            selection: TextSelection.collapsed(offset: originalSelection.start),
            composing: TextRange.empty,
          );
        });
      }
    }
  }

  // --- NEW: Common InputDecoration for all text fields ---
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

    // Define the focused border style (Vibrant Orange Highlight)
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: primaryAppColor, width: 2),
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

      // *** NEW: Prevent label from floating above the input field ***
      floatingLabelBehavior: FloatingLabelBehavior.never,

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

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Sign in with email and password
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          // Ensure we are signing in with the final, complete email address
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          // --- START: Send Welcome Mail using FIREBASE AUTH details ---
          final user = userCredential.user!;
          final recipientEmail = user.email!;

          // Attempt to get user's display name, defaulting to email prefix if 'name' field is missing
          final displayName = userDoc.get('name') as String? ?? recipientEmail.split('@').first;

          // Subject and body with bolding applied via HTML tags
          final emailSubject = '🎉 Welcome to Mahek Food, ${displayName}!';
          final emailBody =
              'We are so excited to have <b>${displayName}</b> join the Mahek Food family! '
              'Your account is successfully set up and you are now logged in. '
              'Start exploring our delicious menu and place your first order today.'
              '<br><br>'
              'Your login email is: <b>$recipientEmail</b>. ' // Bolded email
              'We hope you enjoy the best food delivered right to your door!';

          // Send the email (Button/Link arguments are now correctly omitted)
          final mailSuccess = await CallMahekForeverMail(
            subject: emailSubject,
            bodyText: emailBody,
            recipientEmail: recipientEmail,
          );

          if (mailSuccess) {
            print('Mail Sent Successfully!'); // REQUIRED terminal message
          } else {
            print('Warning: Failed to send welcome email to $recipientEmail.');
          }
          // --- END: NEW EMAIL LOGIC ---


          // Navigate to HomePage on successful sign-in
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false, // This condition removes ALL previous routes
          );
        } else {
          // If user document doesn't exist in Firestore
          setState(() {
            _errorMessage = 'User data not found. Please contact support.';
          });
          await _auth.signOut(); // Sign out the user
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'No user found with this email.';
              break;
            case 'wrong-password':
              _errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'invalid-email':
              _errorMessage = 'Invalid email format.';
              break;
            case 'user-disabled':
              _errorMessage = 'This account has been disabled.';
              break;
            default:
              _errorMessage = 'An error occurred: ${e.message}';
          }
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image (UPDATED to a food-related background)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Use the food-related image from GetStarted or a suitable placeholder
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
                  secondaryDarkColor.withOpacity(0.8), // Updated dark color
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
                  // App Logo/Circle (UPDATED for Mahek Food Delivery)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryAppColor.withOpacity(0.8), // Primary Color
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      // Placeholder for the "Mahek Food Delivery" logo/icon
                      child: Icon(
                        Icons.fastfood, // Food icon
                        size: 60,
                        color: lightInputColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header Text
                  Text(
                    'Welcome Back!', // Updated Text
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: lightInputColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error Message Display - UPDATED to show red bold text on a white background
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(12.0),
                      width: double.infinity, // Take full width
                      decoration: BoxDecoration(
                        color: lightInputColor, // White background
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                        border: Border.all(
                          color: Colors.red.shade700, // Red border
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700, // Red Bold text color
                          fontSize: 16, // Slightly larger font size
                          fontWeight: FontWeight.w700, // Bold text
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                            // Only validate the actual format if the user has manually entered '@'
                            if (value.contains('@') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          // *** UPDATED TEXT INPUT STYLE ***
                          style: GoogleFonts.poppins(color: secondaryDarkColor, fontSize: 17, fontWeight: FontWeight.w600),
                          obscureText: !_isPasswordVisible,
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
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPassword()),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.poppins(
                                color: primaryAppColor, // Primary Color
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAppColor, // Primary Color
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'Sign In to Mahek Food', // Updated Text
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: lightInputColor,
                              ),
                            ),
                          ),
                        ),

                        // Increased spacing after the main button
                        const SizedBox(height: 40),

                        // Don't Have An Account? Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't Have An Account? ",
                              style: GoogleFonts.poppins(color: lightInputColor),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUp()),
                                );
                              },
                              child: Text(
                                'Sign Up Now!', // Updated Text
                                style: GoogleFonts.poppins(
                                  color: primaryAppColor, // Matching the primary color
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
