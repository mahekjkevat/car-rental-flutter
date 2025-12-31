import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class PrivacyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Function to change the language
    void _changeLanguage(String languageCode) {
      Locale newLocale = Locale(languageCode);
      // Call your method to update the app's locale here
      MyApp.setLocale(context, newLocale);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.privacyPolicy,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.07,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // PopupMenuButton for language options
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: Colors.white),
            tooltip: 'Change Language',
            onSelected: (String value) {
              _changeLanguage(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'en',
                child: Text('English'),
              ),
              PopupMenuItem<String>(
                value: 'hi',
                child: Text('Hindi'),
              ),
              PopupMenuItem<String>(
                value: 'gu',
                child: Text('Gujarati'),
              ),
              // Add other languages here
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              FadeInDown(
                duration: Duration(milliseconds: 600),
                child: _buildSectionCard(context, '', [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 30, color: Colors.blue[600]),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                      Text(
                        localizations.yourPrivacyMatters,
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ], isHeader: true),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              FadeInUp(
                duration: Duration(milliseconds: 700),
                child: Text(
                  localizations.effectiveDate,
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              // Sections
              _buildSectionCard(context, localizations.section1Title, [
                _buildParagraph(context, localizations.section1Content),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              _buildSectionCard(context, localizations.section2Title, [
                _buildParagraph(context, localizations.section2Content),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              _buildSectionCard(context, localizations.section3Title, [
                _buildParagraph(context, localizations.section3Content),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              _buildSectionCard(context, localizations.section4Title, [
                _buildParagraph(context, localizations.section4Content),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              _buildSectionCard(context, localizations.section5Title, [
                _buildParagraph(context, localizations.section5Content),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              _buildSectionCard(context, localizations.section6Title, [
                _buildParagraph(context, localizations.section6Content),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              Center(
                child: Text(
                  localizations.thankYou,
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children, {bool isHeader = false}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: isHeader ? [Colors.blue[100]!, Colors.blue[50]!] : [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.045),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isHeader ? MediaQuery.of(context).size.width * 0.08 : MediaQuery.of(context).size.width * 0.055,
                fontWeight: FontWeight.w700,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: MediaQuery.of(context).size.width * 0.045,
          color: Colors.grey[800],
          height: 1.6,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
