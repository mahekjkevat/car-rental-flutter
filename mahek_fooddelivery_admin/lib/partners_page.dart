// file: lib/partners_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'partner_model.dart';
import 'partner_details_page.dart';

// --- Theme Colors and Constants ---
final Color primaryAppColor = const Color(0xFFF96D0A);
final Color secondaryDarkColor = const Color(0xFF333333);
final Color lightBackgroundColor = const Color(0xFFF0F4F8);

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Partner> _allPartners = [];
  List<Partner> _filteredPartners = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPartners);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPartners);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPartners() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredPartners = _allPartners.where((partner) {
        return partner.name.toLowerCase().contains(searchTerm) ||
            partner.email.toLowerCase().contains(searchTerm) ||
            partner.mobileNumber.contains(searchTerm) ||
            partner.city.toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  Stream<List<Partner>> _streamPartners() {
    return FirebaseFirestore.instance
        .collection('partners')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Partner.fromFirestore(doc)).toList(),
        );
  }

  void _navigateToPartnerDetails(Partner partner, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerDetailsPage(partner: partner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<Partner>>(
            stream: _streamPartners(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                );
              }

              final streamedPartners = snapshot.data ?? [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_allPartners.length != streamedPartners.length) {
                  setState(() {
                    _allPartners = streamedPartners;
                    _filterPartners();
                  });
                }
              });

              final partnersToDisplay = _searchController.text.isEmpty
                  ? _allPartners
                  : _filteredPartners;

              if (partnersToDisplay.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  Expanded(child: _buildPartnerGrid(partnersToDisplay)),
                  _buildFooter(partnersToDisplay.length),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'All Partners',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: secondaryDarkColor,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _exportPartners(
                  context,
                  _filteredPartners.isEmpty ? _allPartners : _filteredPartners,
                ),
                icon: const Icon(Icons.download),
                label: Text(
                  'Export PDF',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAppColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Viewing all delivery partners across all cities.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search partners by name, email, phone or city...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerGrid(List<Partner> partners) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 3.2 / 1, // Even more vertical space
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: partners.length,
        itemBuilder: (context, index) => _buildPartnerCard(partners[index]),
      ),
    );
  }

  Widget _buildPartnerCard(Partner partner) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _navigateToPartnerDetails(partner, context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Name + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partner.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(partner),
                ],
              ),
              const SizedBox(height: 4),

              // Contact Info - Single line
              Row(
                children: [
                  Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    partner.mobileNumber,
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.location_city,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    partner.city,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: primaryAppColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 5),

              // Bottom Row: Stats + Actions
              Row(
                children: [
                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(
                          'Orders',
                          partner.ordersCompleted.toString(),
                        ),
                        _buildMiniStat(
                          'Approved',
                          partner.isApproved ? '✓' : '✗',
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: lightBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove_red_eye, size: 14),
                      onPressed: () =>
                          _navigateToPartnerDetails(partner, context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.red,
                      ),
                      onPressed: () => _showDeleteConfirmation(partner),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primaryAppColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatusChip(Partner partner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: partner.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        partner.statusText,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: partner.statusColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            _searchController.text.isNotEmpty
                ? 'No partners match "${_searchController.text}"'
                : 'No Partners found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Partners: $count',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: lightBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Showing $count entries',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Partner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Partner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete ${partner.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePartner(partner);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deletePartner(Partner partner) {
    FirebaseFirestore.instance
        .collection('partners')
        .doc(partner.id)
        .delete()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${partner.name} deleted successfully')),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        });
  }

  // PDF Export
  Future<void> _exportPartners(
    BuildContext context,
    List<Partner> partners,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating PDF for ${partners.length} partners...'),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewPage(
          generatePdf: (format) => _generatePartnersPdf(partners),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePartnersPdf(List<Partner> partners) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final primaryColor = PdfColor.fromHex(
      primaryAppColor.value.toRadixString(16).substring(2),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'All Delivery Partners Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: fontBold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 12, font: font),
            ),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 20),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1),
              },
              children: [
                _buildPdfHeaderRow([
                  'Name',
                  'Email',
                  'City',
                  'Status',
                  'Orders',
                ], fontBold),
                ...partners
                    .map(
                      (partner) => pw.TableRow(
                        children: [
                          _buildPdfCell(partner.name, font),
                          _buildPdfCell(partner.email, font),
                          _buildPdfCell(partner.city, font),
                          _buildPdfCell(
                            partner.statusText,
                            fontBold,
                            _getStatusColor(partner.status),
                          ),
                          _buildPdfCell(
                            partner.ordersCompleted.toString(),
                            fontBold,
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Partners: ${partners.length}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: fontBold,
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.TableRow _buildPdfHeaderRow(List<String> headers, pw.Font fontBold) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: headers
          .map((header) => _buildPdfCell(header, fontBold, PdfColors.black))
          .toList(),
    );
  }

  pw.Widget _buildPdfCell(String text, pw.Font font, [PdfColor? color]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, color: color, font: font),
      ),
    );
  }

  PdfColor _getStatusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.available:
        return PdfColors.green700;
      case DriverStatus.receiving:
        return PdfColors.blue700;
      case DriverStatus.outForDelivery:
        return PdfColor.fromHex(
          primaryAppColor.value.toRadixString(16).substring(2),
        );
      case DriverStatus.offline:
        return PdfColors.red700;
    }
  }
}

class PdfPreviewPage extends StatelessWidget {
  final Future<Uint8List> Function(PdfPageFormat) generatePdf;

  const PdfPreviewPage({super.key, required this.generatePdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partners Report', style: GoogleFonts.poppins()),
        backgroundColor: primaryAppColor,
      ),
      body: PdfPreview(
        build: generatePdf,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
