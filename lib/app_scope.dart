import 'package:flutter/material.dart';

import 'services/scores_repository.dart';
import 'services/settings_controller.dart';

/// Deja las preferencias y los marcadores al alcance de cualquier pantalla
/// sin tener que pasarlos de constructor en constructor.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.scores,
    required super.child,
  });

  final SettingsController settings;
  final ScoresRepository scores;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay AppScope en el arbol');
    return scope!;
  }

  static SettingsController settingsOf(BuildContext context) =>
      of(context).settings;

  static ScoresRepository scoresOf(BuildContext context) => of(context).scores;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      settings != oldWidget.settings || scores != oldWidget.scores;
}
