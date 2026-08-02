import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget webBody;
  
  // Custom breakpoint, default is 800
  final double breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.webBody,
    this.breakpoint = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return mobileBody;
        } else {
          return webBody;
        }
      },
    );
  }
}

class WebConstrainedBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebConstrainedBox({
    super.key, 
    required this.child,
    this.maxWidth = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
