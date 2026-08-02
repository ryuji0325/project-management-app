import 'package:flutter/material.dart';

/// FadeInSlideUp — Performant entry animation.
///
/// PERFORMANCE NOTE: Menggunakan FadeTransition (bukan Opacity widget)
/// kerana FadeTransition menggunakan GPU compositing layer caching
/// yang jauh lebih murah berbanding Opacity.saveLayer() pada setiap frame.
class FadeInSlideUp extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const FadeInSlideUp({super.key, required this.child, this.delayMs = 0});

  @override
  State<FadeInSlideUp> createState() => _FadeInSlideUpState();
}

class _FadeInSlideUpState extends State<FadeInSlideUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450), // Slightly faster = snappier
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _translateY = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition is cheaper than Opacity widget (no saveLayer per frame)
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _translateY,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _translateY.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
