import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15/logic/puzzle_board.dart';

void main() {
  group('Tablero resuelto', () {
    test('3x3 tiene el hueco al final', () {
      final board = PuzzleBoard.solved(3);
      expect(board.tiles, [1, 2, 3, 4, 5, 6, 7, 8, 0]);
      expect(board.isSolved, isTrue);
    });

    test('tablero desordenado no esta resuelto', () {
      final board = PuzzleBoard.fromList(3, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(board.isSolved, isFalse);
    });
  });

  group('Paridad', () {
    test('cuenta inversiones ignorando el hueco', () {
      expect(PuzzleBoard.countInversions([1, 2, 3, 4, 5, 6, 7, 8, 0]), 0);
      expect(PuzzleBoard.countInversions([2, 1, 3, 4, 5, 6, 7, 8, 0]), 1);
      expect(PuzzleBoard.countInversions([8, 7, 6, 5, 4, 3, 2, 1, 0]), 28);
    });

    test('3x3 con dos piezas cambiadas no tiene solucion', () {
      expect(PuzzleBoard.isSolvable([2, 1, 3, 4, 5, 6, 7, 8, 0], 3), isFalse);
      expect(PuzzleBoard.isSolvable([1, 2, 3, 4, 5, 6, 7, 0, 8], 3), isTrue);
    });

    test('4x4: el famoso 14-15 de Sam Loyd es imposible', () {
      final loyd = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, 0];
      expect(PuzzleBoard.isSolvable(loyd, 4), isFalse);
      expect(PuzzleBoard.isSolvable(PuzzleBoard.solved(4).tiles, 4), isTrue);
    });

    test('4x4: subir el hueco una fila mantiene la solucion', () {
      // Hueco en la tercera fila (desde arriba) tras mover el 12 hacia abajo.
      final tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 13, 14, 15, 12];
      expect(PuzzleBoard.isSolvable(tiles, 4), isTrue);
    });

    test('3x3: todas las mezclas aparecen entre los estados alcanzables', () {
      // Se recorren con BFS todos los estados a los que se llega desde el
      // tablero resuelto (son 9!/2 = 181440). Cualquier mezcla del juego
      // tiene que estar ahi, si no seria imposible de resolver.
      final start = PuzzleBoard.solved(3).tiles.join(',');
      final seen = <String>{start};
      final queue = <String>[start];
      for (var head = 0; head < queue.length; head++) {
        final tiles = queue[head].split(',').map(int.parse).toList();
        for (final dir in SlideDirection.values) {
          final board = PuzzleBoard.fromList(3, tiles);
          if (board.slide(dir) == 0) continue;
          final key = board.tiles.join(',');
          if (seen.add(key)) queue.add(key);
        }
      }
      expect(seen.length, 181440);

      final rnd = Random(42);
      for (var i = 0; i < 300; i++) {
        final board = PuzzleBoard.shuffled(3, random: rnd);
        expect(seen.contains(board.tiles.join(',')), isTrue);
      }
    });

    for (final size in [3, 4, 5]) {
      test('$size x $size: 500 mezclas siempre son resolubles', () {
        final rnd = Random(size);
        for (var i = 0; i < 500; i++) {
          final board = PuzzleBoard.shuffled(size, random: rnd);
          expect(PuzzleBoard.isSolvable(board.tiles, size), isTrue);
          expect(board.isSolved, isFalse);
          expect(board.tiles.toSet().length, size * size);
        }
      });
    }
  });

  group('Movimientos', () {
    test('mover una pieza vecina al hueco', () {
      final board = PuzzleBoard.solved(3);
      expect(board.moveTile(7), 1);
      expect(board.tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(board.moveTile(8), 1);
      expect(board.isSolved, isTrue);
    });

    test('una pieza fuera de la fila o columna no se mueve', () {
      final board = PuzzleBoard.solved(3);
      expect(board.moveTile(0), 0);
      expect(board.isSolved, isTrue);
    });

    test('tocar una pieza lejana en la misma fila arrastra varias', () {
      final board = PuzzleBoard.solved(4);
      expect(board.moveTile(12), 3);
      expect(board.tiles.sublist(12), [0, 13, 14, 15]);
    });

    test('las flechas mueven la pieza contraria al hueco', () {
      final board = PuzzleBoard.solved(3);
      expect(board.slide(SlideDirection.up), 0);
      expect(board.slide(SlideDirection.right), 1);
      expect(board.tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(board.slide(SlideDirection.down), 1);
      expect(board.tiles, [1, 2, 3, 4, 0, 6, 7, 5, 8]);
    });

    test('cuenta piezas en su sitio', () {
      final board = PuzzleBoard.fromList(3, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(board.tilesInPlace, 7);
    });
  });
}
