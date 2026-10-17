import 'dart:math';

/// Direccion en la que se desliza una pieza hacia el hueco.
enum SlideDirection { up, down, left, right }

/// Estado del tablero y reglas del juego, sin nada de UI.
///
/// Las piezas se guardan en una lista plana de tamano n*n. El 0 es el hueco.
/// El tablero resuelto es 1, 2, 3 ... n*n-1 y el hueco al final.
class PuzzleBoard {
  PuzzleBoard._(this.size, this._tiles);

  final int size;
  final List<int> _tiles;

  factory PuzzleBoard.solved(int size) {
    final tiles = List<int>.generate(size * size, (i) => i + 1);
    tiles[tiles.length - 1] = 0;
    return PuzzleBoard._(size, tiles);
  }

  /// Crea un tablero a partir de una lista concreta (se usa en los tests).
  factory PuzzleBoard.fromList(int size, List<int> tiles) {
    assert(tiles.length == size * size);
    return PuzzleBoard._(size, List<int>.of(tiles));
  }

  /// Mezcla al azar y garantiza que la mezcla tenga solucion.
  ///
  /// Se baraja con Fisher-Yates y despues se revisa la paridad de las
  /// inversiones. Si la permutacion sale imposible basta con intercambiar
  /// dos piezas (que no sean el hueco) para cambiar la paridad y volverla
  /// resoluble. Tambien se evita entregar un tablero ya resuelto.
  factory PuzzleBoard.shuffled(int size, {Random? random}) {
    final rnd = random ?? Random();
    final tiles = List<int>.generate(size * size, (i) => i);

    do {
      for (var i = tiles.length - 1; i > 0; i--) {
        final j = rnd.nextInt(i + 1);
        final tmp = tiles[i];
        tiles[i] = tiles[j];
        tiles[j] = tmp;
      }
      if (!isSolvable(tiles, size)) {
        _swapFirstTwoTiles(tiles);
      }
    } while (PuzzleBoard._(size, tiles).isSolved);

    return PuzzleBoard._(size, tiles);
  }

  List<int> get tiles => List.unmodifiable(_tiles);
  int get length => _tiles.length;
  int get blankIndex => _tiles.indexOf(0);

  int tileAt(int index) => _tiles[index];
  int indexOfTile(int value) => _tiles.indexOf(value);

  int rowOf(int index) => index ~/ size;
  int colOf(int index) => index % size;

  /// Posicion en la que deberia estar la pieza [value] al resolver.
  int goalIndexOf(int value) => value == 0 ? _tiles.length - 1 : value - 1;

  bool isInPlace(int index) => _tiles[index] == 0
      ? index == _tiles.length - 1
      : _tiles[index] == index + 1;

  bool get isSolved {
    for (var i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles.last == 0;
  }

  int get tilesInPlace {
    var count = 0;
    for (var i = 0; i < _tiles.length; i++) {
      if (_tiles[i] != 0 && isInPlace(i)) count++;
    }
    return count;
  }

  /// Una pieza se puede mover si esta en la misma fila o columna que el hueco.
  /// Si no es vecina directa se arrastra toda la fila (como en el juego fisico).
  bool canMove(int index) {
    final blank = blankIndex;
    if (index == blank) return false;
    return rowOf(index) == rowOf(blank) || colOf(index) == colOf(blank);
  }

  bool isAdjacentToBlank(int index) {
    final blank = blankIndex;
    final dr = (rowOf(index) - rowOf(blank)).abs();
    final dc = (colOf(index) - colOf(blank)).abs();
    return dr + dc == 1;
  }

  /// Mueve la pieza en [index] (y las que haya entre ella y el hueco).
  /// Devuelve cuantas piezas se movieron; 0 si el movimiento no es valido.
  int moveTile(int index) {
    if (!canMove(index)) return 0;

    final blank = blankIndex;
    final step = rowOf(index) == rowOf(blank)
        ? (index > blank ? 1 : -1)
        : (index > blank ? size : -size);

    var moved = 0;
    var current = blank;
    while (current != index) {
      final next = current + step;
      _tiles[current] = _tiles[next];
      _tiles[next] = 0;
      current = next;
      moved++;
    }
    return moved;
  }

  /// Mueve hacia el hueco la pieza que este del lado contrario a [direction].
  /// Por ejemplo, con flecha arriba sube la pieza que esta debajo del hueco.
  int slide(SlideDirection direction) {
    final blank = blankIndex;
    final row = rowOf(blank);
    final col = colOf(blank);

    int? source;
    switch (direction) {
      case SlideDirection.up:
        if (row < size - 1) source = blank + size;
      case SlideDirection.down:
        if (row > 0) source = blank - size;
      case SlideDirection.left:
        if (col < size - 1) source = blank + 1;
      case SlideDirection.right:
        if (col > 0) source = blank - 1;
    }
    return source == null ? 0 : moveTile(source);
  }

  /// Cuenta las inversiones: pares (a, b) con a antes que b y a > b,
  /// ignorando el hueco.
  static int countInversions(List<int> tiles) {
    final values = tiles.where((t) => t != 0).toList();
    var inversions = 0;
    for (var i = 0; i < values.length; i++) {
      for (var j = i + 1; j < values.length; j++) {
        if (values[i] > values[j]) inversions++;
      }
    }
    return inversions;
  }

  /// Regla de paridad del 15-puzzle:
  /// - Ancho impar (3x3, 5x5): resoluble si las inversiones son pares.
  /// - Ancho par (4x4): resoluble si inversiones + fila del hueco contada
  ///   desde abajo (empezando en 1) da un numero impar.
  static bool isSolvable(List<int> tiles, int size) {
    final inversions = countInversions(tiles);
    if (size.isOdd) return inversions.isEven;

    final blankRowFromBottom = size - (tiles.indexOf(0) ~/ size);
    return (inversions + blankRowFromBottom).isOdd;
  }

  static void _swapFirstTwoTiles(List<int> tiles) {
    final a = tiles.indexWhere((t) => t != 0);
    final b = tiles.indexWhere((t) => t != 0, a + 1);
    final tmp = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = tmp;
  }
}
