import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/difficulty.dart';
import '../theme/app_theme.dart';
import '../utils/transitions.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/entrance.dart';
import '../widgets/game_logo.dart';
import '../widgets/menu_button.dart';
import 'game_screen.dart';
import 'instructions_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _play(BuildContext context, {bool forcePicker = false}) async {
    final settings = AppScope.settingsOf(context);
    var difficulty = settings.savedDifficulty;

    // Si nunca eligio dificultad (o pidio otra) se pregunta antes de jugar.
    if (difficulty == null || forcePicker) {
      difficulty = await showDifficultyPicker(
        context,
        initial: settings.difficulty,
        askToRemember: settings.savedDifficulty == null,
      );
      if (difficulty == null || !context.mounted) return;
    }

    Navigator.of(context).push(
      fadeRoute(
        GameScreen(difficulty: difficulty),
        animate: settings.animations,
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).push(fadeRoute(page, animate: AppScope.settingsOf(context).animations));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = AppScope.settingsOf(context);
    final scores = AppScope.scoresOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(scheme),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                // El subtitulo de "Jugar" muestra la dificultad guardada, asi
                // que se escucha a los ajustes para reflejar cambios al volver.
                child: ListenableBuilder(
                  listenable: Listenable.merge([settings, scores]),
                  builder: (context, _) {
                    final saved = settings.savedDifficulty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Entrance(
                          from: EntranceFrom.top,
                          child: Center(child: GameLogo(size: 96)),
                        ),
                        const SizedBox(height: 20),
                        Entrance(
                          from: EntranceFrom.top,
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            '15-Puzzle',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Entrance(
                          from: EntranceFrom.top,
                          delay: const Duration(milliseconds: 150),
                          child: Text(
                            _bestLine(context, saved),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Entrance(
                          delay: const Duration(milliseconds: 200),
                          child: MenuButton(
                            primary: true,
                            icon: Icons.play_arrow_rounded,
                            label: 'Jugar',
                            subtitle: saved == null
                                ? 'Elige una dificultad'
                                : '${saved.label} · ${saved.gridLabel}'
                                      '${settings.timedMode ? ' · contrarreloj' : ''}',
                            onPressed: () => _play(context),
                          ),
                        ),
                        if (saved != null)
                          Entrance(
                            delay: const Duration(milliseconds: 250),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    _play(context, forcePicker: true),
                                child: const Text('Jugar en otra dificultad'),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        Entrance(
                          delay: const Duration(milliseconds: 500),
                          child: MenuButton(
                            icon: Icons.menu_book_rounded,
                            label: 'Cómo jugar',
                            subtitle: 'Reglas e instrucciones',
                            onPressed: () =>
                                _open(context, const InstructionsScreen()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _bestLine(BuildContext context, Difficulty? saved) {
    final scores = AppScope.scoresOf(context);
    final d = saved ?? Difficulty.medium;
    final best = scores.bestTime(d);
    if (best == null) return 'Ordena las piezas en el menor tiempo posible';
    final secs = best.time.inMilliseconds / 1000;
    return 'Tu récord en ${d.label}: ${secs.toStringAsFixed(1)} s';
  }
}
