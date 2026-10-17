import 'dart:math';

import 'package:flutter/material.dart';

/// Paisaje dibujado a mano para el modo Imagen. Se dibuja por codigo y no
/// con un PNG para que se vea nitido a cualquier tamano y funcione offline.
void paintScene(Canvas canvas, Size size, {required bool dark}) {
  final w = size.width;
  final h = size.height;

  final sky = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? const [Color(0xFF0B1033), Color(0xFF3B2A6B), Color(0xFFB45C7A)]
          : const [Color(0xFF5FB4FF), Color(0xFFA9D8FF), Color(0xFFFFD7A8)],
    ).createShader(Offset.zero & size);
  canvas.drawRect(Offset.zero & size, sky);

  if (dark) {
    final star = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final rnd = Random(7);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.45),
        rnd.nextDouble() * 1.4 + 0.4,
        star,
      );
    }
  }

  // Sol o luna
  final sunCenter = Offset(w * 0.72, h * 0.28);
  canvas.drawCircle(
    sunCenter,
    w * 0.16,
    Paint()
      ..color = (dark ? Colors.white : const Color(0xFFFFE07A)).withValues(
        alpha: 0.25,
      ),
  );
  canvas.drawCircle(
    sunCenter,
    w * 0.1,
    Paint()..color = dark ? const Color(0xFFF4F1E1) : const Color(0xFFFFC93C),
  );

  // Montanas del fondo
  final back = Path()
    ..moveTo(0, h * 0.62)
    ..lineTo(w * 0.18, h * 0.38)
    ..lineTo(w * 0.34, h * 0.55)
    ..lineTo(w * 0.52, h * 0.32)
    ..lineTo(w * 0.74, h * 0.58)
    ..lineTo(w * 0.88, h * 0.44)
    ..lineTo(w, h * 0.56)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  canvas.drawPath(
    back,
    Paint()..color = dark ? const Color(0xFF2B2557) : const Color(0xFF7A8CC9),
  );

  // Nieve en los picos
  final snow = Paint()
    ..color = Colors.white.withValues(alpha: dark ? 0.6 : 0.9);
  canvas.drawPath(
    Path()
      ..moveTo(w * 0.52, h * 0.32)
      ..lineTo(w * 0.46, h * 0.39)
      ..lineTo(w * 0.5, h * 0.38)
      ..lineTo(w * 0.53, h * 0.41)
      ..lineTo(w * 0.57, h * 0.38)
      ..close(),
    snow,
  );
  canvas.drawPath(
    Path()
      ..moveTo(w * 0.18, h * 0.38)
      ..lineTo(w * 0.13, h * 0.44)
      ..lineTo(w * 0.17, h * 0.43)
      ..lineTo(w * 0.2, h * 0.45)
      ..lineTo(w * 0.23, h * 0.44)
      ..close(),
    snow,
  );

  // Colinas
  final hills = Path()
    ..moveTo(0, h * 0.74)
    ..quadraticBezierTo(w * 0.25, h * 0.6, w * 0.5, h * 0.72)
    ..quadraticBezierTo(w * 0.75, h * 0.84, w, h * 0.68)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  canvas.drawPath(
    hills,
    Paint()..color = dark ? const Color(0xFF1C3B3A) : const Color(0xFF5DBB63),
  );

  // Lago
  final lake = Rect.fromLTWH(w * 0.08, h * 0.82, w * 0.55, h * 0.1);
  canvas.drawOval(
    lake,
    Paint()..color = dark ? const Color(0xFF3B4C8C) : const Color(0xFF4FA6E8),
  );

  // Pinos
  final treePaint = Paint()
    ..color = dark ? const Color(0xFF0F2422) : const Color(0xFF2E7D32);
  for (final x in [0.7, 0.78, 0.86, 0.93]) {
    final base = h * (0.86 + (x - 0.7) * 0.1);
    final height = h * 0.17;
    canvas.drawPath(
      Path()
        ..moveTo(w * x, base - height)
        ..lineTo(w * x - w * 0.045, base)
        ..lineTo(w * x + w * 0.045, base)
        ..close(),
      treePaint,
    );
  }
}

/// Pinta solo el pedazo del paisaje que le toca a la ficha [value].
class SceneSlicePainter extends CustomPainter {
  SceneSlicePainter({
    required this.value,
    required this.boardSize,
    required this.dark,
  });

  final int value;
  final int boardSize;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final goal = value - 1;
    final row = goal ~/ boardSize;
    final col = goal % boardSize;
    final full = Size(size.width * boardSize, size.height * boardSize);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-col * size.width, -row * size.height);
    paintScene(canvas, full, dark: dark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SceneSlicePainter old) =>
      old.value != value || old.boardSize != boardSize || old.dark != dark;
}

/// Imagen completa, para la vista previa de "como deberia quedar".
class ScenePainter extends CustomPainter {
  ScenePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) => paintScene(canvas, size, dark: dark);

  @override
  bool shouldRepaint(ScenePainter old) => old.dark != dark;
}
