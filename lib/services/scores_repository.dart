import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty.dart';
import '../models/score_entry.dart';

/// Que records rompio una partida recien ganada.
class RecordResult {
  const RecordResult({required this.bestTime, required this.fewestMoves});

  final bool bestTime;
  final bool fewestMoves;

  bool get any => bestTime || fewestMoves;
}

/// Guarda las partidas ganadas por dificultad (las 10 mejores por tiempo).
class ScoresRepository extends ChangeNotifier {
  ScoresRepository(this._prefs) {
    for (final d in Difficulty.values) {
      _entries[d] = _read(d);
    }
  }

  static const maxEntries = 10;

  final SharedPreferences _prefs;
  final Map<Difficulty, List<ScoreEntry>> _entries = {};

  String _key(Difficulty d) => 'scores_${d.name}';

  List<ScoreEntry> _read(Difficulty d) {
    final raw = _prefs.getString(_key(d));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Si el dato esta corrupto se descarta en vez de romper la app.
      return [];
    }
  }

  List<ScoreEntry> entriesFor(Difficulty d) => List.unmodifiable(_entries[d]!);

  bool get isEmpty => _entries.values.every((list) => list.isEmpty);

  ScoreEntry? bestTime(Difficulty d) {
    final list = _entries[d]!;
    if (list.isEmpty) return null;
    return list.reduce((a, b) => b.time < a.time ? b : a);
  }

  ScoreEntry? fewestMoves(Difficulty d) {
    final list = _entries[d]!;
    if (list.isEmpty) return null;
    return list.reduce((a, b) => b.moves < a.moves ? b : a);
  }

  Future<RecordResult> addWin(Difficulty d, ScoreEntry entry) async {
    final previousTime = bestTime(d);
    final previousMoves = fewestMoves(d);

    final result = RecordResult(
      bestTime: previousTime == null || entry.time < previousTime.time,
      fewestMoves: previousMoves == null || entry.moves < previousMoves.moves,
    );

    final list = _entries[d]!..add(entry);
    list.sort((a, b) {
      final byTime = a.time.compareTo(b.time);
      return byTime != 0 ? byTime : a.moves.compareTo(b.moves);
    });

    // El record de movimientos no siempre esta entre los 10 mas rapidos,
    // asi que se conserva aparte para no perderlo al recortar.
    final keepMoves = fewestMoves(d);
    if (list.length > maxEntries) {
      list.removeRange(maxEntries, list.length);
      if (keepMoves != null && !list.contains(keepMoves)) {
        list[list.length - 1] = keepMoves;
      }
    }

    notifyListeners();
    await _prefs.setString(
      _key(d),
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    return result;
  }

  Future<void> clearAll() async {
    for (final d in Difficulty.values) {
      _entries[d] = [];
      await _prefs.remove(_key(d));
    }
    notifyListeners();
  }
}
