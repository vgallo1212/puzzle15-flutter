import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../utils/format.dart';

enum GameOverAction { restart, keepBoard, menu }

/// Pantalla superpuesta de fin de partida (victoria o derrota).
Future<GameOverAction?> showGameOverDialog(
  BuildContext context, {
  required bool won,
  required Duration time,
  required int moves,
  required Difficulty difficulty,
  required bool newRecord,
  required bool animate,
  String? reason,
}) {
  return showGeneralDialog<GameOverAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: animate
        ? const Duration(milliseconds: 300)
        : Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => _GameOverDialog(
      won: won,
      time: time,
      moves: moves,
      difficulty: difficulty,
      newRecord: newRecord,
      animate: animate,
      reason: reason,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({
    required this.won,
    required this.time,
    required this.moves,
    required this.difficulty,
    required this.newRecord,
    required this.animate,
    this.reason,
  });

  final bool won;
  final Duration time;
  final int moves;
  final Difficulty difficulty;
  final bool newRecord;
  final bool animate;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = won ? const Color(0xFFFFB547) : scheme.error;

    Widget icon = Icon(
      won ? Icons.emoji_events_rounded : Icons.timer_off_rounded,
      size: 72,
      color: accent,
    );
    if (animate) {
      icon = won
          ? Bounce(delay: const Duration(milliseconds: 250), child: icon)
          : ShakeX(delay: const Duration(milliseconds: 250), child: icon);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(28),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(height: 12),
                  Text(
                    won ? '¡Ganaste!' : 'Perdiste',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  if (newRecord) ...[
                    const SizedBox(height: 12),
                    _RecordBadge(animate: animate),
                  ],
                  const SizedBox(height: 20),
                  _SummaryRow(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo',
                    value: formatDuration(time),
                  ),
                  _SummaryRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Movimientos',
                    value: '$moves',
                  ),
                  _SummaryRow(
                    icon: Icons.grid_view_rounded,
                    label: 'Dificultad',
                    value: '${difficulty.label} (${difficulty.gridLabel})',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      autofocus: true,
                      onPressed: () =>
                          Navigator.of(context).pop(GameOverAction.restart),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(won ? 'Jugar otra vez' : 'Reintentar'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context)
                                  .pop(GameOverAction.keepBoard),
                          child: const Text('Ver tablero'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(GameOverAction.menu),
                          child: const Text('Menú'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB547), Color(0xFFFF7A90)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            '¡Nuevo récord!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    if (!animate) return badge;
    return Pulse(
      delay: const Duration(milliseconds: 500),
      infinite: true,
      child: badge,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
