import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/splash_screen.dart';
import 'services/scores_repository.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key, required this.settings, required this.scores});

  final SettingsController settings;
  final ScoresRepository scores;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      scores: scores,
      // Solo este builder escucha los ajustes: al cambiar el tema se
      // reconstruye MaterialApp y todas las pantallas lo reciben.
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return MaterialApp(
            title: '15-Puzzle Flutter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            themeAnimationDuration: settings.animations
                ? const Duration(milliseconds: 300)
                : Duration.zero,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
