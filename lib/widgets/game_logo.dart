import 'package:flutter/material.dart';

/// Logo: un mini tablero 3x3 con el hueco abajo a la derecha.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gap = size * 0.05;
    final cell = (size - gap * 4) / 3;

    final colors = [
      const Color(0xFF7C5CFF),
      const Color(0xFF5B8CFF),
      const Color(0xFF3CC6D0),
      const Color(0xFFFF7A90),
      const Color(0xFFFFB547),
      const Color(0xFF55D187),
      const Color(0xFFB067F0),
      const Color(0xFFFF8F5A),
    ];

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: List.generate(9, (i) {
          if (i == 8) return SizedBox(width: cell, height: cell);
          return Container(
            width: cell,
            height: cell,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(cell * 0.22),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: cell * 0.5,
                height: 1.1,
              ),
            ),
          );
        }),
      ),
    );
  }
}
