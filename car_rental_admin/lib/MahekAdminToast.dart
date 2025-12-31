import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Enum for easy status selection and color assignment
enum ToastStatus { success, error, info }

class MahekAdminToast {
  // Define Theme Colors for consistency
  static const Color _primaryColor = Colors.black;
  static const Color _accentColor = Colors.yellow;
  static const Color _textColor = Colors.white;

  /// Displays a custom, branded toast message (using a SnackBar).
  /// durationSeconds: Sets how long the toast remains visible.
  static void show({
    required BuildContext context,
    required String message,
    ToastStatus status = ToastStatus.info,
    int durationSeconds = 3, // Default duration set to 3 seconds
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case ToastStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case ToastStatus.error:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_outline;
        break;
      case ToastStatus.info:
      default:
        statusColor = _accentColor;
        statusIcon = Icons.info_outline;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Logo/Image (Left side) - Boldly represents the app
          Container(
            width: 30,
            height: 30,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/images/app_logo.jpeg", // Your specified image path
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),

          // 2. Status Icon & Message - High Contrast Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Text (e.g., SUCCESS, ERROR) - Prominent and Bold
                Text(
                  status.toString().split('.').last.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 13, // Slightly increased size
                    fontWeight: FontWeight.w800, // Extra Bold for status
                  ),
                ),
                // Message Text - Bolder and larger for readability
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: _textColor,
                    fontSize: 15, // Increased size
                    fontWeight: FontWeight.w700, // Bold
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3. Status Icon (Right side) - Visual cue
          Icon(
            statusIcon,
            color: statusColor.withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: durationSeconds), // Parameterized Duration
      backgroundColor: _primaryColor, // Black theme background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor, width: 2), // Status color border
      ),
      // Margin moves it up from the bottom of the screen
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
    );

    // Ensure only one toast is visible at a time
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}