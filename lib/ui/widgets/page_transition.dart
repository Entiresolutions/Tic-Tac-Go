import 'package:flutter/material.dart';

/// Custom transition between pages.
Route pageTransition(Widget page, {int durationMs = 400}) {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: durationMs),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade, slide, and scale effects.
      final slide = Tween<Offset>(
        begin: const Offset(0.2, 0.0), // Slide in from the right.
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

      final scale = Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, child: child),
        ),
      );
    },
  );
}
