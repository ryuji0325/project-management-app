// lib/assign_task_page.dart (Premium Glassmorphic Task Provisioner Console)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global
import 'services/database_service.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});
  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController taskCtrl = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  String? selectedUserId;
  String? selectedUserName;
  String? selectedUserEmail;
  List<Map<String, dynamic>> userList = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    taskCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await _dbService.fetchAllUsers();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final filteredUsers = users.where((u) => u['uid'] != currentUserId).toList();
    if (mounted) setState(() => userList = filteredUsers);
  }

  // --- LOGIK API: DISPATCH EMAIL VIA EMAILJS NETWORK ---
  Future<void> _sendEmailNotification(
      String toEmail, String toName, String taskDesc) async {
    const serviceId = 'service_nyayehc';
    const templateId = 'template_pw0fk2c';
    const publicKey = 'mkFa5b_jI4Xv1k-Qf';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final currentUser = FirebaseAuth.instance.currentUser;
    final fromName = currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        'Admin';
    final fromEmail = currentUser?.email ?? 'noreply.unixpm@gmail.com';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': toEmail,
            'to_name': toName,
            'from_name': fromName,
            'from_email': fromEmail,
            'task_desc': taskDesc,
          }
        }),
      );
      debugPrint('EmailJS Network Transmission Response: ${response.body}');
    } catch (e) {
      debugPrint('Error dispatching communication packet: $e');
    }
  }

  // --- TRANSACTION TRIGER: EXECUTING DATABASE ASSIGNMENT ---
  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target node authorization required: Please select staff.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    String fileUrl = "";

    String fromName = currentUser?.email ?? 'Unknown';
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          fromName = userDoc.data()!['username'] ??
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Unknown';
        }
      } catch (_) {}
    }

    try {
      // Menjana kemasukan tugasan ke dalam Cloud Firestore Cluster
      await FirebaseFirestore.instance.collection('tasks').add({
        'from': currentUser?.uid,
        'fromName': fromName,
        'to': selectedUserId,
        'toName': selectedUserName,
        'task': taskCtrl.text.trim(),
        'fileName': "",
        'fileUrl': fileUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      if (selectedUserEmail != null && selectedUserEmail!.isNotEmpty) {
        _sendEmailNotification(
          selectedUserEmail!,
          selectedUserName ?? 'Staff',
          taskCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task instance mapped and assigned successfully!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF0C2B23),
          ),
        );

        taskCtrl.clear();
        setState(() {
          selectedUserId = null;
          selectedUserName = null;
          selectedUserEmail = null;
        });
      }
    } catch (e) {
      debugPrint("❌ Database transaction failure: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to provision assignment node: $e', style: GoogleFonts.plusJakartaSans())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk memelihara fluid backdrop canvas shell parent utama
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. APPMANIFEST ENGINE LABEL
                  Text(
                    'RESOURCE COMMAND',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: kAccentColor, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Assign Operation Task',
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 24),

                  // 2. MAIN CORE FORM GLASSMORPHIC CONTAINER BLOCK
                  GlassContainer(
                    borderRadius: 26,
                    padding: EdgeInsets.zero, // Padding kosong supaya top gradient rapat ke sempadan border kaca
                    child: Column(
                      children: [
                        // High-Fidelity Multi-Tone Accent Top Border Bar
                        Container(
                          height: 4,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF3B82F6), kAccentColor, Color(0xFF7C3AED)]),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionHeader(Icons.hub_rounded, 'Operational Node Allocation'),
                                const SizedBox(height: 20),

                                // FIELD COMPONENT A: TARGET USER SELECT DROPDOWN DROPDOWN
                                _buildInputLabel("Target Allocation Pool (Staff)"),
                                _buildFormWrapper(
                                  child: Theme(
                                    data: Theme.of(context).copyWith(canvasColor: const Color(0xFF0F1626)),
                                    child: DropdownButtonFormField<String>(
                                      value: selectedUserId,
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF0F1626),
                                      style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                      decoration: const InputDecoration(
                                        hintText: "Select team member handle",
                                        hintStyle: TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                        prefixIcon: Icon(Icons.person_pin_rounded, size: 18),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      ),
                                      items: userList
                                          .map((u) => DropdownMenuItem(
                                                value: u['uid'] as String,
                                                child: Text(u['username'] ?? u['displayName'] ?? 'Unknown Node Handle'),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        final user = userList.firstWhere((u) => u['uid'] == val);
                                        setState(() {
                                          selectedUserId = val;
                                          selectedUserName = user['username'] ?? user['displayName'];
                                          selectedUserEmail = user['email'];
                                        });
                                      },
                                      validator: (v) => v == null ? 'Allocation pointer target missing' : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // FIELD COMPONENT B: TASK MANIFEST MEMO DETAIL INPUT
                                _buildInputLabel("Task Operation Manifest (Description)"),
                                _buildFormWrapper(
                                  child: TextFormField(
                                    controller: taskCtrl,
                                    maxLines: 3,
                                    style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      hintText: 'Describe core objective parameters and deadlines...',
                                      hintStyle: TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                      prefixIcon: Icon(Icons.terminal_rounded, size: 18),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Task deployment instruction description mandatory' : null,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // SUBMIT FORM BROADCAST BUTTON TRIGGER
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submitTask,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20, width: 20,
                                            child: CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.assignment_turned_in_rounded, size: 18),
                                              const SizedBox(width: 10),
                                              Text('Deploy Task Cluster', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // --- REUSABLE MODULES HELPERS SYSTEM ---

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAccentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAccentColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: kAccentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String labelText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        labelText.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFormWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}