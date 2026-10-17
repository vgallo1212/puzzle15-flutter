import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/scores_repository.dart';
import 'services/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se cargan las preferencias antes de pintar para que el tema correcto
  // salga desde el primer frame (sin parpadeo claro -> oscuro).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    PuzzleApp(
      settings: SettingsController(prefs),
      scores: ScoresRepository(prefs),
    ),
  );
}
