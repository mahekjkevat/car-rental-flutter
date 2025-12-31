import 'package:flutter/material.dart';
import 'EmailService.dart';

class EmailSenderPage extends StatefulWidget {
  @override
  _EmailSenderPageState createState() => _EmailSenderPageState();
}

class _EmailSenderPageState extends State<EmailSenderPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false;
  String _resultMessage = '';
  bool _isSuccess = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    // Set default values
    _subjectController.text = 'Welcome to GearGo! 🚗';
    _messageController.text = '''
Hello from GearGo!

Thank you for testing our email service. This is a sample email sent from our Flutter app.

We're excited to have you on board!

Best regards,
GearGo Team
    ''';

    // Test credentials on startup
    _testCredentials();
  }

  Future<void> _testCredentials() async {
    print('🧪 Testing Gmail credentials on app start...');
    await EmailService.testCredentials();
  }

  Future<void> _sendEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _resultMessage = 'Please enter an email address';
        _isSuccess = false;
        _debugInfo = 'No email address provided';
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _resultMessage = 'Please enter a valid email address';
        _isSuccess = false;
        _debugInfo = 'Invalid email format: ${_emailController.text}';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _resultMessage = '';
      _debugInfo = 'Starting email sending process...';
    });

    // Clear previous debug console
    print('\n' * 5); // Add some space in console
    print('🔄 ========== NEW EMAIL ATTEMPT ==========');

    try {
      final success = await EmailService.sendEmail(
        recipientEmail: _emailController.text.trim(),
        subject: _subjectController.text,
        htmlBody: '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>${_subjectController.text}</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .header h1 { color: white; margin: 0; font-size: 28px; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚗 GearGo</h1>
    </div>
    <div class="content">
        <h2>Hello!</h2>
        <p>${_messageController.text.replaceAll('\n', '<br>')}</p>
        
        <div style="text-align: center;">
            <a href="#" class="button">Get Started</a>
        </div>
        
        <p>If you have any questions, feel free to reply to this email.</p>
        
        <div class="footer">
            <p>Best regards,<br><strong>The GearGo Team</strong></p>
            <p style="font-size: 12px; color: #999;">
                © 2024 GearGo. All rights reserved.<br>
                This email was sent from our Flutter application.
            </p>
        </div>
    </div>
</body>
</html>
        ''',
      );

      setState(() {
        _isSending = false;
        _isSuccess = success;
        _resultMessage = success
            ? '✅ Email sent successfully to ${_emailController.text}'
            : '❌ Failed to send email. Check console for details.';
        _debugInfo = success ? 'Success!' : 'Check debug console (Run tab in VS Code/Android Studio)';
      });

      if (success) {
        // Clear only the email field on success
        _emailController.clear();
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _isSuccess = false;
        _resultMessage = '❌ Error occurred. Check debug console.';
        _debugInfo = 'Error: $e\n\nOpen Run tab in VS Code/Android Studio to see detailed logs';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Email from Flutter - DEBUG'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _testCredentials,
            tooltip: 'Test Credentials',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Debug Header
              Container(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange),
                        SizedBox(width: 10),
                        Text(
                          'DEBUG MODE',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Check the console (Run tab) for detailed error messages',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Look for messages starting with: 🚀 📧 ❌ 🔄',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // App Logo/Header
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(Icons.email_outlined, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Send Test Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Using: hetpaa0208@gmail.com',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Email Input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Recipient Email',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 15),

              // Subject Input
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Enter email subject',
                  prefixIcon: Icon(Icons.subject),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              SizedBox(height: 15),

              // Message Input
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter your message',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
              ),

              SizedBox(height: 25),

              // Send Button
              ElevatedButton(
                onPressed: _isSending ? null : _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSending
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Sending... Please wait'),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 12),
                    Text('Send Test Email'),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Result Message
              if (_resultMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green[50] : Colors.red[50],
                    border: Border.all(
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _resultMessage,
                              style: TextStyle(
                                color: _isSuccess ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _debugInfo,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green[700] : Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),

              // Troubleshooting Card
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            'Troubleshooting Steps:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildStep('1. Check Console', 'Open Run tab in VS Code/Android Studio'),
                      _buildStep('2. Verify App Password', 'Ensure 2FA is enabled on Gmail'),
                      _buildStep('3. Check Internet', 'Try mobile data if WiFi fails'),
                      _buildStep('4. Test Credentials', 'Use the bug icon in app bar'),
                      SizedBox(height: 10),
                      Text(
                        'Console logs will show detailed error messages with possible solutions.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String step, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}