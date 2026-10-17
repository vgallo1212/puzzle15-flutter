import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/difficulty.dart';

/// Hoja inferior para elegir dificultad antes de jugar.
/// Si [askToRemember] es true ofrece guardarla como dificultad por defecto.
Future<Difficulty?> showDifficultyPicker(
  BuildContext context, {
  required Difficulty initial,
  bool askToRemember = true,
}) {
  return showModalBottomSheet<Difficulty>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) =>
        _DifficultySheet(initial: initial, askToRemember: askToRemember),
  );
}

class _DifficultySheet extends StatefulWidget {
  const _DifficultySheet({required this.initial, required this.askToRemember});

  final Difficulty initial;
  final bool askToRemember;

  @override
  State<_DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<_DifficultySheet> {
  late Difficulty _selected = widget.initial;
  bool _remember = true;

  Future<void> _confirm() async {
    if (widget.askToRemember && _remember) {
      await AppScope.settingsOf(context).setDifficulty(_selected);
    }
    if (mounted) Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Qué tan difícil?',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            for (final d in Difficulty.values) ...[
              DifficultyOption(
                difficulty: d,
                selected: d == _selected,
                onTap: () => setState(() => _selected = d),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.askToRemember)
              CheckboxListTile(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Recordar mi elección'),
                subtitle: Text(
                  'Se puede cambiar luego en Configuración',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta seleccionable con el tamano y las piezas de cada dificultad.
/// Tambien la usa la pantalla de configuracion.
class DifficultyOption extends StatelessWidget {
  const DifficultyOption({
    super.key,
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animate = AppScope.settingsOf(context).animations;

    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              _MiniGrid(size: difficulty.size, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${difficulty.gridLabel} · ${difficulty.pieces} piezas',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.size, required this.color});

  final int size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const box = 36.0;
    final cell = box / size;
    return SizedBox(
      width: box,
      height: box,
      child: Wrap(
        children: List.generate(size * size, (i) {
          final last = i == size * size - 1;
          return Container(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: last ? Colors.transparent : color.withValues(alpha: 0.75),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 0.8,
              ),
            ),
          );
        }),
      ),
    );
  }
}
