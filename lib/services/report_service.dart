import 'dart:io';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  static Future<void> generateAndDownloadReport(BuildContext context) async {
    // Progress notification toast (does not affect Navigator stack)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
            ),
            const SizedBox(width: 14),
            Text(
              'Compiling Executive Portfolio & Financial Report...',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF131B2E),
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      // 1. Fetch project and task data from Firestore
      final projectsSnap = await FirebaseFirestore.instance.collection('projects').get();
      final tasksSnap = await FirebaseFirestore.instance.collection('tasks').get();

      final projects = projectsSnap.docs;
      final tasks = tasksSnap.docs;

      int totalCount = projects.length;
      int activeCount = 0;
      int completedCount = 0;
      double totalBudget = 0.0;

      final List<List<String>> projectRows = [];

      for (var doc in projects) {
        final data = doc.data();
        final String name = data['projectName'] ?? data['title'] ?? 'Unnamed Project';
        final String client = data['client'] ?? 'Internal Department';
        final String status = data['status'] ?? 'Active';
        final String budgetStr = (data['budget'] ?? '0').toString();
        final double budgetVal = double.tryParse(budgetStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        totalBudget += budgetVal;

        if (status.toLowerCase() == 'completed') {
          completedCount++;
        } else {
          activeCount++;
        }

        String createdDate = 'N/A';
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          createdDate = DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate());
        }

        projectRows.add([
          name,
          client,
          status.toUpperCase(),
          'RM ${budgetVal.toStringAsFixed(2)}',
          createdDate,
        ]);
      }

      // 2. Build PDF Document
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'UNI-X PROJECT MANAGEMENT',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Executive Portfolio & Financial Allocation Audit Report',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: $formattedDate',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Total Projects: $totalCount',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.indigo200, thickness: 1.5),
              pw.SizedBox(height: 16),

              // Executive Summary Card
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.indigo200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Projects', '$totalCount'),
                    _buildStatItem('Active', '$activeCount'),
                    _buildStatItem('Completed', '$completedCount'),
                    _buildStatItem('Total Tasks', '${tasks.length}'),
                    _buildStatItem('Allocated Capital', 'RM ${totalBudget.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Table Section
              pw.Text(
                'Financial Allocation & Project Inventory',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 12),

              if (projectRows.isEmpty)
                pw.Paragraph(text: 'No projects registered in the system portfolio.')
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Project Name', 'Client / Dept', 'Status', 'Allocated Budget', 'Registered Date'],
                  data: projectRows,
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  cellAlignment: pw.Alignment.centerLeft,
                ),

              pw.SizedBox(height: 30),

              // Verification Note
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated by Uni-X Automated Governance Engine', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Confidential - Executive Management Only', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        // Web: Download PDF file directly via HTML Blob
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "UniX_Executive_Portfolio_Report.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Executive portfolio report downloaded successfully!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF0C2B23),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Mobile / Desktop: Save to local directory & open file
        final outputDir = await getApplicationDocumentsDirectory();
        final file = File('${outputDir.path}/UniX_Executive_Portfolio_Report.pdf');
        await file.writeAsBytes(bytes);

        await OpenFilex.open(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Executive report saved: ${file.path}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF0C2B23),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: const Color(0xFF00E5FF),
              onPressed: () {
                OpenFilex.open(file.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to generate report: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  static pw.Widget _buildStatItem(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          title.toUpperCase(),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
        ),
      ],
    );
  }
}
