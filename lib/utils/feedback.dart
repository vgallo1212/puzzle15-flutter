import 'package:flutter/services.dart';

/// Efectos cortos al mover piezas (sin musica). En movil suena el click del
/// sistema y vibra un poco; en web y escritorio el sistema puede ignorarlos.
class GameFeedback {
  static void move(bool enabled) {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  static void invalid(bool enabled) {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void win(bool enabled) {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }
}
