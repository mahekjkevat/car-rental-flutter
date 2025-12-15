import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahek_cafe/contact_support_page.dart';

// Define the consistent theme colors based on home_page.dart
const Color primaryBrown = Color(0xFF5D4037); // Richer Dark Brown
const Color accentOrange = Color(0xFFF4511E); // Vibrant Orange/Terracotta
const Color lightBgColor = Colors.white; // Creamy light background

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dummy FAQ Data for the Mahek Food Delivery App
  final List<Map<String, String>> faqData = [
    {
      'question': 'How can I cancel my order?',
      'answer': 'You can cancel your order only if the restaurant has not yet accepted it. Navigate to the "Orders" page, select the pending order, and tap the "Cancel Order" button. Once food preparation begins, cancellation may not be possible.',
    },
    {
      'question': 'How do I order food?',
      'answer': 'Ordering is easy! Browse the menu on the Home screen or use the Search bar. Tap on the items you like, adjust the quantity, and add them to your cart. Once ready, go to the "Cart" page to checkout and confirm your delivery details.',
    },
    {
      'question': 'How can I contact the delivery driver?',
      'answer': 'Once your order is picked up and en route, the live tracking screen will show the driver\'s details. A "Call" or "Chat" button will appear, allowing you to connect with them directly for any delivery inquiries.',
    },
    {
      'question': 'What are your delivery hours?',
      'answer': 'Our delivery hours typically run from 8:00 AM to 11:00 PM every day. Specific restaurant hours may vary, but you will only be able to place an order when the restaurant is open.',
    },
    {
      'question': 'Is there a minimum order amount?',
      'answer': 'Most restaurants do not have a minimum order amount. However, a small delivery fee may apply. If a minimum order is required, it will be clearly displayed before you proceed to checkout.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryAppColor,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryBrown.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 10),
              // Map through the FAQ data to create animated accordion tiles
              ...faqData.map((faq) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Theme(
                        // Remove the default divider line
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: accentOrange,
                          collapsedIconColor: primaryBrown.withOpacity(0.7),
                          backgroundColor: lightBgColor,
                          collapsedBackgroundColor: Colors.white,
                          title: Text(
                            faq['question']!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: primaryBrown,
                            ),
                          ),
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                              width: double.infinity,
                              color: lightBgColor.withOpacity(0.5), // Subtle background for the answer
                              child: Text(
                                faq['answer']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: primaryBrown.withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 30),
              // Footer/Contact Call-to-Action
              Center(
                child: Column(
                  children: [
                    Text(
                      'Still need help?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ContactSupportPage()),
                        );
                      },
                      icon: const Icon(Icons.support_agent, color: accentOrange),
                      label: Text(
                        'Contact Customer Support',
                        style: GoogleFonts.poppins(
                          color: accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentOrange, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
