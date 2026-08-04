// lib/splash_screen.dart (Premium Glassmorphic Immersive Splash)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengimport tokens reka bentuk global

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInCubic),
    );

    // Animasi anjal elastik untuk impak kemunculan logo yang premium
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Mengekalkan delay perlaksanaan sistem selama 2 saat untuk kestabilan pembacaan session
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // Penghalaan route dinamik yang selamat
    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // 1. IMMERSIVE FLUID BACKDROP CANVAS
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
          
          // Sfera Ambient Glow Pusat (Center Ambient Light Core)
          Center(
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kAccentColor.withValues(alpha: 0.12),
                    kAccentColor.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Sfera Ambient Glow Sisi Kiri Atas (Hiasan Kedalaman)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryPurpleGlow,
              ),
            ),
          ),

          // 2. MAIN INTERACTIVE CONTENT LAYER
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Cyber Neon Avatar Shell
                    Container(
                      width: 124,
                      height: 124,
                      padding: const EdgeInsets.all(2), // Ruang pemisah antara border dan imej
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(
                          color: kAccentColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kAccentColor.withValues(alpha: 0.12),
                            blurRadius: 40,
                            spreadRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/PM.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Penanganan kecemasan jika fail aset PNG tidak ditemui semasa kompilasi
                            return Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(Icons.token_rounded, color: kAccentColor, size: 44),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App Brand Typography Setup
                    Text(
                      'UNI-X',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: kTextPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PROJECT MANAGEMENT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kTextSecondary,
                        letterSpacing: 4.5, // Lebar karakter premium eksekutif
                      ),
                    ),
                    const SizedBox(height: 54),
                    
                    // High-Fidelity Minimalist Pipeline Tracker (Loading indicator)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: const AlwaysStoppedAnimation<Color>(kAccentColor),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}