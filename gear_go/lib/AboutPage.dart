import 'package:flutter/material.dart';
import 'package:gear_go/happiness.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? selectedLanguageCode;
  bool showContent = true;

  void changeLanguage(String code) async {
    setState(() {
      showContent = false; // Trigger fade out
    });
    await Future.delayed(Duration(milliseconds: 300));
    Locale newLocale;
    switch (code) {
      case 'gu':
        newLocale = Locale('gu');
        break;
      case 'hi':
        newLocale = Locale('hi');
        break;
      default:
        newLocale = Locale('en');
    }
    MyApp.setLocale(context, newLocale);
    setState(() {
      selectedLanguageCode = code;
      showContent = true; // Fade in with new language
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Background Shapes
          Positioned(
            top: -50,
            left: -50,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          // Main Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.blue[600],
                elevation: 0,
                pinned: true,
                leading: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: Text(
                  localizations.aboutUs,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                actions: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.language, color: Colors.white),
                    onSelected: (String code) {
                      changeLanguage(code);
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(value: 'en', child: Text('English')),
                          PopupMenuItem(value: 'gu', child: Text('Gujarati')),
                          PopupMenuItem(value: 'hi', child: Text('Hindi')),
                        ],
                  ),
                ],
              ),
              // Content with effect
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child:
                      showContent
                          ? Padding(
                            key: ValueKey<String>(selectedLanguageCode ?? 'en'),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo
                                FadeInDown(
                                  child: Center(
                                    child: Hero(
                                      tag: 'app-logo',
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.asset(
                                            'assets/images/car.png',
                                            height: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 32),
                                // Header
                                FadeInUp(
                                  child: Text(
                                    localizations
                                        .yourUltimateCarRentalExperience,
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 24),
                                // Our Story
                                FadeInUp(
                                  delay: Duration(milliseconds: 200),
                                  child: _buildSectionCard(
                                    title: localizations.ourStory,
                                    content: localizations.welcomeMessage,
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Our Features Section Title
                                FadeInUp(
                                  delay: Duration(milliseconds: 400),
                                  child: _buildSectionTitle(
                                    localizations.aboutUsSectionTitle,
                                  ),
                                ),
                                // Features Grid
                                FadeInUp(
                                  delay: Duration(milliseconds: 600),
                                  child: _buildFeaturesGrid(
                                    context,
                                    localizations,
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Our Mission (Using same welcomeMessage as placeholder)
                                FadeInUp(
                                  delay: Duration(milliseconds: 800),
                                  child: _buildSectionCard(
                                    title: localizations.aboutUs,
                                    content: localizations.welcomeMessage,
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Connect With Us
                                FadeInUp(
                                  delay: Duration(milliseconds: 1000),
                                  child: _buildSectionCard(
                                    title: localizations.connectWithUs,
                                    contentWidget: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          localizations.welcomeMessage,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        _buildContactRow(
                                          Icons.email_outlined,
                                          'mahekjkevat@gmail.com',
                                          () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Email feature coming soon!',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: 8),
                                        _buildContactRow(
                                          Icons.phone_outlined,
                                          '+919537803676',
                                          () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Phone feature coming soon!',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          HappinessCelebrationPage(),
                                                ),
                                              );ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Contact form coming soon!',
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[600],
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              localizations.contactUs,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 32),
                              ],
                            ),
                          )
                          : Container(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blue[600],
      ),
    ),
  );

  Widget _buildSectionCard({
    required String title,
    String? content,
    Widget? contentWidget,
  }) => Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 8),
        contentWidget ??
            Text(
              content ?? '',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
      ],
    ),
  );

  Widget _buildFeaturesGrid(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final features = [
      {
        'icon': Icons.directions_car,
        'title': localizations.luxuryFleet,
        'desc': localizations.luxuryFleetDesc,
      },
      {
        'icon': Icons.calendar_today,
        'title': localizations.easyBooking,
        'desc': localizations.easyBookingDesc,
      },
      {
        'icon': Icons.lock_outline,
        'title': localizations.securePayments,
        'desc': localizations.securePaymentsDesc,
      },
      {
        'icon': Icons.headset_mic,
        'title': localizations.support,
        'desc': localizations.supportDesc,
      },
      {
        'icon': Icons.design_services,
        'title': localizations.sleekInterface,
        'desc': localizations.sleekInterfaceDesc,
      },
      {
        'icon': Icons.star_border,
        'title': localizations.exclusivePerks,
        'desc': localizations.exclusivePerksDesc,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return _FeatureCard(
          icon: features[index]['icon'] as IconData,
          title: features[index]['title'] as String,
          description: features[index]['desc'] as String,
        );
      },
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue[600], size: 36),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
