import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'get_started.dart'; // Import the GetStarted page
// Define colors locally as constants.dart is not available in this file
const Color kPrimaryColor = Color(0xFFF96D0A); // Vibrant Orange
const Color kLightTextColor = Colors.white70;

// A helper class to define each page's content
class OnboardingPageModel {
  final String imagePath;
  final String title;
  final String subtitle;
  final String titlePt; // Portuguese Title (for reference)
  final String subtitlePt; // Portuguese Subtitle (for reference)

  OnboardingPageModel({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.titlePt,
    required this.subtitlePt,
  });
}

// Data for the Onboarding Pages (using English)
final List<OnboardingPageModel> pages = [
  OnboardingPageModel(
    imagePath: 'assets/images/onboarding_1.jpg', // Replace with your image
    title: 'Discover the best food around you.',
    subtitle: 'Explore local restaurants and flavors, all in one app.',
    titlePt: 'Descubra a melhor comida perto de si.',
    subtitlePt: 'Explore restaurantes e sabores locais, tudo em uma app.',
  ),
  OnboardingPageModel(
    imagePath: 'assets/images/onboarding_2.jpg', // Replace with your image
    title: 'Order your favorite meals.',
    subtitle: 'With just a few taps, your food is on the way.',
    titlePt: 'Peça a sua comida favorita.',
    subtitlePt: 'Com apenas alguns toques, a sua comida está a caminho.',
  ),
  OnboardingPageModel(
    imagePath: 'assets/images/onboarding_3.jpg', // Replace with your image
    title: 'Enjoy every delicious moment.',
    subtitle: 'Because every meal deserves to be special.',
    titlePt: 'Saboreie momentos deliciosos.',
    subtitlePt: 'Porque cada refeição merece ser especial.',
  ),
  OnboardingPageModel(
    imagePath: 'assets/images/onboarding_4.jpg', // Replace with your image
    title: 'Safe and reliable orders.',
    subtitle: 'Verified restaurants, secure payments, and on-time delivery.',
    titlePt: 'Pedidos seguros e confiáveis.',
    subtitlePt: 'Restaurantes verificados, pagamentos seguros e entregas a tempo.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Last page, navigate to GetStarted
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const GetStarted(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Explicitly set the Scaffold background to black to hide the white flash
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return OnboardingPage(page: pages[index]);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                          (index) => buildDot(index, context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Next/Get Started Button
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kPrimaryColor, // Orange/Red color
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _currentPage == pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Skip Button (optional)
          if (_currentPage < pages.length - 1)
            Align(
              alignment: Alignment.topRight,
              child: SafeArea(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const GetStarted(),
                      ),
                    );
                  },
                  child: Text(
                    'Skip',
                    // APPLYING GOOGLE FONT HERE
                    style: GoogleFonts.poppins(
                      color: Colors.white, // Assuming white text on dark image overlay
                      fontSize: 18, // Slightly larger
                      fontWeight: FontWeight.w600, // Semi-bold for better visibility
                      shadows: const [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black,
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Page Indicator Dot
  AnimatedContainer buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? kPrimaryColor : kLightTextColor,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// Widget for a single Onboarding Page
class OnboardingPage extends StatelessWidget {
  final OnboardingPageModel page;

  const OnboardingPage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(page.imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5), // Slightly darker overlay for text readability
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // APPLYING GOOGLE FONT AND STYLE TO TITLE
            Text(
              page.title,
              style: GoogleFonts.poppins(
                fontSize: 34, // Slightly larger for impact
                fontWeight: FontWeight.w800, // Extra bold
                color: Colors.white,
                shadows: const [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // APPLYING GOOGLE FONT AND STYLE TO SUBTITLE
            Text(
              page.subtitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9), // Near white, slight transparency
                fontWeight: FontWeight.w400,
                shadows: const [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 150), // Space for the indicator and button
          ],
        ),
      ),
    );
  }
}
