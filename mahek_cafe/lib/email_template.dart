import 'package:firebase_auth/firebase_auth.dart';
import 'EmailService.dart';

// Aesthetic Colors for HTML Email (matching your Flutter theme)
const String primaryAppColorHex = '#F96D0A'; // Vibrant Orange/Red
const String secondaryDarkColorHex = '#333333'; // Dark background/text
const String lightBackgroundHex = '#F5F5F5';

/// Builds a structured, attractive, and colorfully themed HTML email
/// for Mahek Food Delivery.
String _buildStyledHtmlEmail({
  required String subject,
  required String bodyText,
  // Button parameters are ignored in this version but kept for function compatibility
  String buttonText = 'View My Order',
  String buttonLink = '#',
}) {
  // Placeholder image URL for the background (using picsum for a generic food/kitchen look)
  const String bgImageUrl = 'https://picsum.photos/1200/800?grayscale&blur=3';

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$subject</title>
    <style>
        /* Email client specific resets */
        body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
        table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
        img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }

        /* Main Styles */
        body { 
            font-family: 'Arial', sans-serif; 
            margin: 0; 
            padding: 0; 
            color: $secondaryDarkColorHex;
            background-color: $lightBackgroundHex;
            /* Added Low Opacity Background Image */
            background-image: url('$bgImageUrl'); 
            background-size: cover; 
            background-position: center; 
        }

        /* Semi-transparent overlay to give the background image low opacity */
        .main-wrapper { 
            background-color: rgba(255, 255, 255, 0.7); 
            padding: 20px 0;
        }

        .container { 
            width: 100%; 
            max-width: 600px; 
            margin: 0 auto; 
            background-color: #ffffff; 
            border-radius: 12px; 
            overflow: hidden; 
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15); /* Stronger shadow */
            border: 1px solid #eee;
        }
        
        /* Header Customization */
        .header { 
            background-color: $primaryAppColorHex; 
            color: #ffffff; 
            padding: 30px 20px 20px 20px; 
            text-align: center; 
            border-bottom: 5px solid #FF8C00; /* Darker orange accent */
        }
        .header h1 { 
            margin: 0; 
            font-size: 32px; 
            font-weight: bold; 
            letter-spacing: 1px;
        }
        .header .icon-set { 
            font-size: 40px; 
            margin-bottom: 10px; 
            display: block; 
            line-height: 1;
        }

        /* Content */
        .content { 
            padding: 30px 25px; 
            color: $secondaryDarkColorHex; 
            line-height: 1.6; 
        }
        .content h2 { 
            color: $primaryAppColorHex; 
            font-size: 24px; 
            padding-bottom: 10px; 
            margin-top: 0; 
            font-weight: 700;
        }
        
        /* Button Styling (kept but not used in body) */
        .button-area { text-align: center; padding: 10px 0 25px 0; }
        .button {
            display: inline-block;
            padding: 14px 30px;
            background-color: $primaryAppColorHex;
            color: #ffffff !important;
            text-decoration: none;
            border-radius: 50px; 
            font-weight: bold;
            font-size: 17px;
            box-shadow: 0 6px 15px rgba(249, 109, 10, 0.5);
        }

        /* Footer Customization */
        .footer { 
            background-color: $secondaryDarkColorHex; 
            color: #ffffff; 
            padding: 25px; 
            text-align: center; 
            font-size: 12px; 
            border-top: 5px solid $primaryAppColorHex;
        }
    </style>
</head>
<body style="margin: 0; padding: 0;">

    <div class="main-wrapper" role="presentation">
        <center>
            <table class="container" role="presentation" cellspacing="0" cellpadding="0" border="0" align="center">
                <!-- Header Section -->
                <tr>
                    <td class="header">
                        <!-- Multiple food symbols/emojis -->
                        <span class="icon-set">&#127828; &#127830; &#127839;</span> 
                        <h1>Mahek Food Delivery</h1>
                        <p style="font-size:14px; margin-top: 5px; opacity: 0.9;">Your delicious food is just a click away!</p>
                    </td>
                </tr>

                <!-- Content Section -->
                <tr>
                    <td class="content">
                        <h2>$subject</h2>
                        <p style="font-size: 16px;">Hello there,</p>
                        <p style="font-size: 15px;">$bodyText</p>
                        
                        <!-- REMOVED: Button area -->

                        <p style="margin-top: 30px; font-size: 14px; text-align: center;">
                            Thank you for choosing Mahek. Enjoy your meal! &#128523;
                        </p>
                    </td>
                </tr>

                <!-- Footer Section (Simplified) -->
                <tr>
                    <td class="footer">
                        &copy; ${DateTime.now().year} Mahek Food Delivery. All rights reserved.
                        <!-- REMOVED: Unsubscribe and Privacy links -->
                    </td>
                </tr>
            </table>
        </center>
    </div>
</body>
</html>
''';
}


/// Central function to prepare and send a themed email using the EmailService.
Future<bool> CallMahekForeverMail({
  required String subject,
  required String bodyText,
  String buttonText = 'Go to App',
  String buttonLink = '#',
  String? recipientEmail,
}) async {
  final User? user = FirebaseAuth.instance.currentUser;

  // 1. Determine Recipient Email
  String finalRecipientEmail;
  if (recipientEmail != null) {
    finalRecipientEmail = recipientEmail;
  } else if (user?.email != null) {
    finalRecipientEmail = user!.email!;
  } else {
    print('❌ ERROR: No recipient email provided and no user is currently logged in via Firebase.');
    return false;
  }

  // 2. Build the Styled HTML Body
  // Note: The button/link parameters are ignored by the internal builder now.
  final htmlBody = _buildStyledHtmlEmail(
    subject: subject,
    bodyText: bodyText,
    buttonText: buttonText,
    buttonLink: buttonLink,
  );

  // 3. Send the Email
  return EmailService.sendEmail(
    recipientEmail: finalRecipientEmail,
    subject: subject,
    htmlBody: htmlBody,
  );
}
