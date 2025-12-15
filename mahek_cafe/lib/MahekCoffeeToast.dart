import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class MahekCoffeeToast {
  // Static instance of FToast to manage and show toasts
  static final FToast _fToast = FToast();

  // Aesthetic Colors
  static const Color _coffeeBackground = Color(0xFF4E342E); // Dark Brown
  static const Color _errorBackground = Color(0xFFB71C1C); // Deep Red
  static const Color _logoColor = Color(0xFFE65100); // Accent Orange

  /// Initializes FToast with the current context. This must be called
  /// before showing a toast, ideally in the main app widget's build method
  /// or when the app starts.
  static void init(BuildContext context) {
    _fToast.init(context);
  }

  /// Builds the custom-styled widget for the toast.
  static Widget _buildCustomToastWidget(String message, bool isError) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: isError ? _errorBackground : _coffeeBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. App Icon/Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/images/app_icon.jpeg', // <<< NEW: Use the specified asset path
              height: 30,
              width: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12.0),
          // 2. Message Text with Google Font
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.merriweather( // <<< NEW: Using Merriweather font for a classic look
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a custom-styled toast notification using the custom widget.
  /// It now accepts BuildContext to ensure FToast is initialized correctly.
  static void show(BuildContext context, String message, {bool isError = false}) {
    // FIX: Initialize FToast with the context where it is being shown
    _fToast.init(context);

    // Note: On Web/Desktop, Fluttertoast typically reverts to a simple text-only
    // implementation, but this custom view will be used on mobile devices.
    _fToast.showToast(
      child: _buildCustomToastWidget(message, isError),
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3), // Show a bit longer
    );
  }
}