// file: lib/admin_mahek_toast.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastType { success, error, warning, info }

class AdminMahekToast {
  static void show(
      BuildContext context,
      String message,
      ToastType type, {
        Duration duration = const Duration(seconds: 4),
      }) {
    final Color backgroundColor;
    final Color accentColor;
    final IconData icon;
    final String title;

    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xFFE8F5E8);
        accentColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle_rounded;
        title = 'Success';
        break;
      case ToastType.error:
        backgroundColor = const Color(0xFFFDECEA);
        accentColor = const Color(0xFFF44336);
        icon = Icons.error_outline_rounded;
        title = 'Error';
        break;
      case ToastType.warning:
        backgroundColor = const Color(0xFFFFF4E5);
        accentColor = const Color(0xFFFF9800);
        icon = Icons.warning_amber_rounded;
        title = 'Warning';
        break;
      case ToastType.info:
        backgroundColor = const Color(0xFFE3F2FD);
        accentColor = const Color(0xFF2196F3);
        icon = Icons.info_outline_rounded;
        title = 'Info';
        break;
    }

    // Remove any existing toast
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show new toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _ToastContent(
          title: title,
          message: message,
          icon: icon,
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          onClose: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // Convenience methods for different toast types
  static void showSuccess(BuildContext context, String message) {
    show(context, message, ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, ToastType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message, ToastType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, ToastType.info);
  }
}

class _ToastContent extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback onClose;

  const _ToastContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.9),
            backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          // Left Side: App Icon in Beautiful Circular Design
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF96D0A).withOpacity(0.9),
                  const Color(0xFFFF8C42),
                  const Color(0xFFFFA75C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF96D0A).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(-2, -2),
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Pattern
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.8],
                    ),
                  ),
                ),
                // App Icon Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "M",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 0.8,
                      ),
                    ),
                    Text(
                      "Cafe",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Status Icon with Background
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Close Button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade600),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for quick toast usage
extension ToastExtension on BuildContext {
  void showSuccessToast(String message) => AdminMahekToast.showSuccess(this, message);
  void showErrorToast(String message) => AdminMahekToast.showError(this, message);
  void showWarningToast(String message) => AdminMahekToast.showWarning(this, message);
  void showInfoToast(String message) => AdminMahekToast.showInfo(this, message);
}