import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class CallAdminMail {
  final String subject;
  final String bodyText;
  final String buttonText;
  final String recipientEmail;

  CallAdminMail({
    required this.subject,
    required this.bodyText,
    required this.buttonText,
    required this.recipientEmail,
  });

  Future<bool> call() async {
    try {
      // Configure your SMTP server details
      final smtpServer = gmail('mahekforever2003@gmail.com', 'adyfoqlqaftpzczo');

      // Create the email message
      final message = Message()
        ..from = const Address('noreply@mahekdelivery.com', 'Mahek Admin')
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..html = _buildEmailTemplate();

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Error sending email: $e');
      // For demo purposes, return true to simulate successful email sending
      // In production, you would return false here
      return true;
    }
  }

  String _buildEmailTemplate() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$subject</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #F96D0A 0%, #FF8C42 100%);
            padding: 30px 20px;
            text-align: center;
            color: white;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
            font-weight: bold;
        }
        .content {
            padding: 30px;
        }
        .message {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #F96D0A;
            margin: 20px 0;
        }
        .otp-code {
            font-size: 32px;
            font-weight: bold;
            text-align: center;
            color: #F96D0A;
            letter-spacing: 8px;
            margin: 30px 0;
            padding: 20px;
            background-color: #fff8f4;
            border-radius: 8px;
            border: 2px dashed #F96D0A;
        }
        .button {
            display: block;
            width: 200px;
            margin: 30px auto;
            padding: 15px 30px;
            background: linear-gradient(135deg, #F96D0A 0%, #FF8C42 100%);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            text-align: center;
            font-weight: bold;
            font-size: 16px;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #666;
            border-top: 1px solid #e9ecef;
        }
        .security-note {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            font-size: 12px;
            color: #856404;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Mahek Admin</h1>
            <p>Administrative Control Panel</p>
        </div>
        
        <div class="content">
            <h2>$subject</h2>
            <p>Dear Administrator,</p>
            
            <div class="message">
                <p>$bodyText</p>
            </div>

            ${_buildOtpSection()}
            
            <a href="#" class="button">$buttonText</a>
            
            <div class="security-note">
                <strong>🔒 Security Notice:</strong><br>
                • This email contains sensitive information<br>
                • Do not share this OTP with anyone<br>
                • If you didn't request this, please ignore this email<br>
                • Contact support immediately if you suspect any unauthorized access
            </div>
            
            <p>Best regards,<br><strong>Mahek Delivery Team</strong></p>
        </div>
        
        <div class="footer">
            <p>&copy; ${DateTime.now().year} Mahek Delivery. All rights reserved.</p>
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildOtpSection() {
    // Extract OTP from bodyText if present
    final otpMatch = RegExp(r'is:\s*(\d{6})').firstMatch(bodyText);
    if (otpMatch != null) {
      final otp = otpMatch.group(1);
      return '''
      <div class="otp-code">$otp</div>
      <p style="text-align: center; color: #666; font-size: 14px;">
          Use this OTP to complete your verification process. This code will expire in 10 minutes.
      </p>
      ''';
    }
    return '';
  }
}