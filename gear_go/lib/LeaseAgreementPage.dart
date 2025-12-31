import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gear_go/main.dart'; // Import MyApp to access setLocale
import 'l10n/app_localizations.dart';

class LeaseAgreementPage extends StatelessWidget {
  const LeaseAgreementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<Map<String, String>> topics = [
      {
        'title': localizations.topic_intro_title,
        'subtitle': localizations.topic_intro_subtitle,
        'details': localizations.topic_intro_details,
        'icon': 'info',
      },
      {
        'title': localizations.topic_def_title,
        'subtitle': localizations.topic_def_subtitle,
        'details': localizations.topic_def_details,
        'icon': 'gavel',
      },
      {
        'title': localizations.topic_agreement_title,
        'subtitle': localizations.topic_agreement_subtitle,
        'details': localizations.topic_agreement_details,
        'icon': 'handshake',
      },
      {
        'title': localizations.topic_usage_title,
        'subtitle': localizations.topic_usage_subtitle,
        'details': localizations.topic_usage_details,
        'icon': 'directions_car',
      },
      {
        'title': localizations.topic_term_title,
        'subtitle': localizations.topic_term_subtitle,
        'details': localizations.topic_term_details,
        'icon': 'calendar_today',
      },
      {
        'title': localizations.topic_delivery_title,
        'subtitle': localizations.topic_delivery_subtitle,
        'details': localizations.topic_delivery_details,
        'icon': 'local_shipping',
      },
      {
        'title': localizations.topic_rental_title,
        'subtitle': localizations.topic_rental_subtitle,
        'details': localizations.topic_rental_details,
        'icon': 'attach_money',
      },
      {
        'title': localizations.topic_theft_title,
        'subtitle': localizations.topic_theft_subtitle,
        'details': localizations.topic_theft_details,
        'icon': 'security',
      },
      {
        'title': localizations.topic_violation_title,
        'subtitle': localizations.topic_violation_subtitle,
        'details': localizations.topic_violation_details,
        'icon': 'gavel',
      },
      {
        'title': localizations.topic_insurance_title,
        'subtitle': localizations.topic_insurance_subtitle,
        'details': localizations.topic_insurance_details,
        'icon': 'verified_user',
      },
      {
        'title': localizations.topic_maintenance_title,
        'subtitle': localizations.topic_maintenance_subtitle,
        'details': localizations.topic_maintenance_details,
        'icon': 'build',
      },
      {
        'title': localizations.topic_obligations_title,
        'subtitle': localizations.topic_obligations_subtitle,
        'details': localizations.topic_obligations_details,
        'icon': 'assignment_ind',
      },
      {
        'title': localizations.topic_termination_title,
        'subtitle': localizations.topic_termination_subtitle,
        'details': localizations.topic_termination_details,
        'icon': 'cancel',
      },
      {
        'title': localizations.topic_return_title,
        'subtitle': localizations.topic_return_subtitle,
        'details': localizations.topic_return_details,
        'icon': 'assignment_return',
      },
      {
        'title': localizations.topic_confidentiality_title,
        'subtitle': localizations.topic_confidentiality_subtitle,
        'details': localizations.topic_confidentiality_details,
        'icon': 'lock',
      },
      {
        'title': localizations.topic_indemnity_title,
        'subtitle': localizations.topic_indemnity_subtitle,
        'details': localizations.topic_indemnity_details,
        'icon': 'health_and_safety',
      },
      {
        'title': localizations.topic_misc_title,
        'subtitle': localizations.topic_misc_subtitle,
        'details': localizations.topic_misc_details,
        'icon': 'gavel',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitle,
          style: GoogleFonts.robotoSlab(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String value) {
              Locale newLocale;
              switch (value) {
                case 'en':
                  newLocale = const Locale('en');
                  break;
                case 'hi':
                  newLocale = const Locale('hi');
                  break;
                case 'gu':
                  newLocale = const Locale('gu');
                  break;
                default:
                  newLocale = const Locale('en');
              }
              MyApp.setLocale(context, newLocale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'en', child: Text(localizations.english_text)),
              PopupMenuItem(value: 'hi', child: Text(localizations.hindi_text)),
              PopupMenuItem(value: 'gu', child: Text(localizations.gujarati_text)),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background with frosted glass effect - The BackdropFilter was removed here to prevent the crash
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade100.withOpacity(0.8),
                  Colors.white.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Main content
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white, // semi-transparent card
                child: ExpansionTile(
                  leading: Icon(
                    _getIconData(topic['icon']!),
                    color: _getIconColor(index),
                    size: 28,
                  ),
                  title: Text(
                    topic['title']!,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    topic['subtitle']!,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  trailing: const Icon(Icons.expand_more, color: Colors.blueAccent),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        topic['details']!,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
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
    );
  }

  // Helper to get icon data from string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'info':
        return Icons.info;
      case 'gavel':
        return Icons.gavel;
      case 'handshake':
        return Icons.handshake;
      case 'directions_car':
        return Icons.directions_car;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'attach_money':
        return Icons.attach_money;
      case 'security':
        return Icons.security;
      case 'verified_user':
        return Icons.verified_user;
      case 'build':
        return Icons.build;
      case 'assignment_ind':
        return Icons.assignment_ind;
      case 'cancel':
        return Icons.cancel;
      case 'assignment_return':
        return Icons.assignment_return;
      case 'lock':
        return Icons.lock;
      case 'health_and_safety':
        return Icons.health_and_safety;
      default:
        return Icons.description;
    }
  }

  // Helper to assign colors to icons
  Color _getIconColor(int index) {
    const colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lime,
      Colors.amber,
      Colors.tealAccent,
    ];
    return colors[index % colors.length];
  }
}
