// lib/signup_page.dart (Premium Glassmorphic Registration Hub)

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Terminal Controllers
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();

  bool _loading = false;
  String _role = 'Staff';
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  // --- KAEDAH 1: PENDAFTARAN EMEL & KATA LALUAN TRADISIONAL ---
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create Auth Instance User
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      
      // Simpan data instans lengkap ke Cloud Firestore Cluster
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'position': _positionCtrl.text.trim(),
        'role': _role,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _error = 'Emel ini sudah didaftarkan. Sila guna emel lain atau log masuk.';
        } else if (e.code == 'weak-password') {
          _error = 'Kata laluan terlalu lemah. Sila guna sekurang-kurangnya 6 aksara.';
        } else if (e.code == 'invalid-email') {
          _error = 'Format emel tidak sah.';
        } else {
          _error = e.message ?? e.toString();
        }
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- KAEDAH 2: INTEGRASI GOOGLE OAUTH FLOW SIGN-UP/SIGN-IN ---
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '897744544653-hcj4st0a27be6rkccdrtlc1dgj13obat.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _loading = false);
        return; // Pengguna membatalkan operasi pendaftaran
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential cred = await FirebaseAuth.instance.signInWithCredential(credential);

      // Semakan perlindungan data (Idempotent check) untuk mengelakkan overwriting profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'username': _usernameCtrl.text.trim().isNotEmpty 
              ? _usernameCtrl.text.trim() 
              : (cred.user!.displayName ?? googleUser.displayName ?? 'Unnamed Node'),
          'email': cred.user!.email ?? googleUser.email,
          'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '',
          'department': _deptCtrl.text.trim().isNotEmpty ? _deptCtrl.text.trim() : 'Unassigned Pool',
          'position': _positionCtrl.text.trim().isNotEmpty ? _positionCtrl.text.trim() : 'Operational Operator',
          'role': _role,
          'photoUrl': cred.user!.photoURL ?? googleUser.photoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? e.toString(); });
    } catch (e) {
      setState(() { _error = "Google Sign Up gagal: ${e.toString().replaceAll('Exception: ', '')}"; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Ambient Fluid Layer 1: Base Dark Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBgGradientStart, kBgGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Ambient Fluid Layer 2: Core Purple/Teal Glow Blur
          Center(
            child: Container(
              width: 450, height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kAccentColor.withValues(alpha: 0.08), Colors.transparent]
                )
              ),
            ),
          ),

          // Main Registration Dashboard Content
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IDENTITY TITLE SEGMENT
                        Text(
                          "Create Terminal Account",
                          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Initialize your security profile parameters inside Uni-X.",
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Divider(thickness: 0.5),
                        ),
                        
                        // INPUT FORM PACKS
                        _buildFieldLabel("Full Handle / Real Name"),
                        TextFormField(
                          controller: _usernameCtrl,
                          style: const TextStyle(color: kTextPrimary, fontSize: 14),
                          decoration: const InputDecoration(hintText: 'e.g. Alex Mercer', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                          validator: (v) => v!.isEmpty ? 'Identifier required' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel("Secure Access Email Address"),
                        TextFormField(
                          controller: _emailCtrl,
                          style: const TextStyle(color: kTextPrimary, fontSize: 14),
                          decoration: const InputDecoration(hintText: 'e.g. name@company.com', prefixIcon: Icon(Icons.alternate_email_rounded, size: 19)),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            return emailRegex.hasMatch(v.trim()) ? null : 'Malformed communication channel link';
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel("Contact Grid Node (Phone)"),
                        TextFormField(
                          controller: _phoneCtrl,
                          style: const TextStyle(color: kTextPrimary, fontSize: 14),
                          decoration: const InputDecoration(hintText: 'e.g. +60123456789', prefixIcon: Icon(Icons.phone_android_rounded, size: 19)),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? 'Phone parameters uninitialized' : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("Department"),
                                  TextFormField(
                                    controller: _deptCtrl,
                                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                                    decoration: const InputDecoration(hintText: 'e.g. Infra Dev', prefixIcon: Icon(Icons.hub_outlined, size: 19)),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("Position Title"),
                                  TextFormField(
                                    controller: _positionCtrl,
                                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                                    decoration: const InputDecoration(hintText: 'e.g. Lead Engineer', prefixIcon: Icon(Icons.badge_outlined, size: 19)),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel("Cryptographic Gateway Key (Password)"),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: kTextPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Minimum 6 alphanumeric keys',
                            prefixIcon: const Icon(Icons.lock_person_outlined, size: 19),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: kTextSecondary, size: 18),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? 'Insecure key weight (Min 6 chars)' : null,
                        ),
                        const SizedBox(height: 20),

                        // CUSTOM NODE ROLE CHOICE SELECTION
                        _buildFieldLabel("Authorization Cluster Level (Role)"),
                        Row(
                          children: [
                            _buildCustomChoiceChip("Supervisor Account", _role == 'Supervisor', () => setState(() => _role = 'Supervisor')),
                            const SizedBox(width: 12),
                            _buildCustomChoiceChip("Standard Staff Node", _role == 'Staff', () => setState(() => _role = 'Staff')),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // SUBMIT PRIMARIES BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signUp,
                            child: _loading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2))
                              : Text("Initialize Registration", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        
                        // DECORATIVE INDUSTRIAL OR DIVIDER
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: kCardGlassBorder.withValues(alpha: 0.4), thickness: 0.5)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                child: Text("OR STREAM VIA OAUTH", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5)),
                              ),
                              Expanded(child: Divider(color: kCardGlassBorder.withValues(alpha: 0.4), thickness: 0.5)),
                            ],
                          ),
                        ),

                        // GOOGLE OAUTH INTERFACE LINK BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _signUpWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kCardGlassBorder, width: 1.2),
                              backgroundColor: Colors.white.withValues(alpha: 0.01),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Membina logo Google menggunakan rekabentuk poligon custom mini untuk penjimatan fail aset
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                                    child: const Icon(Icons.g_mobiledata_rounded, color: Colors.amber, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Sync Account with Google Profile",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // BACK LINK CONTROLLER FOOTER
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary),
                                children: const [
                                  TextSpan(text: "Already operational? "),
                                  TextSpan(text: "Access Terminal", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.w700)),
                                ],
                              ),
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
        ],
      ),
    );
  }

  // --- REUSABLE UTILITY HELPER COMPONENTS ---
  Widget _buildFieldLabel(String labelText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        labelText.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCustomChoiceChip(String title, bool isSelected, VoidCallback onSelected) {
    return Expanded(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? kAccentColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kAccentColor : kCardGlassBorder,
              width: 1.2
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? kAccentColor : kTextSecondary
            ),
          ),
        ),
      ),
    );
  }
}