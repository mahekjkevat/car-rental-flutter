import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart'; // For animations
import 'AboutPage.dart';
import 'ChoosePage.dart';
import 'HelpPage.dart';
import 'PrivacyPage.dart';
import 'main.dart';
import 'notification_page.dart';
import 'l10n/app_localizations.dart'; // Import localization

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // Access localized strings

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              localizations.settings,
              style: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language),
            onSelected: (String value) {
              Locale newLocale;
              switch (value) {
                case 'en':
                  newLocale = Locale('en');
                  break;
                case 'hi':
                  newLocale = Locale('hi');
                  break;
                case 'gu':
                  newLocale = Locale('gu');
                  break;
                default:
                  newLocale = Locale('en');
              }
              MyApp.setLocale(context, newLocale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'hi', child: Text('Hindi')),
              PopupMenuItem(value: 'gu', child: Text('Gujarati')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with subtle decoration
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[200]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.shield, color: Colors.white, size: 60),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              children: [
                FadeInUp(
                  duration: Duration(milliseconds: 400),
                  child: _buildSettingTile(
                      context,
                      localizations.privacy,
                      Icons.lock,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PrivacyPage()),
                        );
                      }
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 500),
                  child: _buildSettingTile(
                      context,
                      localizations.notifications,
                      Icons.notifications,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationPage()),
                        );
                      }
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 600),
                  child: _buildSettingTile(
                      context,
                      localizations.help,
                      Icons.help,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HelpPage()),
                        );
                      }
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 700),
                  child: _buildSettingTile(
                      context,
                      localizations.about,
                      Icons.info,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutPage()),
                        );
                      }
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 800),
                  child: _buildSettingTile(
                      context,
                      localizations.logout,
                      Icons.logout,
                      onTap: () {
                        _showLogoutDialog(context, localizations);
                      }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.015,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(icon, color: Colors.blue[700], size: MediaQuery.of(context).size.width * 0.07),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[600], size: MediaQuery.of(context).size.width * 0.04),
          onTap: onTap ?? () {},
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, color: Colors.blue, size: MediaQuery.of(context).size.width * 0.12),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  localizations.logout,
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  localizations.areYouSureLogout,
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        localizations.cancel,
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => ChoosePage()),
                              (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                        elevation: 6,
                      ),
                      child: Text(
                        localizations.logout,
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}