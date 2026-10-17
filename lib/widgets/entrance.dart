import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Entrada animada con animate_do que respeta el ajuste de animaciones.
/// Con las animaciones apagadas devuelve el hijo tal cual.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = EntranceFrom.bottom,
  });

  final Widget child;
  final Duration delay;
  final EntranceFrom from;

  @override
  Widget build(BuildContext context) {
    if (!AppScope.settingsOf(context).animations) return child;

    const duration = Duration(milliseconds: 500);
    switch (from) {
      case EntranceFrom.bottom:
        return FadeInUp(
          delay: delay,
          duration: duration,
          from: 30,
          child: child,
        );
      case EntranceFrom.top:
        return FadeInDown(
          delay: delay,
          duration: duration,
          from: 30,
          child: child,
        );
      case EntranceFrom.zoom:
        return ZoomIn(delay: delay, duration: duration, child: child);
    }
  }
}

enum EntranceFrom { bottom, top, zoom }
