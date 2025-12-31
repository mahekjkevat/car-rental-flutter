import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // <-- Add this import

Future<File> createRentalInvoicePdf(
    Map<String, dynamic> bookingData,
    String userId,
    FirebaseFirestore _firestore,
    ) async {
  final pdf = pw.Document();

  // Initialize formatter for currency (with commas and 2 decimals)
  final NumberFormat currencyFormat = NumberFormat('#,##0.00');

  // Load assets
  final logoBytes = await rootBundle.load('assets/images/app_logo_invoice.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final fontBytes = await rootBundle.load('assets/fonts/Roboto.ttf');
  final robotoFont = pw.Font.ttf(fontBytes.buffer.asByteData());

  final fontBoldBytes = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  final robotoFontBold = pw.Font.ttf(fontBoldBytes.buffer.asByteData());

  // Helper functions
  String formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  DateTime getDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now();
  }

  // Fetch CarAdmin data
  final doc = await _firestore.collection('CarAdmin').doc(userId).get();
  final adminData = doc.data() ?? {};
  final adminName = adminData['name'] ?? 'MAHEK KEVAT';
  final adminEmail = adminData['email'] ?? 'mahekjkevat@gmail.com';
  final adminPhone = adminData['phone'] ?? '9537803676';
  final adminLocation = adminData['selectedLocation'] ?? 'Bilimora, India';
  final adminCreatedAt = adminData['createdAt'] != null
      ? (adminData['createdAt'] as Timestamp).toDate()
      : DateTime.parse('2025-04-23T09:52:47.573+05:30');

  // Extract booking data
  final userName = bookingData['userName'] ?? 'User Name';
  final userEmail = bookingData['userEmail'] ?? 'Not provided';
  final userMobile = bookingData['userMobile'] ?? 'Not provided';
  final userAddress = bookingData['userAddress'] ?? 'Not provided';
  final carName = bookingData['carName'] ?? 'Car Name';
  final totalPrice = double.tryParse('${bookingData['totalPrice']}') ?? 0.0;
  final insuranceName = bookingData['subscription'] ?? 'Not Provided';
  final pickUpDateTime = getDateTime(bookingData['pickUpDateTime']);
  final returnDateTime = getDateTime(bookingData['returnDateTime']);
  final bookingTime = getDateTime(bookingData['bookingTime']);
  final invoiceDate = DateTime.now();

  // Generate invoice number
  final random = Random();
  final random5Digits = random.nextInt(100000).toString().padLeft(5, '0');
  final random3Digits = random.nextInt(1000).toString().padLeft(3, '0');
  final invoiceNumber = 'INV2025$random5Digits-$random3Digits';

  // Static info
  const companyName = 'GearGO';
  const companyAddress = 'GearGo ,Near Maliba Campus , Bardoli';
  const companyWebsite = 'www.gear_go.com';

  // Charges
  const double taxRate = 0.05; // 5%


  final otherServicePrice = 0; // set accordingly if any

  final subtotalInr =totalPrice + otherServicePrice;
  final taxesInr = subtotalInr * taxRate;
  final totalChargesInr = subtotalInr + taxesInr;

  // Styles
  final headerStyle = pw.TextStyle(font: robotoFontBold, fontSize: 24, color: PdfColors.blue900);
  final subHeaderStyle = pw.TextStyle(font: robotoFontBold, fontSize: 16, color: PdfColors.blue900, decoration: pw.TextDecoration.underline);
  final normalStyle = pw.TextStyle(font: robotoFont, fontSize: 12, color: PdfColors.black);
  final boldStyle = pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.black);
  final yellowBg = PdfColor.fromInt(0xFFFFD700);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with logo and company info
            pw.Container(
              color: yellowBg,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.ClipOval(
                        child: pw.Image(logoImage, width: 50, height: 50, fit: pw.BoxFit.cover),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(companyName, style: headerStyle),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(companyAddress, style: normalStyle),
                      pw.Text(adminEmail, style: normalStyle),
                      pw.Text(adminPhone, style: normalStyle),
                      pw.Text(companyWebsite, style: normalStyle),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Bill To and Invoice Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILL TO', style: subHeaderStyle),
                    pw.SizedBox(height: 5),
                    pw.Text('Name: $userName', style: normalStyle),
                  //  pw.Text('Address: $userAddress', style: normalStyle),
                    pw.Text('Email: $userEmail', style: normalStyle),
                    pw.Text('Phone: $userMobile', style: normalStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: subHeaderStyle),
                    pw.SizedBox(height: 5),
                    pw.Text('Invoice Number: $invoiceNumber', style: normalStyle),
                    pw.Text('Invoice Date: ${formatDate(invoiceDate)}', style: normalStyle),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Vehicle Information
            pw.Text('VEHICLE INFORMATION', style: subHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text('Car Model: $carName', style: normalStyle),
            pw.Text('Rental Period: ${formatDate(pickUpDateTime)} - ${formatDate(returnDateTime)}', style: normalStyle),
            pw.SizedBox(height: 10),

            // Charges Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.blue900),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Description', style: pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.white)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Total Price', style: pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.white)),
                    ),
                  ],
                ),
                // Car Rental
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: yellowBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Car Rental', style: normalStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('₹${currencyFormat.format(totalPrice)}', style: normalStyle),
                    ),
                  ],
                ),
                // Insurance
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: yellowBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Insurance', style: normalStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('$insuranceName', style: normalStyle),
                    ),
                  ],
                ),
                // Other Service
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: yellowBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Other Service', style: normalStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('₹${currencyFormat.format(otherServicePrice)}', style: normalStyle),
                    ),
                  ],
                ),
                // Taxes (5%)
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('TAXES (5%)', style: pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.white)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${currencyFormat.format(taxesInr)}', style: pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.white)),
                    ),
                  ],
                ),
                // Total Charges
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('TOTAL CHARGES', style: pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.white)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${currencyFormat.format(totalChargesInr)} /- INR', style: pw.TextStyle(font: robotoFontBold, fontSize: 12, color: PdfColors.white)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Payment Info
            pw.Text('PAYMENT INFORMATION', style: subHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text('Payment Due Date: ${formatDate(bookingTime)}', style: normalStyle),
            pw.Text('Payment Method: RazorPay', style: normalStyle),
            pw.Text('Account Name: $userName', style: normalStyle),
            pw.Text('Date: ${formatDate(invoiceDate)}', style: normalStyle),
            pw.SizedBox(height: 20),

            // Notes
            pw.Text('NOTES', style: subHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text(
              'Thank you for choosing GearGO Rental for your car rental needs. If you have any questions regarding this invoice or need further assistance, please don’t hesitate to contact us at $adminPhone or $adminEmail.',
              style: normalStyle,
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.Text('$adminName\nAuthorized Sign', style: normalStyle),
              ],
            ),
            pw.SizedBox(height: 20),

            // Admin info
            pw.Text('CAR RENTAL ADMIN INFORMATION', style: subHeaderStyle),
            pw.SizedBox(height: 5),
            pw.Text('Name: $adminName', style: normalStyle),
            pw.Text('Email: $adminEmail', style: normalStyle),
            pw.Text('Phone: $adminPhone', style: normalStyle),
            pw.Text('Location: $adminLocation', style: normalStyle),
            pw.Text('Created At: ${adminCreatedAt.day}/${adminCreatedAt.month}/${adminCreatedAt.year} at ${adminCreatedAt.hour}:${adminCreatedAt.minute}:${adminCreatedAt.second} UTC+5:30', style: normalStyle),
          ],
        );
      },
    ),
  );

  final outputDir = await getApplicationDocumentsDirectory();
  final file = File('${outputDir.path}/RentalInvoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}