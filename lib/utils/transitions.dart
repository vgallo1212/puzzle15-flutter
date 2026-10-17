import 'package:flutter/material.dart';

/// Ruta con fundido + leve deslizamiento. Si las animaciones estan
/// apagadas en ajustes, la pantalla aparece al instante.
Route<T> fadeRoute<T>(Widget page, {bool animate = true}) {
  return PageRouteBuilder<T>(
    transitionDuration: animate
        ? const Duration(milliseconds: 350)
        : Duration.zero,
    reverseTransitionDuration: animate
        ? const Duration(milliseconds: 250)
        : Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
