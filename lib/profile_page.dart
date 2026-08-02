// lib/profile_page.dart (Premium Glassmorphic Profile Deck)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool loading = true;
  String? error;
  bool _uploading = false;
  bool _isEditing = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _posCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _deptCtrl = TextEditingController();
    _posCtrl = TextEditingController();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (user == null) {
      setState(() { loading = false; error = "Not logged in"; });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          loading = false;
          _nameCtrl.text = userData?['username'] ?? '';
          _phoneCtrl.text = userData?['phone'] ?? '';
          _deptCtrl.text = userData?['department'] ?? '';
          _posCtrl.text = userData?['position'] ?? '';
        });
      } else {
        setState(() { error = "User profile instance unassigned"; loading = false; });
      }
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'username': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'position': _posCtrl.text.trim(),
      });
      setState(() {
        _isEditing = false;
        userData!['username'] = _nameCtrl.text.trim();
        userData!['phone'] = _phoneCtrl.text.trim();
        userData!['department'] = _deptCtrl.text.trim();
        userData!['position'] = _posCtrl.text.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile encryption database updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cluster database rejection: $e")));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _updateProfilePic() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Multi-media stream pipelines are isolated to mobile endpoints')),
        );
      }
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null && user != null) {
      setState(() => _uploading = true);
      try {
        final bytes = await picked.readAsBytes();
        final String userId = user!.uid;
        final String fileName = 'profile_$userId.jpg';
        final ref = FirebaseStorage.instance.ref().child('user_profiles').child(fileName);
        await ref.putData(bytes);
        final String downloadUrl = await ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'photoUrl': downloadUrl});
        await user!.updatePhotoURL(downloadUrl);
        setState(() { userData = { ...?userData, 'photoUrl': downloadUrl }; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile secure hash image updated!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Media stream fault: $e")));
      } finally {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // --- REFACTOR MEDAN BARIS PARAMETER DENGAN KLIKAN INLINE KACA FROSTED ---
  Widget _profileInfoRow(String label, String value, TextEditingController controller, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                shape: BoxShape.circle,
                border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 18, color: _isEditing ? kAccentColor : kTextSecondary),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(), 
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                ),
                const SizedBox(height: 5),
                _isEditing
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kCardGlassBorder),
                        ),
                        child: TextFormField(
                          controller: controller,
                          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          value.isEmpty ? "-" : value,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = userData?['photoUrl'];
    final hasPhoto = photoUrl != null && photoUrl.toString().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent, // Lutsinar bagi mengekalkan hiasan cecair dari shell parent
      appBar: AppBar(
        title: Text(
          'Security Account', 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.5)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: _saving ? null : () {
                if (_isEditing) { _saveProfileChanges(); } else { setState(() => _isEditing = true); }
              },
              icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kAccentColor, strokeWidth: 2))
                : Icon(_isEditing ? Icons.check_circle_rounded : Icons.tune_rounded, color: kAccentColor, size: 22),
            ),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kAccentColor))
          : error != null
              ? Center(
                  child: GlassContainer(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 36),
                        const SizedBox(height: 16),
                        Text(error!, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.2), foregroundColor: Colors.redAccent),
                            child: const Text('Emergency Sign Out'),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 550),
                        child: GlassContainer(
                          borderRadius: 28,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // --- COMPONENT 1: TEAL NEON AVATAR DECK HALO ---
                              GestureDetector(
                                onTap: _uploading ? null : _updateProfilePic,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(alpha: 0.3),
                                        border: Border.all(color: kAccentColor.withValues(alpha: 0.35), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(color: kAccentColor.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 4),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 52,
                                        backgroundColor: kBackgroundColor,
                                        backgroundImage: hasPhoto ? NetworkImage(photoUrl) as ImageProvider : null,
                                        child: _uploading
                                            ? const CircularProgressIndicator(color: kAccentColor, strokeWidth: 2)
                                            : (!hasPhoto ? Icon(Icons.face_retouching_natural_rounded, size: 44, color: kTextSecondary.withValues(alpha: 0.4)) : null),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kAccentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF0F1626), width: 2.5),
                                      ),
                                      child: const Icon(Icons.add_a_photo_rounded, color: kBackgroundColor, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Identity Meta Strings
                              if (!_isEditing) ...[
                                Text(
                                  userData?['username'] ?? 'Anonymous Operator',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData?['email'] ?? user?.email ?? '-',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w500),
                                ),
                              ] else ...[
                                _profileInfoRow('Full Node Identity Name', userData?['username'] ?? '', _nameCtrl),
                              ],
                              
                              const Padding(padding: EdgeInsets.symmetric(vertical: 18.0), child: Divider(thickness: 0.5)),
                              
                              // --- COMPONENT 2: INTERACTIVE DECK PARAMETERS REFACTOR ---
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), shape: BoxShape.circle, border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.3))),
                                    child: Icon(Icons.gpp_good_rounded, size: 18, color: kAccentColor.withValues(alpha: 0.8)),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("AUTHORIZATION RANK LEVEL", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: kAccentColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: kAccentColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Text(
                                          (userData?['role'] ?? 'Staff').toString().toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11, color: kAccentColor, letterSpacing: 0.5),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              
                              const Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Divider(thickness: 0.5)),
                              _profileInfoRow('Phone Connection Handle', userData?['phone'] ?? '', _phoneCtrl, icon: Icons.phone_iphone_rounded),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Divider(thickness: 0.5)),
                              _profileInfoRow('Operational Department Pool', userData?['department'] ?? '', _deptCtrl, icon: Icons.hub_rounded),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Divider(thickness: 0.5)),
                              _profileInfoRow('Corporate Deployment Position', userData?['position'] ?? '', _posCtrl, icon: Icons.badge_rounded),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Divider(thickness: 0.5)),
                              
                              const SizedBox(height: 28),
                              
                              // --- COMPONENT 3: SECURE TERMINATION PURGE BUTTON ---
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                                  label: Text('Terminate Session (Sign Out)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                                  onPressed: _signOut,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.35), width: 1.2),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}