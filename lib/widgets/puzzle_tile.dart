import 'package:flutter/material.dart';

import '../models/tile_style.dart';
import 'scene_painter.dart';

/// Dibuja una ficha segun el estilo elegido. No sabe nada de reglas:
/// solo recibe el numero, el tamano del tablero y si esta en su sitio.
class PuzzleTile extends StatelessWidget {
  const PuzzleTile({
    super.key,
    required this.value,
    required this.boardSize,
    required this.style,
    required this.extent,
    this.inPlace = false,
    this.highlight = false,
  });

  final int value;
  final int boardSize;
  final TileStyle style;

  /// Lado de la ficha en pixeles (para escalar el texto).
  final double extent;
  final bool inPlace;

  /// Resalta la ficha (por ejemplo al ganar).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(extent * 0.16);
    final fontSize = extent * (boardSize >= 5 ? 0.36 : 0.4);

    switch (style) {
      case TileStyle.classic:
        return _box(
          radius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF8A6A4B), Color(0xFF6B4E35)]
                : const [Color(0xFFF3D9B1), Color(0xFFE2B887)],
          ),
          border: Border.all(
            color: inPlace
                ? (dark ? const Color(0xFFFFD08A) : const Color(0xFF9C6B3B))
                : Colors.transparent,
            width: 2,
          ),
          shadow: Colors.black.withValues(alpha: 0.25),
          child: _number(
            fontSize,
            dark ? const Color(0xFFFFF3E2) : const Color(0xFF5A3A1E),
            FontWeight.w700,
          ),
        );

      case TileStyle.colorful:
        final hue = (value - 1) / (boardSize * boardSize - 1) * 320;
        final color = HSLColor.fromAHSL(
          1,
          hue,
          0.7,
          dark ? 0.5 : 0.58,
        ).toColor();
        return _box(
          radius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.15)!, color],
          ),
          border: inPlace ? Border.all(color: Colors.white, width: 2.5) : null,
          shadow: color.withValues(alpha: 0.45),
          child: _number(fontSize, Colors.white, FontWeight.w700),
        );

      case TileStyle.retro:
        const green = Color(0xFF39FF88);
        return _box(
          radius: BorderRadius.circular(extent * 0.06),
          color: const Color(0xFF0E1A12),
          border: Border.all(
            color: inPlace ? green : green.withValues(alpha: 0.35),
            width: inPlace ? 2 : 1.2,
          ),
          shadow: green.withValues(alpha: inPlace ? 0.35 : 0.12),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: green,
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              shadows: [
                Shadow(color: green.withValues(alpha: 0.8), blurRadius: 8),
              ],
            ),
          ),
        );

      case TileStyle.minimal:
        return _box(
          radius: radius,
          color: scheme.surface,
          border: Border.all(
            color: inPlace ? scheme.primary : scheme.outlineVariant,
            width: inPlace ? 2 : 1,
          ),
          child: _number(fontSize, scheme.onSurface, FontWeight.w400),
        );

      case TileStyle.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(extent * 0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: SceneSlicePainter(
                  value: value,
                  boardSize: boardSize,
                  dark: dark,
                ),
              ),
              // Numero pequeno de ayuda en la esquina.
              Positioned(
                left: 4,
                top: 2,
                child: Text(
                  '$value',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (extent * 0.18).clamp(9.0, 16.0),
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 3),
                    ],
                  ),
                ),
              ),
              if (inPlace || highlight)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(extent * 0.08),
                  ),
                ),
            ],
          ),
        );
    }
  }

  Widget _number(double fontSize, Color color, FontWeight weight) {
    return Text(
      '$value',
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.1,
      ),
    );
  }

  Widget _box({
    required BorderRadius radius,
    required Widget child,
    Color? color,
    Gradient? gradient,
    BoxBorder? border,
    Color? shadow,
  }) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: radius,
        border: border,
        boxShadow: [
          if (shadow != null)
            BoxShadow(
              color: highlight ? shadow.withValues(alpha: 0.9) : shadow,
              blurRadius: highlight ? 16 : 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}
