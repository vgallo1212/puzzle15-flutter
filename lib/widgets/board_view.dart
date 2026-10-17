import 'package:flutter/material.dart';

import '../logic/puzzle_board.dart';
import '../models/tile_style.dart';
import 'puzzle_tile.dart';

/// Dibuja el tablero. Cada ficha es un AnimatedPositioned con key = su numero,
/// asi Flutter la reconoce entre frames y la desliza a su nueva casilla.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.style,
    required this.extent,
    required this.onTileTap,
    this.animate = true,
    this.enabled = true,
    this.solved = false,
  });

  final PuzzleBoard board;
  final TileStyle style;

  /// Lado total del tablero en pixeles.
  final double extent;
  final ValueChanged<int> onTileTap;
  final bool animate;
  final bool enabled;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = board.size;
    final padding = extent * 0.025;
    final gap = style == TileStyle.image && solved ? 0.0 : extent * 0.015;
    final cell = (extent - padding * 2) / n;
    final tileExtent = cell - gap;

    final background = switch (style) {
      TileStyle.retro => const Color(0xFF050B07),
      TileStyle.classic =>
        scheme.brightness == Brightness.dark
            ? const Color(0xFF3A2A1C)
            : const Color(0xFFB98B5E),
      _ => scheme.surfaceContainerHighest,
    };

    return Container(
      width: extent,
      height: extent,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(extent * 0.05),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          for (var value = 1; value < n * n; value++)
            _buildTile(value, cell, gap, tileExtent),
        ],
      ),
    );
  }

  Widget _buildTile(int value, double cell, double gap, double tileExtent) {
    final index = board.indexOfTile(value);
    final row = board.rowOf(index);
    final col = board.colOf(index);
    final movable = enabled && board.canMove(index);

    return AnimatedPositioned(
      key: ValueKey(value),
      duration: animate ? const Duration(milliseconds: 160) : Duration.zero,
      curve: Curves.easeOutCubic,
      left: col * cell + gap / 2,
      top: row * cell + gap / 2,
      width: tileExtent,
      height: tileExtent,
      child: MouseRegion(
        cursor: movable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onTileTap(index) : null,
          child: Semantics(
            button: movable,
            label: 'Pieza $value',
            child: PuzzleTile(
              value: value,
              boardSize: board.size,
              style: style,
              extent: tileExtent,
              inPlace: board.isInPlace(index),
              highlight: solved,
            ),
          ),
        ),
      ),
    );
  }
}
