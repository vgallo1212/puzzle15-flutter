enum TileStyle {
  classic('Clásico', 'Números sobre fichas de madera'),
  colorful('Colorido', 'Cada ficha con su propio color'),
  retro('Retro', 'Pantalla verde de los 80'),
  minimal('Minimalista', 'Solo bordes y números finos'),
  image('Imagen', 'Arma un paisaje en lugar de números');

  const TileStyle(this.label, this.description);

  final String label;
  final String description;

  static TileStyle fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return TileStyle.classic;
  }
}
