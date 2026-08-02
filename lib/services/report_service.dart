import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  static Future<void> generateAndDownloadReport(BuildContext context) async {
    // Tunjukkan dialog kemajuan penjanaan PDF
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Exporting Performance Report',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            Text(
              'Generating analytics data & compiling PDF report...',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // 1. Ambil data projek, tugas, dan pengguna dari Firestore
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
        final String name = data['projectName'] ?? data['title'] ?? 'Unnamed Node';
        final String client = data['client'] ?? 'Internal';
        final String status = data['status'] ?? 'Active';
        final String budgetStr = (data['budget'] ?? '0').toString();
        final double budgetVal = double.tryParse(budgetStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        totalBudget += budgetVal;

        if (status.toLowerCase() == 'completed') {
          completedCount++;
        } else {
          activeCount++;
        }

        final String progress = (data['progress'] ?? '0').toString();
        projectRows.add([
          name,
          client,
          status,
          '$progress%',
          'RM ${budgetVal.toStringAsFixed(2)}',
        ]);
      }

      // 2. Bina Dokumen PDF
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Tajuk Utama (Header)
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
                        'Global Asset & Performance Audit Report',
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
                        'Total Nodes: $totalCount',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.indigo200, thickness: 1.5),
              pw.SizedBox(height: 16),

              // Kad Ringkasan Eksekutif
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
                    _buildStatItem('Total Assets', '$totalCount'),
                    _buildStatItem('Active Nodes', '$activeCount'),
                    _buildStatItem('Completed', '$completedCount'),
                    _buildStatItem('Total Tasks', '${tasks.length}'),
                    _buildStatItem('Est. Budget', 'RM ${totalBudget.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Seksyen Jadual Projek
              pw.Text(
                'Project Portfolio Breakdown',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 12),

              if (projectRows.isEmpty)
                pw.Paragraph(text: 'No projects registered in the system.')
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Project Name', 'Client / Dept', 'Status', 'Progress', 'Budget'],
                  data: projectRows,
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  cellAlignment: pw.Alignment.centerLeft,
                ),

              pw.SizedBox(height: 30),

              // Catatan Pengesahan Laporan
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated by Uni-X Automated System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Confidential - Internal Management Only', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      if (!context.mounted) return;
      Navigator.pop(context);

      if (kIsWeb) {
        // Untuk Web: cetak atau muat turun fail melalui pelayar
        await Printing.sharePdf(bytes: bytes, filename: 'UniX_Performance_Report.pdf');
      } else {
        // Untuk Mobile / Desktop: Simpan fail ke storan tempatan dan buka fail
        final outputDir = await getApplicationDocumentsDirectory();
        final file = File('${outputDir.path}/UniX_Performance_Report.pdf');
        await file.writeAsBytes(bytes);

        // Buka fail PDF secara automatik
        await OpenFilex.open(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Report saved & generated: ${file.path}',
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
      Navigator.pop(context);
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
