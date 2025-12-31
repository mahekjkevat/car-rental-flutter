import 'dart:async';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final String gmailEmail = 'hetpaa0208@gmail.com';
  static final String appPassword = 'vbcqbtomhsrjelcs'; // Without spaces

  static Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    try {
      print('🚀 ========== EMAIL SENDING PROCESS STARTED ==========');
      print('📧 From: $gmailEmail');
      print('📨 To: $recipientEmail');
      print('🔑 App Password: ${appPassword.substring(0, 4)}...${appPassword.substring(appPassword.length - 4)}');
      print('📝 Subject: $subject');

      // Try different SMTP configurations
      SmtpServer smtpServer;

      // Configuration 1: Using gmail() constructor
      print('🔄 Trying Configuration 1: gmail() constructor...');
      try {
        smtpServer = gmail(gmailEmail, appPassword);
        print('✅ Configuration 1: Success');
      } catch (e) {
        print('❌ Configuration 1 failed: $e');

        // Configuration 2: Manual SMTP settings
        print('🔄 Trying Configuration 2: Manual SMTP settings...');
        smtpServer = SmtpServer(
          'smtp.gmail.com',
          username: gmailEmail,
          password: appPassword,
          port: 587,
          ssl: false,
          allowInsecure: true,
          ignoreBadCertificate: true,
        );
        print('✅ Configuration 2: Success');
      }

      // Create the message
      final message = Message()
        ..from = Address(gmailEmail, 'GearGo App')
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..html = htmlBody
        ..text = textBody ?? _stripHtml(htmlBody);

      print('📤 Attempting to send email...');

      // Send the email with timeout
      final sendReport = await send(message, smtpServer)
          .timeout(Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Email sending timed out after 30 seconds');
      });

      print('✅ ========== EMAIL SENT SUCCESSFULLY! ==========');
      print('📫 Message ID: ${sendReport.toString()}');
      return true;

    } on TimeoutException catch (e) {
      print('⏰ ========== TIMEOUT ERROR ==========');
      print('Error: $e');
      print('Possible causes:');
      print('• Slow internet connection');
      print('• Gmail server is busy');
      print('• Network firewall blocking SMTP port 587');
      return false;
    } on MailerException catch (e) {
      print('📧 ========== MAILER ERROR ==========');
      print('Main error: $e');
      print('Detailed problems:');
      for (var p in e.problems) {
        print('  • Code: ${p.code}, Message: ${p.msg}');
      }
      print('Possible solutions:');
      print('• Check if app password is correct');
      print('• Ensure 2FA is enabled on Gmail');
      print('• Try using mobile data instead of WiFi');
      return false;
    } catch (e) {
      print('❌ ========== UNEXPECTED ERROR ==========');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace:');
      print(e.toString());
      print('Possible issues:');
      print('• Internet permission missing in AndroidManifest.xml');
      print('• App password has spaces or special characters');
      print('• Gmail account security restrictions');
      return false;
    }
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  // Test method to verify credentials
  static Future<void> testCredentials() async {
    print('🧪 ========== TESTING GMAIL CREDENTIALS ==========');
    print('Email: $gmailEmail');
    print('App Password: $appPassword');

    try {
      final smtpServer = gmail(gmailEmail, appPassword);
      print('✅ SMTP Server created successfully');

      final testMessage = Message()
        ..from = Address(gmailEmail, 'Test')
        ..recipients.add(gmailEmail)
        ..subject = 'GearGo Test - ${DateTime.now()}'
        ..text = 'This is a test email to verify credentials.';

      print('📤 Sending test email...');
      await send(testMessage, smtpServer);
      print('✅ Test email sent successfully!');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }
}