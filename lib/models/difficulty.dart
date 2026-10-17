enum Difficulty {
  easy(3, 'Fácil', Duration(minutes: 3)),
  medium(4, 'Medio', Duration(minutes: 8)),
  hard(5, 'Difícil', Duration(minutes: 15));

  const Difficulty(this.size, this.label, this.timeLimit);

  final int size;
  final String label;

  /// Tiempo maximo cuando el modo contrarreloj esta activo.
  final Duration timeLimit;

  int get pieces => size * size - 1;
  String get gridLabel => '${size}x$size';

  static Difficulty? fromName(String? name) {
    for (final d in values) {
      if (d.name == name) return d;
    }
    return null;
  }
}
