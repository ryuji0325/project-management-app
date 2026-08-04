import 'package:flutter/material.dart';
import '../main.dart';

/// AppBackground — Aurora ambient glow background.
/// 
/// PERFORMANCE NOTE: BackdropFilter (blur) dihapuskan kerana ia
/// sangat mahal (GPU saveLayer) dan menyebabkan lag semasa navigation.
/// Gradient + RadialGradient orbs memberikan kesan visual yang sama
/// tanpa kos GPU yang tinggi.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final bool isDark = currentMode == ThemeMode.dark;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [kBgGradientStart, kBgGradientEnd]
                  : [const Color(0xFF6C5DD3), const Color(0xFF2DD4A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Ambient aurora glow - top right (Teal)
              Positioned(
                top: -150,
                right: -100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        kAccentColor.withValues(alpha: isDark ? 0.18 : 0.22),
                        kAccentColor.withValues(alpha: isDark ? 0.06 : 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Ambient aurora glow - bottom left (Purple)
              Positioned(
                bottom: -200,
                left: -150,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.14 : 0.18),
                        const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.04 : 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Ambient aurora glow - top left (Rose)
              Positioned(
                top: 100,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE11D48).withValues(alpha: isDark ? 0.09 : 0.12),
                        const Color(0xFFE11D48).withValues(alpha: isDark ? 0.02 : 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              child,
            ],
          ),
        );
      }
    );
  }
}