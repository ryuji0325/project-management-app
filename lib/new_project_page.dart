// lib/new_project_page.dart (Premium Glassmorphic Project Provisioner)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});
  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _driveCtrl = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _budgetCtrl.dispose();
    _driveCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.now() : (_start ?? DateTime.now()),
      firstDate: isStart ? DateTime(2000) : (_start ?? DateTime(2000)),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccentColor,
              onPrimary: kBackgroundColor,
              surface: Color(0xFF0F1626),
              onSurface: kTextPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF0F1626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: kCardGlassBorder)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Chronology parameters required: Please select start and end dates.", style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Chronological breach: End date cannot be earlier than start date.", style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('projects').add({
        'projectName': _nameCtrl.text.trim(),
        'client': _clientCtrl.text.trim(),
        'budget': double.tryParse(_budgetCtrl.text) ?? 0.0,
        'driveUrl': _driveCtrl.text.trim(),
        'startDate': Timestamp.fromDate(_start!),
        'endDate': Timestamp.fromDate(_end!),
        'createdBy': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'vendors': [],
        'orgChart': {'manager': null, 'leader': null, 'operation': []},
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ New project instance initialized into Firestore Cluster!", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF0C2B23),
          ),
        );
        _nameCtrl.clear();
        _clientCtrl.clear();
        _budgetCtrl.clear();
        _driveCtrl.clear();
        setState(() {
          _start = null;
          _end = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pipeline Transaction Failure: $e", style: GoogleFonts.plusJakartaSans())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk memelihara fluid canvas parent shell utama
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER SECTION
                  Text(
                    'PROVISIONING ENGINE',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: kAccentColor, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'New Project Manifest',
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 24),

                  // 2. MAIN CORE GLASS FORM CARD
                  GlassContainer(
                    borderRadius: 26,
                    padding: EdgeInsets.zero, // Padding dikosongkan supaya top gradient rapat ke border
                    child: Column(
                      children: [
                        // High-Fidelity Accent Top Glowing Bar
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
                                // SECTION A: PROJECT IDENTITY DETAILS
                                _sectionHeader(Icons.folder_open_rounded, 'Project Identity Configuration'),
                                const SizedBox(height: 20),
                                
                                _buildFieldLabel("Project Name"),
                                _buildField(
                                  controller: _nameCtrl,
                                  hintText: 'e.g. Infrastructure Core Overhaul',
                                  icon: Icons.token_rounded,
                                  validator: (v) => v!.isEmpty ? 'Project identifier mandatory' : null,
                                ),
                                const SizedBox(height: 16),
                                
                                _buildFieldLabel("Client"),
                                _buildField(
                                  controller: _clientCtrl,
                                  hintText: 'e.g. Apex Corporation',
                                  icon: Icons.business_center_rounded,
                                  validator: (v) => v!.isEmpty ? 'Client routing handle required' : null,
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Allocated Budget"),
                                          _buildField(
                                            controller: _budgetCtrl,
                                            hintText: 'RM 0.00',
                                            icon: Icons.account_balance_wallet_rounded,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Shared Cloud Folder (Drive)"),
                                          _buildField(
                                            controller: _driveCtrl,
                                            hintText: 'drive.google.com/...',
                                            icon: Icons.cloud_circle_rounded,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Divider(thickness: 0.5),
                                ),

                                // SECTION B: LIFECYCLE TIMELINE TIMING
                                _sectionHeader(Icons.av_timer_rounded, 'Timeline Schedule'),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _datePicker(true)),
                                    const SizedBox(width: 14),
                                    Expanded(child: _datePicker(false)),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Divider(thickness: 0.5),
                                ),

                                // SECTION C: DISPATCH SUBMISSION ACTION ENGINE
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.add_circle_outline_rounded, size: 18),
                                              const SizedBox(width: 10),
                                              Text('Deploy Project', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
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

  // --- REUSABLE SUB-WIDGET COMPONENTS PLATFORM ---

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

  Widget _buildFieldLabel(String labelText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        labelText.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 18, color: kTextSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  Widget _datePicker(bool isStart) {
    final date = isStart ? _start : _end;
    final label = isStart ? 'Start Launch' : 'Target Closure';
    final icon = isStart ? Icons.play_arrow_rounded : Icons.stop_rounded;
    final bool hasDate = date != null;

    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate ? kAccentColor.withValues(alpha: 0.5) : kCardGlassBorder.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: hasDate ? kAccentColor : kTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate ? '${date.day}/${date.month}/${date.year}' : 'Staged/Tap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasDate ? kTextPrimary : kTextSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}