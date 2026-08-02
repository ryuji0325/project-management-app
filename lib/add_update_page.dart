// lib/add_update_page.dart (Premium Glassmorphic Broadcast Provisioner)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global dari main.dart
import 'widgets/app_background.dart';

class AddUpdatePage extends StatefulWidget {
  final String projectId;

  const AddUpdatePage({super.key, required this.projectId});

  @override
  State<AddUpdatePage> createState() => _AddUpdatePageState();
}

class _AddUpdatePageState extends State<AddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController commentCtrl = TextEditingController();

  bool _loading = false;
  bool _submitted = false;
  String? _errorMessage;
  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _userName = userData?['username'] ??
                userData?['displayName'] ??
                user.email?.split('@').first ??
                'User';
          });
        } else {
          setState(() {
            _userName = user.email?.split('@').first ?? 'User';
          });
        }
      } catch (e) {
        setState(() {
          _userName = user.email?.split('@').first ?? 'User';
        });
      }
    }
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Menulis dokumen transaksi baru ke sub-koleksi 'updates' projek anda
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('updates')
          .add({
        'name': _userName,
        'userId': _userId,
        'update': commentCtrl.text.trim(),
        'date': FieldValue.serverTimestamp(),
        'fileUrl': '',
        'fileName': '',
      });

      if (!mounted) return;

      setState(() {
        _submitted = true;
      });

      // Delay 1 saat untuk membolehkan operator melihat visual keberhasilan animasi kaca
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Update transmission pipeline failed.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!_submitted && mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk melihat cecair ambient fluid background dari wrapper parent
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Dispatch Console',
            style: GoogleFonts.plusJakartaSans(
              color: kTextPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: EdgeInsets.zero, // Padding dikosongkan untuk integrasi penuh kitaran AnimatedSwitcher
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    child: _submitted
                        ? _buildSuccessCard(context)
                        : _buildForm(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- SUB COMPONENT A: BORANG MANIFEST INPUT TRANSMISI ---
  Widget _buildForm(BuildContext context) {
    return Padding(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cyber Sync Glowing Icon Ring Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kAccentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.bolt_rounded, size: 32, color: kAccentColor),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Broadcast Update',
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.3),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Stream structural status modifications or operational notes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(thickness: 0.5)),

            // OPERATOR TELEMETRY IDENTITY CAPSULE
            _buildInputLabel("Operator Authority Profile"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kAccentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kAccentColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: kAccentColor, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _userName.isNotEmpty ? 'Active Operator: $_userName' : 'Establishing stream authentication...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // INPUT FORM TEXT BOX FIELD CONTAINER
            _buildInputLabel("Update Manifest Details / Logs"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.6)),
              ),
              child: TextFormField(
                controller: commentCtrl,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 54.0), // Menyelaraskan ikon selari rapat ke atas
                    child: Icon(Icons.drive_file_rename_outline_rounded, color: kTextSecondary, size: 18),
                  ),
                  hintText: 'Enter mission-critical update descriptions...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Manifest data payload description required' : null,
              ),
            ),
            const SizedBox(height: 20),

            // ERROR PARSING NOTIFICATION BAND
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // METALLIC GRADIENT BROADCAST SUBMIT BUTTON
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), kAccentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: kAccentColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _loading ? null : _submit,
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: kBackgroundColor),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_and_archive_rounded, color: kBackgroundColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Commit Broadcast Log',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: kBackgroundColor),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB COMPONENT B: KAD VISUAL KEBERHASILAN TRANSAKSI TRANSMISI ---
  Widget _buildSuccessCard(BuildContext context) {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 44, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          Text(
            'Manifest Stamped!',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Your strategic operation notes have been successfully integrated into the cloud stream pipeline.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
}