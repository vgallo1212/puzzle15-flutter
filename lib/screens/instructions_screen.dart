import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../widgets/entrance.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final limits = Difficulty.values
        .map((d) => '${d.label}: ${d.timeLimit.inMinutes} min')
        .join(' · ');

    final sections = [
      const _Section(
        icon: Icons.flag_rounded,
        title: 'Objetivo',
        body:
            'Ordena las piezas en orden numérico (o forma la imagen correcta) '
            'utilizando el espacio vacío para deslizar las piezas adyacentes.',
      ),
      const _Section(
        icon: Icons.touch_app_rounded,
        title: 'Cómo mover',
        body:
            'Toca una pieza que esté junto al espacio vacío y se deslizará hacia él. '
            'Si tocas una pieza de la misma fila o columna, se mueven todas las que '
            'hay en medio, y cada pieza cuenta como un movimiento.\n\n'
            'También puedes deslizar el dedo sobre el tablero o usar las flechas '
            '(o W A S D) del teclado.',
      ),
      const _Section(
        icon: Icons.emoji_events_rounded,
        title: 'Cómo se gana',
        body:
            'Ganas cuando todas las piezas quedan ordenadas de izquierda a derecha '
            'y de arriba hacia abajo (1, 2, 3...) y el espacio vacío queda al final, '
            'en la esquina inferior derecha.',
      ),
      _Section(
        icon: Icons.timer_off_rounded,
        title: 'Cómo se pierde',
        body:
            'En el modo normal no hay forma de perder: tómate tu tiempo. '
            'Si activas el modo contrarreloj en Configuración, pierdes cuando el '
            'tiempo llega a cero ($limits). '
            'También puedes rendirte desde la partida, y cuenta como perdida.',
      ),
      const _Section(
        icon: Icons.timer_rounded,
        title: 'Tiempo y récords',
        body:
            'El cronómetro empieza con tu primer movimiento. Si sales de la app o '
            'cambias de pestaña, la partida se pausa sola. Al ganar se guarda tu '
            'tiempo, tus movimientos y la fecha; si superas tu mejor marca verás '
            '"¡Nuevo récord!".',
      ),
      const _Section(
        icon: Icons.verified_rounded,
        title: '¿Siempre tiene solución?',
        body:
            'Sí. No todas las mezclas del 15-Puzzle se pueden resolver: la mitad '
            'son imposibles. El juego revisa la paridad de las inversiones de cada '
            'tablero y solo te da mezclas que tienen solución.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Cómo jugar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              for (var i = 0; i < sections.length; i++)
                Entrance(
                  delay: Duration(milliseconds: 80 * i),
                  child: sections[i],
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('¡Entendido!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
