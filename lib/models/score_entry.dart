class ScoreEntry {
  const ScoreEntry({
    required this.time,
    required this.moves,
    required this.date,
    this.timed = false,
  });

  final Duration time;
  final int moves;
  final DateTime date;

  /// true si la partida se jugo en modo contrarreloj.
  final bool timed;

  Map<String, dynamic> toJson() => {
    'ms': time.inMilliseconds,
    'moves': moves,
    'date': date.toIso8601String(),
    'timed': timed,
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      time: Duration(milliseconds: json['ms'] as int),
      moves: json['moves'] as int,
      date: DateTime.parse(json['date'] as String),
      timed: json['timed'] as bool? ?? false,
    );
  }
}
