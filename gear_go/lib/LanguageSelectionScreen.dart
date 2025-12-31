import 'package:flutter/material.dart';
import 'package:gear_go/ChoosePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';
import 'main.dart'; // your localization class

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with SingleTickerProviderStateMixin {
  final List<String> availableLanguages = ['English', 'Hindi', 'Gujarati'];
  final List<String> otherLanguages = [
    'English (UK)', 'English (Australia)', 'English (India)', '简体中文',
    '繁體中文', '繁體中文 (香港)', '日本語', 'Español', 'Español (Latinoamérica)',
    'Français', 'Français (Canada)',
  ];

  // Map language strings to locale objects
  final Map<String, Locale> languageMap = {
    'English': Locale('en'),
    'Hindi': Locale('hi'),
    'Gujarati': Locale('gu'),
  };

  String selectedLanguage = 'English';
  Locale? selectedLocale; // The locale to set

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String toastMessage = '';
  bool showToast = false;

  @override
  void initState() {
    super.initState();
    selectedLocale = languageMap[selectedLanguage] ?? Locale('en');

    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void showToastMessage(String message) {
    setState(() {
      toastMessage = message;
      showToast = true;
    });
    _animationController.forward();

    Future.delayed(Duration(seconds: 2), () {
      _animationController.reverse().then((value) {
        setState(() {
          showToast = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optional: get localized strings using AppLocalizations.of(context)
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.chooseLanguage ?? 'Choose a Language',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade400,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 80, color: Colors.blue.shade400),
                  SizedBox(height: 26),
                  Text(
                    AppLocalizations.of(context)?.selectYourLanguage ?? 'Select Your Language',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 30),
                  Container(
                    width: 340,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade400, width: 2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLanguage,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade400),
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedLanguage = newValue;
                              if (languageMap.containsKey(newValue)) {
                                selectedLocale = languageMap[newValue];
                                // Immediately update app language
                                MyApp.setLocale(context, selectedLocale!);
                                showToastMessage("Language Changed - $newValue");
                              } else {
                                showToastMessage("Coming Soon");
                              }
                            });
                          }
                        },
                        items: [
                          ...availableLanguages.map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          )),
                          ...otherLanguages.map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(
                              lang,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedLocale != null) {
                          MyApp.setLocale(context, selectedLocale!);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChoosePage()),
                        );
                        showToastMessage("You Choose Language - $selectedLanguage");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showToast)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.7,
              left: 40,
              right: 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      toastMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}