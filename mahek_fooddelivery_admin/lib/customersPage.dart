import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show Uint8List;
// Imports for PDF generation and viewing/downloading
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'admin_complaints.dart';
import 'customer_models.dart';

// --- NEW IMPORT ---
import 'customer_details_page.dart';
import 'informtoUserForeNews.dart';
// ------------------

// --- Theme Colors for PDF Styling ---
// NOTE: These are defined here for the PDF generation function
// and must be used without the '#' prefix for PdfColor.fromHex.
const String primaryAppColorHex = 'F96D0A'; // Vibrant Orange/Red
const String secondaryDarkColorHex = '333333'; // Dark background/text

// --- Data Structure aligned with Firestore user collection ---


// --- Main Widget ---

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);

  // --- NEW: Search State ---
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Update the state with the current search query
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }
  // --- END Search State ---

  Stream<List<AppUser>> get _fetchUsersStream {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppUser.fromFirestore).toList());
  }

  // --- NEW: App Bar with Search and PDF Button ---
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: primaryAppColor,
      foregroundColor: Colors.white,
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search name or email...',
          border: InputBorder.none,
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
        ),
        style: GoogleFonts.poppins(color: Colors.white),
        cursorColor: Colors.white,
      )
          : Text('Customers', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      actions: [
        // 1. Search Icon - Toggles the search input field
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (_isSearching) {
                _searchController.clear();
                _searchQuery = '';
              }
              _isSearching = !_isSearching;
            });
          },
        ),
        // 2. PDF Icon - Triggers the PDF Options Dialog
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: () => _showPdfOptionsDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  // --- END App Bar ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<AppUser>>(
        stream: _fetchUsersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allUsers = snapshot.data ?? [];

          // --- APPLY Search Filter ---
          final filteredUsers = allUsers.where((user) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery;
            final nameLower = user.name.toLowerCase();
            final emailLower = user.email.toLowerCase();
            return nameLower.contains(query) || emailLower.contains(query);
          }).toList();
          // --- END Search Filter ---


          if (filteredUsers.isEmpty && _searchQuery.isEmpty) {
            return Center(
              child: Text(
                'No customer data found.',
                style: GoogleFonts.poppins(fontSize: 18, color: secondaryDarkColor.withOpacity(0.6)),
              ),
            );
          }

          if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Text(
                'No results found for "${_searchController.text}"',
                style: GoogleFonts.poppins(fontSize: 18, color: secondaryDarkColor.withOpacity(0.6)),
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              return _buildUserListTile(context, filteredUsers[index]);
            },
          );
        },
      ),
      // Floating Action Button for News Blast
      floatingActionButton: FloatingActionButton( // <--- ADD THIS BLOCK
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InformToUserForNewsPage(),
            ),
          );
        },
        backgroundColor: primaryAppColor,
        tooltip: 'Send News Blast',
        child: const Icon(Icons.campaign, color: Colors.white),
      ),
    );
  }
  }

  // --- MODIFIED: Added onTap to navigate to CustomerDetailsPage ---
  Widget _buildUserListTile(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        onTap: () {
          // Navigate to the new CustomerDetailsPage, passing the user object
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDetailsPage(user: user),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: primaryAppColor.withOpacity(0.1),
          child: Icon(Icons.person, color: primaryAppColor),
        ),
        title: Text(
          user.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: secondaryDarkColor, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
            Text(user.phone, style: GoogleFonts.poppins(fontSize: 13, color: secondaryDarkColor)),
            const SizedBox(height: 4),
            Text(
              'Joined: ${DateFormat('dd MMM yyyy').format(user.createdAt)}',
              style: GoogleFonts.poppins(fontSize: 12, color: primaryAppColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$value action for ${user.name}')),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'View Details', child: Text('View Details')),
            const PopupMenuItem(value: 'Send Promo', child: Text('Send Promo')),
            const PopupMenuItem(value: 'Delete User', child: Text('Delete User', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  // --- PDF Dialog and Actions (Unchanged) ---

  // Dialog to choose between preview and download/share
  Future<void> _showPdfOptionsDialog(BuildContext context) async {
    // Show loading message while fetching data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fetching latest customer data for PDF generation...')),
    );
    // 1. Fetch current user data
    final allUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final allUsers = allUsersSnapshot.docs.map(AppUser.fromFirestore).toList();

    // 2. Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Customer Report Options', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('What would you like to do with the generated Customer Report?', style: GoogleFonts.poppins()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              child: Text('Preview PDF', style: GoogleFonts.poppins(color: primaryAppColor, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _previewPdf(context, allUsers);
              },
            ),
            TextButton(
              child: Text('Download/Share PDF', style: GoogleFonts.poppins(color: secondaryDarkColor, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _downloadPdf(context, allUsers);
              },
            ),
          ],
        );
      },
    );
  }

  // Action 1: Opens the in-app PDF viewer
  Future<void> _previewPdf(BuildContext context, List<AppUser> users) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generating PDF Preview...')),
      );
      // layoutPdf is used for showing the preview/print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _generateCustomerPdfBytes(users),
        name: 'customer_report.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF preview. See console for details.')),
      );
      print('PDF Preview Error: $e');
    }
  }

  // Action 2: Triggers the system's share/save dialogue
  Future<void> _downloadPdf(BuildContext context, List<AppUser> users) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generating PDF for Download/Share...')),
      );
      final bytes = await _generateCustomerPdfBytes(users);
      // sharePdf triggers the native share sheet (which usually includes save/download options)
      await Printing.sharePdf(bytes: bytes, filename: 'customer_report.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report generated and system dialogue opened.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF for download. See console for details.')),
      );
      print('PDF Download Error: $e');
    }
  }

  // --- PDF GENERATION LOGIC (Returns raw bytes) ---
  Future<Uint8List> _generateCustomerPdfBytes(List<AppUser> users) async {
    final doc = pw.Document();

    // Load custom fonts for the PDF
    final poppins = await PdfGoogleFonts.poppinsRegular();
    final poppinsBold = await PdfGoogleFonts.poppinsBold();

    final primaryPdfColor = PdfColor.fromHex(primaryAppColorHex);
    final secondaryPdfColor = PdfColor.fromHex(secondaryDarkColorHex);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(
                  'Customer Database Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryPdfColor,
                    font: poppinsBold,
                  ),
                ),
              ),

              // Table Title
              pw.Text(
                'List of Registered Customers',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: secondaryPdfColor,
                  font: poppinsBold,
                ),
              ),
              pw.SizedBox(height: 15),

              // Customer Table
              pw.Expanded(
                child: pw.Table.fromTextArray(
                  headers: ['Name', 'Email', 'Phone', 'Joined On'],
                  data: users.map((user) => [
                    user.name,
                    user.email,
                    user.phone,
                    DateFormat('dd MMM yyyy').format(user.createdAt),
                  ]).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: poppinsBold,
                  ),
                  cellStyle: pw.TextStyle(
                    fontSize: 10,
                    font: poppins,
                    color: secondaryPdfColor,
                  ),
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  headerDecoration: pw.BoxDecoration(color: primaryPdfColor),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2), // Name
                    1: const pw.FlexColumnWidth(3), // Email
                    2: const pw.FlexColumnWidth(2), // Phone
                    3: const pw.FlexColumnWidth(1.5), // Joined On
                  },
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                  },
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Text(
                'Total Customers: ${users.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: poppinsBold),
              ),

              // Bottom Signature
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '— Report Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    font: poppins,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
