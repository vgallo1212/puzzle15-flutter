import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/difficulty.dart';
import '../models/score_entry.dart';
import '../services/scores_repository.dart';
import '../utils/format.dart';
import '../widgets/entrance.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  Future<void> _clearAll(ScoresRepository scores) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: const Text('¿Borrar todos los marcadores?'),
        content: const Text(
          'Se eliminarán los récords de las tres dificultades. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await scores.clearAll();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Marcadores borrados')));
  }

  @override
  Widget build(BuildContext context) {
    final scores = AppScope.scoresOf(context);
    final settings = AppScope.settingsOf(context);
    final initialTab = Difficulty.values.indexOf(settings.difficulty);

    return DefaultTabController(
      length: Difficulty.values.length,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marcadores'),
          actions: [
            if (!scores.isEmpty)
              IconButton(
                tooltip: 'Borrar marcadores',
                onPressed: () => _clearAll(scores),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            tabs: [
              for (final d in Difficulty.values)
                Tab(text: '${d.label} ${d.gridLabel}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final d in Difficulty.values)
              _DifficultyScores(difficulty: d, scores: scores),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al menú'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyScores extends StatelessWidget {
  const _DifficultyScores({required this.difficulty, required this.scores});

  final Difficulty difficulty;
  final ScoresRepository scores;

  @override
  Widget build(BuildContext context) {
    final entries = scores.entriesFor(difficulty);
    if (entries.isEmpty) return _EmptyScores(difficulty: difficulty);

    final best = scores.bestTime(difficulty)!;
    final fewest = scores.fewestMoves(difficulty)!;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Entrance(
                      child: _RecordCard(
                        icon: Icons.timer_rounded,
                        title: 'Mejor tiempo',
                        value: formatDuration(best.time),
                        detail: '${best.moves} movimientos',
                        date: best.date,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Entrance(
                      delay: const Duration(milliseconds: 100),
                      child: _RecordCard(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Menos movimientos',
                        value: '${fewest.moves}',
                        detail: 'en ${formatDuration(fewest.time)}',
                        date: fewest.date,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mejores partidas',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    _EntryRow(position: i + 1, entry: entries[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ordenadas por tiempo. Las partidas en contrarreloj llevan un reloj de arena.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.date,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.onPrimaryContainer),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              detail,
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(date),
              style: TextStyle(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.position, required this.entry});

  final int position;
  final ScoreEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final medal = switch (position) {
      1 => const Color(0xFFFFC23C),
      2 => const Color(0xFFB8C2CC),
      3 => const Color(0xFFCD8B5A),
      _ => scheme.surfaceContainerHighest,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: medal,
        foregroundColor: position <= 3 ? Colors.black87 : scheme.onSurface,
        child: Text(
          '$position',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text.rich(
        TextSpan(
          text: formatDuration(entry.time),
          style: const TextStyle(fontWeight: FontWeight.w600),
          children: [
            if (entry.timed)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
      subtitle: Text(formatDate(entry.date)),
      trailing: Text('${entry.moves} mov.'),
    );
  }
}

class _EmptyScores extends StatelessWidget {
  const _EmptyScores({required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Entrance(
          from: EntranceFrom.zoom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: scheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Todavía no hay récords en ${difficulty.label}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Gana una partida de ${difficulty.gridLabel} y tu tiempo aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
