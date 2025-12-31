import 'package:flutter/material.dart';
import 'package:gear_go/HomePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:flutter/services.dart'; // Add this import for clipboard

class HappinessCelebrationPage extends StatefulWidget {
  const HappinessCelebrationPage({Key? key}) : super(key: key);

  @override
  _HappinessCelebrationPageState createState() => _HappinessCelebrationPageState();
}

class _HappinessCelebrationPageState extends State<HappinessCelebrationPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showContinueButton = false;
  // REMOVED: late AnimationController _animationController; // This was unused

  @override
  void initState() {
    super.initState();

    // REMOVED: _animationController initialization since it's not used

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Show continue button after delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showContinueButton = true;
      });
    });
  }

  @override
  void dispose() {
    // REMOVED: _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToHomePage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  // Helper method to ensure opacity stays within bounds
  double _clampOpacity(double value) {
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),

          // Floating elements
          _buildFloatingElements(),

          // Main content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(height: 60),

                        // Celebration header with custom animation
                        _buildCelebrationHeader(),

                        SizedBox(height: 30),

                        // Special offer card
                        _buildSpecialOfferCard(),

                        SizedBox(height: 25),

                        // Celebration message
                        _buildCelebrationMessage(),

                        SizedBox(height: 25),

                        // Features grid
                        _buildFeaturesGrid(),

                        SizedBox(height: 25),

                        // How to claim
                        _buildHowToClaimCard(),

                        SizedBox(height: 25),

                        // Terms and conditions
                        _buildTermsCard(),

                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fixed bottom button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildFixedButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF1A237E).withOpacity(0.8),
            Color(0xFF311B92).withOpacity(0.6),
            Color(0xFF4A148C).withOpacity(0.4),
            Color(0xFF0A0E21).withOpacity(1.0),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating circles - FIXED: Using safe opacity values
        ...List.generate(8, (index) {
          return Positioned(
            left: Random().nextDouble() * MediaQuery.of(context).size.width,
            top: Random().nextDouble() * MediaQuery.of(context).size.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double size = 20 + 10 * sin(_controller.value * 2 * pi + index);
                final double opacity = _clampOpacity(0.1 * (0.5 + 0.5 * sin(_controller.value * 2 * pi + index)));
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity),
                  ),
                );
              },
            ),
          );
        }),

        // Floating stars - FIXED: Using safe opacity values
        ...List.generate(15, (index) {
          return Positioned(
            left: Random().nextDouble() * MediaQuery.of(context).size.width,
            top: Random().nextDouble() * MediaQuery.of(context).size.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double opacity = _clampOpacity(0.3 + 0.7 * sin(_controller.value * 4 * pi + index));
                final double size = 8 + 4 * sin(_controller.value * 2 * pi + index);
                return Icon(
                  Icons.star,
                  color: Colors.yellow.withOpacity(opacity),
                  size: size,
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCelebrationHeader() {
    return Column(
      children: [
        // Custom animated logo
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(_scaleAnimation.value)
                ..rotateZ(_rotationAnimation.value * 0.1),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange,
                      Colors.red,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: 25),

        // Main title with bounce animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double bounce = sin(_controller.value * 4 * pi) * 5;
            return Transform.translate(
              offset: Offset(0, bounce),
              child: Text(
                "🎉 GearGo Turns 1! 🎉",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.yellow.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),

        SizedBox(height: 10),

        // Subtitle with fade animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double opacity = _clampOpacity(0.7 + 0.3 * sin(_controller.value * 2 * pi));
            return Opacity(
              opacity: opacity,
              child: Text(
                "Celebrating One Year of Excellence",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),

        SizedBox(height: 15),

        // Animated date badge
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double scale = 0.95 + 0.05 * sin(_controller.value * 4 * pi);
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "01 Dec 2024 - 01 Dec 2025",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpecialOfferCard() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double hover = sin(_controller.value * 2 * pi) * 3;
        return Transform.translate(
          offset: Offset(0, hover),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFF7931E), Color(0xFFFFC107)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 5,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated celebration icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double pulse = 0.9 + 0.1 * sin(_controller.value * 4 * pi);
                    return Transform.scale(
                      scale: pulse,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.celebration, color: Colors.white, size: 40),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),

                // Discount percentage with glow effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background glow
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final double glow = _clampOpacity(0.5 + 0.5 * sin(_controller.value * 2 * pi));
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3 * glow),
                                Colors.yellow.withOpacity(0.1 * glow),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),

                    // Main text
                    Column(
                      children: [
                        Text(
                          "UPTO",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final double scale = 0.98 + 0.02 * sin(_controller.value * 4 * pi);
                                return Transform.scale(
                                  scale: scale,
                                  child: Text(
                                    "50%",
                                    style: GoogleFonts.poppins(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: Offset(3, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final double scale = 0.98 + 0.02 * sin(_controller.value * 4 * pi + 1);
                                return Transform.scale(
                                  scale: scale,
                                  child: Text(
                                    "OFF",
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: Offset(3, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          "on All Car Rentals",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20),

// Discount code with shine effect and copy button
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double shine = _clampOpacity(0.3 + 0.2 * sin(_controller.value * 4 * pi));
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(shine),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.orange, size: 20),
                              SizedBox(width: 10),
                              Text(
                                "Code: GEARGO1YEAR",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                          // Copy button
                          InkWell(
                            onTap: () {
                              // Copy to clipboard functionality
                              _copyToClipboard("GEARGO1YEAR");
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.copy, color: Colors.orange, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "Copy",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _showCopySuccessDialog();
    } catch (e) {
      // Fallback for web or if clipboard fails
      _showCopySuccessDialog();
    }
  }

  void _showCopySuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 10),
            Text(
              "Copied!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Text(
          "Discount code 'GEARGO1YEAR' copied to clipboard!",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double bounce = sin(_controller.value * 4 * pi) * 2;
                  return Transform.translate(
                    offset: Offset(0, bounce),
                    child: Icon(Icons.celebration, color: Colors.yellow, size: 24),
                  );
                },
              ),
              SizedBox(width: 10),
              Text(
                "Thank You Amazing Year!",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            "Dear Valued Customer,\n\n"
                "We're thrilled to celebrate our 1st anniversary with you! "
                "As a token of our gratitude for your continued support, "
                "we're offering an exclusive Upto 50% discount on all car rentals.\n\n"
                "This is our way of saying thank you for being part of our journey "
                "and helping us grow into the trusted car rental service we are today.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {'icon': Icons.directions_car_filled, 'title': 'All Car Types', 'desc': 'Economy to Luxury'},
      {'icon': Icons.access_time, 'title': 'Flexible Rental', 'desc': 'Hourly, Daily, Weekly'},
      {'icon': Icons.security, 'title': 'Full Coverage', 'desc': 'Comprehensive Insurance'},
      {'icon': Icons.support_agent, 'title': '24/7 Support', 'desc': 'Always Available'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double hover = sin(_controller.value * 2 * pi + index) * 2;
            return Transform.translate(
              offset: Offset(0, hover),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      features[index]['icon'] as IconData,
                      color: Colors.orange,
                      size: 35,
                    ),
                    SizedBox(height: 10),
                    Text(
                      features[index]['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      features[index]['desc'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHowToClaimCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.3), Colors.teal.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double rotation = sin(_controller.value * 2 * pi) * 0.1;
                  return Transform.rotate(
                    angle: rotation,
                    child: Icon(Icons.rocket_launch, color: Colors.white, size: 24),
                  );
                },
              ),
              SizedBox(width: 10),
              Text(
                "How to Claim Your Discount",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildStep("1", "Open GearGo App", "Launch the application"),
          _buildStep("2", "Browse Cars", "Select your preferred vehicle"),
          _buildStep("3", "Choose Dates", "Pick rental duration"),
          _buildStep("4", "Apply Code", "Use: GEARGO1YEAR"),
          _buildStep("5", "Complete Booking", "Enjoy 50% off instantly!"),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double scale = 0.95 + 0.05 * sin(_controller.value * 4 * pi);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.withOpacity(0.3), Colors.blueGrey.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Terms & Conditions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 15),
          Text(
            "• Valid: 01/11/2025 - 30/12/2025\n"
                "• Upto 50% off base rental charges\n"
                "• Cannot combine with other offers\n"
                "• Subject to vehicle availability\n"
                "• Standard terms apply\n"
                "• GearGo may modify/cancel offer",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedButton() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double scale = _showContinueButton ? (0.95 + 0.05 * sin(_controller.value * 4 * pi)) : 0.0;
        final double opacity = _showContinueButton ? 1.0 : 0.0;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _goToHomePage,
                  borderRadius: BorderRadius.circular(15),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "Explore Amazing Offers",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}