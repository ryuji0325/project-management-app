// lib/task_detail_page.dart (Premium Glassmorphic Inspector Edition)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengimport tokens & GlassContainer global dari main.dart
import 'widgets/app_background.dart';

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> taskData;

  const TaskDetailPage({super.key, required this.taskData});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  bool _loading = false;
  late bool _taskCompleted;

  @override
  void initState() {
    super.initState();
    _taskCompleted = widget.taskData['status'] == 'Completed';
  }

  Future<void> _markTaskAsCompleted() async {
    final taskId = widget.taskData['id'];
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Task ID parameter is untracked.'))
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Update Firestore status
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': 'Completed',
      });

      // 2. Fetch assigner user data (email)
      final fromUid = widget.taskData['from'];
      String? assignerEmail;
      String assignerName = 'Supervisor';

      if (fromUid != null) {
        final assignerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(fromUid)
            .get();
        if (assignerDoc.exists && assignerDoc.data() != null) {
          assignerEmail = assignerDoc.data()!['email'];
          assignerName = assignerDoc.data()!['username'] ??
              assignerDoc.data()!['displayName'] ??
              'Supervisor';
        }
      }

      // 3. Dispatch communication notification email via EmailJS API
      if (assignerEmail != null && assignerEmail.isNotEmpty) {
        const serviceId = 'service_nyayehc';
        const templateId = 'template_pw0fk2c';
        const publicKey = 'mkFa5b_jI4Xv1k-Qf';

        final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
        final currentUser = FirebaseAuth.instance.currentUser;
        final executorName = currentUser?.displayName ??
            currentUser?.email?.split('@')[0] ??
            'Operator';
        final executorEmail = currentUser?.email ?? 'noreply.unixpm@gmail.com';

        final taskDesc = widget.taskData['task'] ?? 'Task Operation';

        try {
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': publicKey,
              'template_params': {
                'email': assignerEmail,
                'to_name': assignerName,
                'from_name': executorName,
                'from_email': executorEmail,
                'task_desc': 'COMPLETED: $taskDesc',
              }
            }),
          );
        } catch (e) {
          debugPrint('EmailJS notification dispatch failure: $e');
        }

        // Prefilled mailto fallsafe launcher
        try {
          final emailUri = Uri(
            scheme: 'mailto',
            path: assignerEmail,
            queryParameters: {
              'subject': 'Uni-X Task Completed: $taskDesc',
              'body': 'Hi $assignerName,\n\nI have completed the task: "$taskDesc".\n\nBest regards,\n$executorName',
            },
          );
          if (await canLaunchUrl(emailUri)) {
            await launchUrl(emailUri);
          }
        } catch (e) {
          debugPrint('Mailto client launch failure: $e');
        }
      }

      setState(() {
        _taskCompleted = true;
        widget.taskData['status'] = 'Completed';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task marked completed & notification email dispatched!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF0C2B23),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task status: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.taskData;
    final bool isCompleted = _taskCompleted;
    final String status = isCompleted ? 'Completed' : (data['status'] ?? 'Pending');
    final Color statusColor = isCompleted ? kAccentColor : Colors.amber;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Mengekalkan reka bentuk ambient fluid background dari Root Wrapper
        appBar: AppBar(
          title: Text(
            'Instance Inspector', 
            style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.5)
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: kTextPrimary, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                children: [
                  // MAIN DATA CONSOLE CARD
                  GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: HEADER & DESCRIPTION TITLE
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                              ),
                              child: Icon(Icons.terminal_rounded, color: statusColor, size: 26),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "NODE OPERATION TASK", 
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: kAccentColor, letterSpacing: 1.5)
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    data['task'] ?? 'Unspecified Operations',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPrimary, height: 1.3, letterSpacing: -0.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Divider(color: kCardGlassBorder.withValues(alpha: 0.4), thickness: 1),
                        ),
  
                        // SECTION 2: STRUCTURAL INFRASTRUCTURE DETAILS
                        _buildHighFidelityDetailRow(Icons.account_tree_outlined, "Origin Operator", data['fromName'] ?? data['from'] ?? 'System Core'),
                        const SizedBox(height: 18),
                        _buildHighFidelityDetailRow(Icons.person_pin_rounded, "Target Allocation", data['toName'] ?? data['to'] ?? 'Cluster User'),
                        const SizedBox(height: 18),
                        _buildHighFidelityDetailRow(Icons.query_builder_rounded, "Deployment Timestamp", _formatDate(data['createdAt'])),
                        const SizedBox(height: 18),
                        
                        // Status Parameter Row with Integrated Premium Glow Pill Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), shape: BoxShape.circle),
                              child: Icon(Icons.shield_outlined, size: 18, color: kTextSecondary.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Pipeline Status", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6, height: 6, 
                                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              status.toString().toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11, 
                                                fontWeight: FontWeight.w800, 
                                                color: statusColor, 
                                                letterSpacing: 0.5
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
  
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Divider(color: kCardGlassBorder.withValues(alpha: 0.4), thickness: 1),
                        ),
  
                        // SECTION 3: TASK STATUS OPERATIONS
                        Text(
                          "Task Status Operations", 
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: kTextPrimary, letterSpacing: -0.2)
                        ),
                        const SizedBox(height: 14),
                        
                        if (_taskCompleted)
                          GlassContainer(
                            borderRadius: 16,
                            fillColor: kAccentColor.withValues(alpha: 0.08),
                            borderColor: kAccentColor.withValues(alpha: 0.25),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 20, color: kAccentColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Task execution fully verified & closed.", 
                                    style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontWeight: FontWeight.w700, fontSize: 13)
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _markTaskAsCompleted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccentColor,
                                foregroundColor: kBackgroundColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: Text(
                                _loading ? "Processing..." : "Mark as Completed",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // BACK BUTTON CONTROLLER
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kCardGlassBorder, width: 1.2),
                        foregroundColor: kTextPrimary,
                        backgroundColor: Colors.white.withValues(alpha: 0.02),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "Return to Console", 
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.1)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- REUSABLE HIGH-FIDELITY DATA ROW COMPONENT ---
  Widget _buildHighFidelityDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            shape: BoxShape.circle
          ),
          child: Icon(icon, size: 18, color: kTextSecondary.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 2),
              Text(
                value, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary)
              ),
            ],
          ),
        ),
      ],
    );
  }
}