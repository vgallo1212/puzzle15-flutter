import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/difficulty.dart';
import '../models/tile_style.dart';
import '../services/settings_controller.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/puzzle_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsController _settings;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _settings = AppScope.settingsOf(context);
      _settings.addListener(_onSettingsChanged);
      _listening = true;
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  // Cada ajuste se guarda en el controlador; aqui solo se redibuja la
  // pantalla para que los controles muestren el valor nuevo.
  void _onSettingsChanged() => setState(() {});

  Future<void> _resetSettings() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restablecer ajustes?'),
        content: const Text(
          'La dificultad, el tema y el estilo vuelven a los valores iniciales. '
          'Tus marcadores no se borran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _settings.reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ajustes restablecidos')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _settings.savedDifficulty;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _SectionTitle('Dificultad por defecto'),
              for (final d in Difficulty.values) ...[
                DifficultyOption(
                  difficulty: d,
                  selected: d == selected,
                  onTap: () => _settings.setDifficulty(d),
                ),
                const SizedBox(height: 8),
              ],
              if (selected == null)
                const _Hint('Si no eliges una, se preguntará al tocar Jugar.'),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.hourglass_bottom_rounded),
                  title: const Text('Modo contrarreloj'),
                  subtitle: Text(
                    'Pierdes si no terminas a tiempo: '
                    '${Difficulty.values.map((d) => '${d.label} ${d.timeLimit.inMinutes} min').join(', ')}.',
                  ),
                  value: _settings.timedMode,
                  onChanged: _settings.setTimedMode,
                ),
              ),

              const _SectionTitle('Tema'),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('Claro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Oscuro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('Auto'),
                  ),
                ],
                selected: {_settings.themeMode},
                onSelectionChanged: (s) => _settings.setThemeMode(s.first),
              ),
              const _Hint('Automático sigue el tema de tu dispositivo.'),

              const _SectionTitle('Estilo de las piezas'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 500 ? 5 : 3;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                    children: [
                      for (final style in TileStyle.values)
                        _StyleCard(
                          style: style,
                          selected: style == _settings.tileStyle,
                          onTap: () => _settings.setTileStyle(style),
                        ),
                    ],
                  );
                },
              ),
              _Hint(_settings.tileStyle.description),

              const _SectionTitle('Efectos'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.animation_rounded),
                      title: const Text('Animaciones'),
                      subtitle: const Text(
                        'Transiciones, entradas y deslizamiento de piezas',
                      ),
                      value: _settings.animations,
                      onChanged: _settings.setAnimations,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_rounded),
                      title: const Text('Sonidos y vibración'),
                      subtitle: const Text('Click al mover piezas (en móvil)'),
                      value: _settings.sounds,
                      onChanged: _settings.setSounds,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: _resetSettings,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Restablecer ajustes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final TileStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final side = c.biggest.shortestSide;
                    final tile = (side - 4) / 2;
                    // Muestra 4 fichas de un tablero 3x3 como vista previa.
                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final v in [1, 2, 4, 5])
                              SizedBox(
                                width: tile,
                                height: tile,
                                child: PuzzleTile(
                                  value: v,
                                  boardSize: 3,
                                  style: style,
                                  extent: tile,
                                  inPlace: v == 1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                style.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
