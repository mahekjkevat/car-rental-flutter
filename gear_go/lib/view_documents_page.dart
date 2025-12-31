import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_go/add_update_documents_page.dart';

class ViewDocumentsPage extends StatefulWidget {
  @override
  _ViewDocumentsPageState createState() => _ViewDocumentsPageState();
}

class _ViewDocumentsPageState extends State<ViewDocumentsPage> {
  Map<String, dynamic>? _documentsData;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('personal_documents')
              .doc('verification_status')
              .get();

      setState(() {
        _documentsData = doc.exists ? doc.data() : null;
      });
    } catch (e) {
      print('Error loading documents: $e');
    }

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  // Get verification status
  VerificationStatus get _verificationStatus {
    if (_documentsData == null) return VerificationStatus.notUploaded;

    final adminApproved = _documentsData?['admin_approved'] == true;
    final verificationStatus = _documentsData?['verification_status'];

    if (adminApproved) return VerificationStatus.verified;
    if (verificationStatus == 'rejected') return VerificationStatus.rejected;
    if (verificationStatus == 'pending') return VerificationStatus.pending;

    return VerificationStatus.notUploaded;
  }

  // Document list for easy iteration
  List<DocumentItem> get _documentItems => [
    DocumentItem(
      title: "Driver's License",
      number: _documentsData?['dl_number'],
      verified: _documentsData?['dl_verified'] == true,
      icon: Icons.directions_car,
    ),
    DocumentItem(
      title: "Aadhar Card",
      number: _documentsData?['aadhar_number'],
      verified: _documentsData?['aadhar_verified'] == true,
      icon: Icons.credit_card,
    ),
    DocumentItem(
      title: "PAN Card",
      number: _documentsData?['pan_number'],
      verified: _documentsData?['pan_verified'] == true,
      icon: Icons.business_center,
    ),
  ];

  Widget _buildDocumentCard(DocumentItem doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
        border: Border.all(color: Colors.blue[200]!, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[700],
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.blue[300]!, blurRadius: 8)],
              ),
              child: Icon(doc.icon, color: Colors.white, size: 30),
            ),
            SizedBox(width: 16),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title, style: _titleStyle),
                  SizedBox(height: 6),
                  Text(
                    doc.number ?? 'Not uploaded',
                    style: _subtitleStyle(doc.number != null),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: doc.verified ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      doc.verified ? 'VERIFIED' : 'PENDING',
                      style: _statusTextStyle,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                doc.verified ? Icons.verified : Icons.pending_actions,
                color: doc.verified ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatusCard() {
    final status = _verificationStatus;
    final statusConfig = _verificationStatusConfig[status]!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: statusConfig.gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue[300]!, blurRadius: 15)],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusConfig.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(statusConfig.title, style: _statusTitleStyle),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        statusConfig.description,
                        style: _statusDescriptionStyle,
                      ),
                      SizedBox(height: 16),
                      if (statusConfig.showActionButton)
                        ElevatedButton(
                          onPressed: () => _navigateToAddDocuments(),
                          style: _actionButtonStyle,
                          child: Text(
                            statusConfig.buttonText,
                            style: _buttonTextStyle,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusConfig.largeIcon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    _isRefreshing
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(Icons.refresh, color: Colors.white),
                onPressed: _isRefreshing ? null : _loadDocuments,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.description, size: 50, color: Colors.blue[300]),
      ),
      SizedBox(height: 20),
      Text('No Documents Found', style: _emptyTitleStyle),
      SizedBox(height: 12),
      Text(
        'Upload your documents to start the verification process',
        style: _emptySubtitleStyle,
      ),
      SizedBox(height: 30),
      ElevatedButton(
        onPressed: _navigateToAddDocuments,
        style: _uploadButtonStyle,
        child: Text('Upload Documents', style: _buttonTextStyle),
      ),
    ],
  );

  void _navigateToAddDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUpdateDocumentsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text('Document Verification', style: _appBarTitleStyle),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToAddDocuments,
            tooltip: 'Add Documents',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _documentsData != null ? _buildFAB() : null,
    );
  }

  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.blue[700]),
        SizedBox(height: 20),
        Text('Loading your documents...', style: _loadingTextStyle),
      ],
    ),
  );

  Widget _buildContent() => Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerificationStatusCard(),
        SizedBox(height: 30),
        _buildDocumentsHeader(),
        SizedBox(height: 20),
        Expanded(
          child:
              _documentsData == null
                  ? _buildEmptyState()
                  : _buildDocumentsList(),
        ),
      ],
    ),
  );

  Widget _buildDocumentsHeader() => Row(
    children: [
      Icon(Icons.fact_check, color: Colors.blue[800], size: 24),
      SizedBox(width: 8),
      Text('Your Documents', style: _documentsTitleStyle),
      Spacer(),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_documentsData != null ? _documentItems.length : 0}/${_documentItems.length} Documents',
          style: _documentsCountStyle,
        ),
      ),
    ],
  );

  Widget _buildDocumentsList() =>
      ListView(children: _documentItems.map(_buildDocumentCard).toList());

  Widget _buildFAB() => FloatingActionButton(
    backgroundColor: Colors.blue[700],
    foregroundColor: Colors.white,
    onPressed: _navigateToAddDocuments,
    child: Icon(Icons.edit_document),
    tooltip: 'Update Documents',
  );

  // Styles - Extracted to reduce duplication
  final _titleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.blue[900],
  );
  final _statusTextStyle = GoogleFonts.poppins(
    fontSize: 10,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  final _statusTitleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  final _statusDescriptionStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white.withOpacity(0.9),
    height: 1.4,
  );
  final _appBarTitleStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  final _loadingTextStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.blue[900],
  );
  final _documentsTitleStyle = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.blue[900],
  );
  final _documentsCountStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.blue[800],
    fontWeight: FontWeight.w600,
  );
  final _emptyTitleStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.grey[600],
  );
  final _emptySubtitleStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.grey[500],
  );
  final _buttonTextStyle = GoogleFonts.poppins(fontWeight: FontWeight.w600);

  TextStyle _subtitleStyle(bool hasValue) => GoogleFonts.poppins(
    fontSize: 14,
    color: hasValue ? Colors.grey[700] : Colors.grey[500],
    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
  );

  final _actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.blue[800],
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    elevation: 4,
  );

  final _uploadButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue[700],
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// Enums and Data Classes for better organization
enum VerificationStatus { notUploaded, pending, verified, rejected }

class DocumentItem {
  final String title;
  final String? number;
  final bool verified;
  final IconData icon;

  DocumentItem({
    required this.title,
    required this.number,
    required this.verified,
    required this.icon,
  });
}

class VerificationStatusConfig {
  final String title;
  final String description;
  final String buttonText;
  final IconData icon;
  final IconData largeIcon;
  final List<Color> gradientColors;
  final bool showActionButton;

  VerificationStatusConfig({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.icon,
    required this.largeIcon,
    required this.gradientColors,
    required this.showActionButton,
  });
}

extension on _ViewDocumentsPageState {
  Map<VerificationStatus, VerificationStatusConfig>
  get _verificationStatusConfig => {
    VerificationStatus.notUploaded: VerificationStatusConfig(
      title: 'Document Verification',
      description: 'Complete document verification to start booking cars.',
      buttonText: 'Upload Documents',
      icon: Icons.description,
      largeIcon: Icons.add_circle,
      gradientColors: [Colors.blue[800]!, Colors.blue[600]!],
      showActionButton: true,
    ),
    VerificationStatus.pending: VerificationStatusConfig(
      title: 'Under Review',
      description:
          'Your documents are being reviewed. This usually takes 24-48 hours.',
      buttonText: 'Update Documents',
      icon: Icons.pending_actions,
      largeIcon: Icons.schedule,
      gradientColors: [Colors.orange[800]!, Colors.orange[600]!],
      showActionButton: true,
    ),
    VerificationStatus.verified: VerificationStatusConfig(
      title: 'Verified Successfully',
      description:
          'All your documents have been verified and approved. You can now book cars instantly!',
      buttonText: '',
      icon: Icons.verified_user,
      largeIcon: Icons.check_circle,
      gradientColors: [Colors.green[700]!, Colors.green[500]!],
      showActionButton: false,
    ),
    VerificationStatus.rejected: VerificationStatusConfig(
      title: 'Verification Rejected',
      description:
          'Your documents were rejected. Please update them and submit again.',
      buttonText: 'Update Documents',
      icon: Icons.error_outline,
      largeIcon: Icons.warning,
      gradientColors: [Colors.red[700]!, Colors.red[500]!],
      showActionButton: true,
    ),
  };
}
