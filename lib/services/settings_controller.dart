import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty.dart';
import '../models/tile_style.dart';

/// Preferencias del jugador. Se leen una vez al arrancar y cada cambio se
/// guarda al momento en shared_preferences. Como es un ChangeNotifier,
/// las pantallas que lo escuchan se redibujan solas al volver al menu.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _difficulty = Difficulty.fromName(_prefs.getString(_kDifficulty));
    _themeMode = _themeFromName(_prefs.getString(_kTheme));
    _tileStyle = TileStyle.fromName(_prefs.getString(_kTileStyle));
    _animations = _prefs.getBool(_kAnimations) ?? true;
    _sounds = _prefs.getBool(_kSounds) ?? true;
    _timedMode = _prefs.getBool(_kTimedMode) ?? false;
  }

  static const _kDifficulty = 'difficulty';
  static const _kTheme = 'theme_mode';
  static const _kTileStyle = 'tile_style';
  static const _kAnimations = 'animations';
  static const _kSounds = 'sounds';
  static const _kTimedMode = 'timed_mode';

  final SharedPreferences _prefs;

  Difficulty? _difficulty;
  late ThemeMode _themeMode;
  late TileStyle _tileStyle;
  late bool _animations;
  late bool _sounds;
  late bool _timedMode;

  /// null mientras el jugador no haya elegido una dificultad por defecto.
  Difficulty? get savedDifficulty => _difficulty;
  Difficulty get difficulty => _difficulty ?? Difficulty.medium;
  ThemeMode get themeMode => _themeMode;
  TileStyle get tileStyle => _tileStyle;
  bool get animations => _animations;
  bool get sounds => _sounds;
  bool get timedMode => _timedMode;

  Future<void> setDifficulty(Difficulty value) async {
    _difficulty = value;
    notifyListeners();
    await _prefs.setString(_kDifficulty, value.name);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    await _prefs.setString(_kTheme, value.name);
  }

  Future<void> setTileStyle(TileStyle value) async {
    _tileStyle = value;
    notifyListeners();
    await _prefs.setString(_kTileStyle, value.name);
  }

  Future<void> setAnimations(bool value) async {
    _animations = value;
    notifyListeners();
    await _prefs.setBool(_kAnimations, value);
  }

  Future<void> setSounds(bool value) async {
    _sounds = value;
    notifyListeners();
    await _prefs.setBool(_kSounds, value);
  }

  Future<void> setTimedMode(bool value) async {
    _timedMode = value;
    notifyListeners();
    await _prefs.setBool(_kTimedMode, value);
  }

  /// Vuelve a los valores de fabrica (no toca los marcadores).
  Future<void> reset() async {
    for (final key in [
      _kDifficulty,
      _kTheme,
      _kTileStyle,
      _kAnimations,
      _kSounds,
      _kTimedMode,
    ]) {
      await _prefs.remove(key);
    }
    _difficulty = null;
    _themeMode = ThemeMode.system;
    _tileStyle = TileStyle.classic;
    _animations = true;
    _sounds = true;
    _timedMode = false;
    notifyListeners();
  }

  static ThemeMode _themeFromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
