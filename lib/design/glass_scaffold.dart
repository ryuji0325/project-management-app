import 'package:flutter/material.dart';
import 'app_theme.dart';

class GlassScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  const GlassScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // 1. Latar Belakang Gradien Utama
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.bgGradientStart, AppTheme.bgGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // 2. Hiasan Sfera Neon (Ambient Glow) di belakang kad untuk efek kedalaman kaca
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonPurple.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonBlue.withValues(alpha: 0.1),
              ),
            ),
          ),

          // 3. Kandungan Aplikasi Sebenar
          SafeArea(child: body),
        ],
      ),
    );
  }
}