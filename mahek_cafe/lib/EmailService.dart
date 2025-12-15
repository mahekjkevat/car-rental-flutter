import 'dart:async';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // --- CREDENTIALS UPDATED HERE ---
  static final String gmailEmail = 'mahekforever2003@gmail.com';
  // Note: Spaces are removed internally by the mailer package, but it's cleaner to remove them here.
  static final String appPassword = 'adyfoqlqaftpzczo';
  // --------------------------------

  static Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    // Check for dummy credentials which cause connection errors
    if (gmailEmail.isEmpty || appPassword.isEmpty) {
      print('❌ ERROR: Email credentials are not set. Cannot send email.');
      return false;
    }

    try {
      print('🚀 ========== EMAIL SENDING PROCESS STARTED ==========');
      print('📧 From: $gmailEmail');
      print('📨 To: $recipientEmail');
      print('📝 Subject: $subject');

      // Configuration 1: Using gmail() constructor (Preferred and reliable)
      final smtpServer = gmail(gmailEmail, appPassword);

      // Create the message
      final message = Message()
        ..from = Address(gmailEmail, 'Mahek Food Delivery') // Updated App Name
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..html = htmlBody
        ..text = textBody ?? _stripHtml(htmlBody);

      print('📤 Attempting to send email...');

      // Send the email with timeout
      final sendReport = await send(message, smtpServer)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Email sending timed out after 30 seconds');
      });

      print('✅ ========== EMAIL SENT SUCCESSFULLY! ==========');
      print('📫 Message ID: ${sendReport.toString()}');
      return true;

    } on TimeoutException catch (e) {
      print('⏰ ========== TIMEOUT ERROR ==========');
      print('Error: $e');
      return false;
    } on MailerException catch (e) {
      print('📧 ========== MAILER ERROR ==========');
      print('Main error: $e');
      for (var p in e.problems) {
        print('  • Code: ${p.code}, Message: ${p.msg}');
      }
      print('Hint: Ensure your App Password is correct and 2FA is enabled.');
      return false;
    } catch (e) {
      print('❌ ========== UNEXPECTED ERROR ==========');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      return false;
    }
  }

  static String _stripHtml(String html) {
    // Improved regex to better clean HTML for plain text body
    return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}
