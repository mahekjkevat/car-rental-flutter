import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';
import 'ForgotPasswordPage.dart';
import 'SignInPage.dart';
import 'l10n/app_localizations.dart'; // Your localization class
import 'main.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _licenseNoController = TextEditingController();

  // Dropdown selections
  String? selectedCity;
  String? selectedState;
  String? selectedCountry;

  final List<String> cityOptions = [
    'Bardoli',
    'Bilimora',
    'Gandevi',
    'Mahuva',
    'Navsari',
    'Surat',
  ];

  final Map<String, String> cityPinMap = {
    'Bardoli': '394601',
    'Bilimora': '396321',
    'Gandevi': '396320',
    'Mahuva': '364290',
    'Navsari': '396445',
    'Surat': '395003',
  };

  final List<String> stateOptions = ['Gujrat'];
  final List<String> countryOptions = ['India'];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showAdditionalFields = false;
  bool _showVerifyEmailButton = false;
  bool _isVerifying = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color activeBlue = Color(0xFF1E88E5);

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    _pinCodeController.dispose();
    _licenseNoController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _proceedToAdditionalFields() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _errorMessage = null);
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _errorMessage = localizations.pleaseFillAllFields);
      return;
    }

    if (RegExp(r'\d').hasMatch(name)) {
      setState(() => _errorMessage = localizations.nameCannotContainNumbers);
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = localizations.enterValidEmail);
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = localizations.passwordMustBeAtLeast6);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = localizations.passwordsDoNotMatch);
      return;
    }

    setState(() => _showAdditionalFields = true);
  }

  Future<void> _register() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    String mobileNumber = _mobileController.text.trim();
    String pinCode = _pinCodeController.text.trim();
    String licenseNo = _licenseNoController.text.trim();

    if (selectedCity == null || selectedCity!.isEmpty) {
      setState(() {
        _errorMessage = localizations.pleaseSelectCity;
        _isLoading = false;
      });
      return;
    }

    if (mobileNumber.isEmpty || pinCode.isEmpty || licenseNo.isEmpty) {
      setState(() {
        _errorMessage = localizations.pleaseFillAllFields;
        _isLoading = false;
      });
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber)) {
      setState(() {
        _errorMessage = localizations.enterValidMobile;
        _isLoading = false;
      });
      return;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(pinCode)) {
      setState(() {
        _errorMessage = localizations.enterValidPinCode;
        _isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'mobile_number': mobileNumber,
          'city': selectedCity,
          'pin_code': pinCode,
          'state': selectedState ?? '',
          'country': selectedCountry ?? '',
          'license_no': licenseNo,
          'dateCreated': DateTime.now(),
        });

        await user.sendEmailVerification();
        setState(() {
          _errorMessage = localizations.verificationEmailSent;
          _showVerifyEmailButton = true;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = localizations.error_user_already_in_use;
          break;
        case 'invalid-email':
          errorMessage = localizations.error_invalid_email;
          break;
        case 'weak-password':
          errorMessage = localizations.error_password_too_weak;
          break;
        default:
          errorMessage = localizations.error_occurred + ": ${e.message}";
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = localizations.error_occurred + ": $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyEmail() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    User? user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      user = _auth.currentUser;

      if (user!.emailVerified) {
        await _postUserNotificationCreated();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = localizations.verificationNotSent;
          _isVerifying = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = localizations.noUserFound;
        _isVerifying = false;
      });
    }
  }

  Future<void> _postUserNotificationCreated() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        String time = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
        await _firestore
            .collection('Users')
            .doc(userId)
            .collection('Notification')
            .add({
          'title': "Account Created Successfully!",
          'description':  "Welcome to our app! Your account has been created.",
          'time': time,
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sending notification: $e");
    }
  }

  // Language selection dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(localizations.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                onTap: () {
                  MyApp.setLocale(context, Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Gujarati'),
                onTap: () {
                  MyApp.setLocale(context, Locale('gu'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Hindi'),
                onTap: () {
                  MyApp.setLocale(context, Locale('hi'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final activeBlue = Color(0xFF1E88E5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: activeBlue),
            onPressed: _showLanguageDialog,
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Background decorations or images can go here
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _showAdditionalFields
                                ? localizations.fillDetails
                                : localizations.createAccount,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: activeBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            _showAdditionalFields
                                ? localizations.fillDetails
                                : localizations.signUp,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),

                          if (!_showAdditionalFields) ...[
                            // Initial registration fields
                            _buildInputField(
                              controller: _nameController,
                              label: localizations.fullName,
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseFillAllFields;
                                }
                                if (RegExp(r'\d').hasMatch(value)) {
                                  return localizations.nameCannotContainNumbers;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            _buildInputField(
                              controller: _emailController,
                              label: localizations.email,
                              icon: Icons.email,
                              validator: (value) {
                                if (value == null || value.isEmpty || !_isValidEmail(value)) {
                                  return localizations.enterValidEmail;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseFillAllFields;
                                }
                                if (value.length < 6) {
                                  return localizations.passwordMustBeAtLeast6;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            _buildInputField(
                              controller: _confirmPasswordController,
                              label: localizations.confirmPassword,
                              icon: Icons.lock,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey[600],
                                ),
                                onPressed: _toggleConfirmPasswordVisibility,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseFillAllFields;
                                }
                                if (value != _passwordController.text) {
                                  return localizations.passwordsDoNotMatch;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _proceedToAdditionalFields,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeBlue,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                localizations.next,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Additional fields
                            DropdownButtonFormField<String>(
                              value: selectedCity,
                              items: cityOptions
                                  .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(
                                  city,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCity = value;
                                  _pinCodeController.text = cityPinMap[value!] ?? '';
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_city, color: activeBlue),
                                labelText: localizations.city,
                                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: activeBlue, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseSelectCity;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            _buildInputField(
                              controller: _pinCodeController,
                              label: localizations.pinCode,
                              icon: Icons.pin_drop,
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseEnterPinCode;
                                }
                                if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                                  return localizations.enterValidPinCode;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            _buildInputField(
                              controller: _mobileController,
                              label: localizations.mobileNumber,
                              icon: Icons.phone,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseEnterMobile;
                                }
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                  return localizations.enterValidMobile;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: selectedState,
                              items: stateOptions
                                  .map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(
                                  state,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedState = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.map, color: activeBlue),
                                labelText: localizations.state,
                                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: activeBlue, width: 2),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: selectedCountry,
                              items: countryOptions
                                  .map((country) => DropdownMenuItem(
                                value: country,
                                child: Text(
                                  country,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCountry = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.public, color: activeBlue),
                                labelText: localizations.country,
                                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: activeBlue, width: 2),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildInputField(
                              controller: _licenseNoController,
                              label: localizations.licenseNumber,
                              icon: Icons.credit_card,
                              validator: validateLicenseNumber,
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeBlue,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                localizations.signUp,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_showVerifyEmailButton) ...[
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isVerifying
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  localizations.verifyEmail,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (_errorMessage != null) ...[
                            SizedBox(height: 20),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                color: _errorMessage!.contains("sent")
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizations.alreadyHaveAccount,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SignInPage()),
                                  );
                                },
                                child: Text(
                                  localizations.signIn,
                                  style: GoogleFonts.poppins(
                                    color: activeBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              localizations.forgotPassword,
                              style: GoogleFonts.poppins(
                                color: activeBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: activeBlue),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeBlue, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

// Your license validation
String? validateLicenseNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your license number';
  }
  if (value.length != 15) {
    return 'License must be exactly 15 characters long';
  }
  final pattern = RegExp(r'^[A-Z]{2}\d{13}$');
  if (!pattern.hasMatch(value)) {
    return 'Format: 2 uppercase letters followed by 13 digits';
  }
  return null;
}