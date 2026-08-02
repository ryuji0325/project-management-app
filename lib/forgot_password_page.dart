// lib/forgot_password_page.dart (Premium Glassmorphic Access Recovery)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global dari main.dart

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address payload.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _sent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification link dispatched successfully!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF0C2B23),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: GoogleFonts.plusJakartaSans())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Access Recovery",
          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
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
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 400, height: 400,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimaryPurpleGlow),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CYBER SECURITY RESET SHIELD RESET RING
                        Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kAccentColor.withValues(alpha: 0.1),
                          border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: kAccentColor, size: 36),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Center(
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        "Enter your authorized routing handle email below to receive an internal security reset link.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 18.0), child: Divider(thickness: 0.5)),
                    
                    // FIELD INPUT FORM PACK
                    _buildInputLabel("Authorized Node Email"),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
                      ),
                      child: TextFormField(
                        controller: _emailCtrl,
                        style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Enter your profile registration email',
                          hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18, color: kTextSecondary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // TRANSACTION SUCCESS SUBTLE STATUS BADGE
                    if (_sent) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kAccentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kAccentColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: kAccentColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Recovery transmission broadcasted! Check your inbox.",
                                style: GoogleFonts.plusJakartaSans(
                                  color: kAccentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // SUBMIT ACTION DISPATCH TRIGGER BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _reset,
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Send Link Request', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                                ],
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