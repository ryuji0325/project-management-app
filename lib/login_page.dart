// lib/login_page.dart (Premium Glassmorphic Authentication Gateway)

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String? error;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- KAEDAH 1: LOG MASUK EMEL & KATA LALUAN TRADISIONAL ---
  Future<void> loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; error = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          error = 'Invalid credential keys or node handle not found.';
        } else if (e.code == 'wrong-password') {
          error = 'Cryptographic key breach: Incorrect password.';
        } else {
          error = e.message;
        }
      });
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --- KAEDAH 2: INTEGRASI GOOGLE OAUTH SECURITY AUTHENTICATION ---
  Future<void> loginWithGoogle() async {
    setState(() { loading = true; error = null; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '897744544653-hcj4st0a27be6rkccdrtlc1dgj13obat.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => loading = false);
        return; // Operator membatalkan peranti login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential cred = await FirebaseAuth.instance.signInWithCredential(credential);

      // Sinkronisasi kluster / Semakan profile wujud (Idempotent tracking)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'username': cred.user!.displayName ?? googleUser.displayName ?? 'Unnamed Node',
          'email': cred.user!.email ?? googleUser.email,
          'phone': '',
          'department': 'Unassigned Pool',
          'position': 'Operational Operator',
          'role': 'Staff',
          'photoUrl': cred.user!.photoURL ?? googleUser.photoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      setState(() { error = e.message ?? e.toString(); });
    } catch (e) {
      setState(() { error = "Log masuk Google gagal: ${e.toString().replaceAll('Exception: ', '')}"; });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Ambient Cecair Latar Belakang 1
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
          // Ambient Sfera Glow 2
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 400, height: 400,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimaryPurpleGlow),
            ),
          ),

          // Main Interactive Authenticator Area
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: GlassContainer(
                      borderRadius: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CYBER LOCK ICON IDENTIFICATION RING
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kAccentColor.withValues(alpha: 0.1),
                                  border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.lock_outline_rounded, color: kAccentColor, size: 36),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            Center(
              child: Text(
                "Welcome Back",
                style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                "Sign in to continue",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(thickness: 0.5)),
            
            _buildInputLabel("Email"),
            TextFormField(
              controller: emailController,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter account email address',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                return emailRegex.hasMatch(v.trim()) ? null : 'Enter valid email address';
              },
            ),
            const SizedBox(height: 16),
            
            _buildInputLabel("Password"),
            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter password key',
                prefixIcon: const Icon(Icons.lock_outline, size: 19),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: kTextSecondary, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
            ),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot'),
                child: Text('Forgot Password?', style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontWeight: FontWeight.w700)),
              ),
            ),
            
            if (error != null)
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
                        child: Text(error!, style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : loginWithEmail,
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2))
                    : Text('Log In', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(thickness: 0.5),
            ),

            // PANGGILAN BUTANG OAUTH YANG BETUL (ASCII SAHAJA)
            _buildGoogleOAuthButton(loading, loginWithGoogle),
            const SizedBox(height: 18),
            
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Text("Sign Up", style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            )
                          ],
                        ),
                      ),
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

  Widget _buildInputLabel(String labelText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        labelText.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildGoogleOAuthButton(bool loading, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
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
              const Icon(Icons.g_mobiledata_rounded, color: Colors.amber, size: 26),
              const SizedBox(width: 12),
              Text("Sign In with Google", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}