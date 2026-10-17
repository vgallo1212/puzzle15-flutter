import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/puzzle_board.dart';
import '../models/difficulty.dart';
import '../models/score_entry.dart';
import '../models/tile_style.dart';
import '../utils/feedback.dart';
import '../utils/format.dart';
import '../widgets/board_view.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/scene_painter.dart';

enum GameStatus { ready, playing, paused, won, lost }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.difficulty, this.initialBoard});

  final Difficulty difficulty;

  /// Solo para los tests: permite empezar con un tablero conocido.
  @visibleForTesting
  final PuzzleBoard? initialBoard;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PuzzleBoard _board;
  GameStatus _status = GameStatus.ready;
  int _moves = 0;

  /// Contrarreloj se fija al empezar la partida: cambiarlo en ajustes
  /// no afecta una partida que ya esta en curso.
  late bool _timed;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  // El reloj cambia varias veces por segundo; con un ValueNotifier solo se
  // redibuja el texto del tiempo y no todo el tablero.
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);

  final FocusNode _focusNode = FocusNode(debugLabel: 'tablero');
  late final AppLifecycleListener _lifecycle;
  bool _peekImage = false;

  Difficulty get _difficulty => widget.difficulty;

  @override
  void initState() {
    super.initState();
    _board = widget.initialBoard ?? PuzzleBoard.shuffled(_difficulty.size);
    // Si el jugador cambia de pestana o minimiza, la partida se pausa sola.
    _lifecycle = AppLifecycleListener(
      onHide: _autoPause,
      onInactive: _autoPause,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timed = _status == GameStatus.ready
        ? AppScope.settingsOf(context).timedMode
        : _timed;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    _elapsed.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _inProgress =>
      _status == GameStatus.playing || _status == GameStatus.paused;

  void _startClock() {
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _stopClock() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _elapsed.value = _stopwatch.elapsed;
  }

  void _tick() {
    _elapsed.value = _stopwatch.elapsed;
    if (_timed && _stopwatch.elapsed >= _difficulty.timeLimit) {
      _lose('Se acabó el tiempo');
    }
  }

  void _onTileTap(int index) {
    if (_status != GameStatus.ready && _status != GameStatus.playing) return;
    _applyMove(_board.moveTile(index));
  }

  void _onSlide(SlideDirection direction) {
    if (_status != GameStatus.ready && _status != GameStatus.playing) return;
    _applyMove(_board.slide(direction));
  }

  void _applyMove(int moved) {
    final sounds = AppScope.settingsOf(context).sounds;
    if (moved == 0) {
      GameFeedback.invalid(sounds);
      return;
    }
    GameFeedback.move(sounds);

    setState(() {
      _moves += moved;
      if (_status == GameStatus.ready) {
        // El cronometro arranca con el primer movimiento, no al abrir.
        _status = GameStatus.playing;
        _startClock();
      }
    });

    if (_board.isSolved) _win();
  }

  Future<void> _win() async {
    _stopClock();
    setState(() => _status = GameStatus.won);

    final settings = AppScope.settingsOf(context);
    final scores = AppScope.scoresOf(context);
    GameFeedback.win(settings.sounds);

    final time = _stopwatch.elapsed;
    final record = await scores.addWin(
      _difficulty,
      ScoreEntry(
        time: time,
        moves: _moves,
        date: DateTime.now(),
        timed: _timed,
      ),
    );

    // Se deja terminar la animacion de la ultima ficha antes del dialogo.
    await Future.delayed(
      Duration(milliseconds: settings.animations ? 450 : 50),
    );
    if (!mounted) return;
    _showEnd(won: true, newRecord: record.any);
  }

  void _lose(String reason) {
    if (!_inProgress && _status != GameStatus.ready) return;
    _stopClock();
    setState(() => _status = GameStatus.lost);
    _showEnd(won: false, newRecord: false, reason: reason);
  }

  Future<void> _showEnd({
    required bool won,
    required bool newRecord,
    String? reason,
  }) async {
    final action = await showGameOverDialog(
      context,
      won: won,
      time: _stopwatch.elapsed,
      moves: _moves,
      difficulty: _difficulty,
      newRecord: newRecord,
      animate: AppScope.settingsOf(context).animations,
      reason: reason,
    );
    if (!mounted) return;
    switch (action) {
      case GameOverAction.restart:
        _restart();
      case GameOverAction.menu:
        Navigator.of(context).pop();
      case GameOverAction.keepBoard:
      case null:
        _focusNode.requestFocus();
    }
  }

  void _restart() {
    _stopClock();
    _stopwatch.reset();
    setState(() {
      _board = PuzzleBoard.shuffled(_difficulty.size);
      _moves = 0;
      _status = GameStatus.ready;
      _timed = AppScope.settingsOf(context).timedMode;
    });
    _elapsed.value = Duration.zero;
    _focusNode.requestFocus();
  }

  void _autoPause() {
    if (_status == GameStatus.playing) _pause();
  }

  void _pause() {
    _stopClock();
    setState(() => _status = GameStatus.paused);
  }

  void _resume() {
    setState(() => _status = GameStatus.playing);
    _startClock();
    _focusNode.requestFocus();
  }

  Future<bool> _confirm(
    String title,
    String message,
    String confirmText,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _askRestart() async {
    if (!_inProgress) return _restart();
    final wasPlaying = _status == GameStatus.playing;
    if (wasPlaying) _pause();
    final ok = await _confirm(
      '¿Reiniciar partida?',
      'Se mezclará un tablero nuevo y perderás el progreso actual.',
      'Reiniciar',
    );
    if (!mounted) return;
    if (ok) {
      _restart();
    } else if (wasPlaying) {
      _resume();
    }
  }

  Future<void> _askSurrender() async {
    final wasPlaying = _status == GameStatus.playing;
    if (wasPlaying) _pause();
    final ok = await _confirm(
      '¿Rendirte?',
      'La partida contará como perdida y no se guardará en los marcadores.',
      'Rendirme',
    );
    if (!mounted) return;
    if (ok) {
      _lose('Te rendiste');
    } else if (wasPlaying) {
      _resume();
    }
  }

  Future<void> _handleBack() async {
    final wasPlaying = _status == GameStatus.playing;
    if (wasPlaying) _pause();
    final ok = await _confirm(
      '¿Salir de la partida?',
      'Llevas $_moves movimientos. Si sales ahora se pierde esta partida.',
      'Salir',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else if (wasPlaying) {
      _resume();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyP) {
      if (_status == GameStatus.playing) {
        _pause();
      } else if (_status == GameStatus.paused) {
        _resume();
      }
      return KeyEventResult.handled;
    }

    final direction = switch (key) {
      LogicalKeyboardKey.arrowUp ||
      LogicalKeyboardKey.keyW => SlideDirection.up,
      LogicalKeyboardKey.arrowDown ||
      LogicalKeyboardKey.keyS => SlideDirection.down,
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.keyA => SlideDirection.left,
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.keyD => SlideDirection.right,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    _onSlide(direction);
    return KeyEventResult.handled;
  }

  void _onSwipe(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    if (v.distance < 250) return;
    if (v.dx.abs() > v.dy.abs()) {
      _onSlide(v.dx > 0 ? SlideDirection.right : SlideDirection.left);
    } else {
      _onSlide(v.dy > 0 ? SlideDirection.down : SlideDirection.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);

    return PopScope(
      canPop: !_inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${_difficulty.label} · ${_difficulty.gridLabel}'),
            actions: [
              if (_inProgress)
                IconButton(
                  tooltip: _status == GameStatus.paused ? 'Reanudar' : 'Pausa',
                  onPressed: _status == GameStatus.paused ? _resume : _pause,
                  icon: Icon(
                    _status == GameStatus.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 760 &&
                    constraints.maxWidth > constraints.maxHeight;
                return wide
                    ? _buildWide(
                        constraints,
                        settings.tileStyle,
                        settings.animations,
                      )
                    : _buildNarrow(
                        constraints,
                        settings.tileStyle,
                        settings.animations,
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Movil o tablet en vertical: estadisticas arriba, tablero, botones abajo.
  Widget _buildNarrow(BoxConstraints c, TileStyle style, bool animate) {
    const reserved = 240.0;
    final extent = min(
      c.maxWidth - 32,
      c.maxHeight - reserved,
    ).clamp(200.0, 620.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: extent),
          child: Column(
            children: [
              _StatsBar(
                moves: _moves,
                elapsed: _elapsed,
                limit: _timed ? _difficulty.timeLimit : null,
                inPlace: _board.tilesInPlace,
                total: _difficulty.pieces,
              ),
              const SizedBox(height: 16),
              _buildBoard(extent, style, animate),
              _buildHint(),
              _buildControls(style, horizontal: true),
            ],
          ),
        ),
      ),
    );
  }

  /// Escritorio o tablet en horizontal: tablero a la izquierda, panel a la derecha.
  Widget _buildWide(BoxConstraints c, TileStyle style, bool animate) {
    final extent = (c.maxHeight - 48).clamp(240.0, 680.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBoard(extent, style, animate),
            const SizedBox(width: 32),
            SizedBox(
              width: 260,
              height: extent,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsBar(
                      vertical: true,
                      moves: _moves,
                      elapsed: _elapsed,
                      limit: _timed ? _difficulty.timeLimit : null,
                      inPlace: _board.tilesInPlace,
                      total: _difficulty.pieces,
                    ),
                    _buildHint(),
                    _buildControls(style, horizontal: false),
                    const SizedBox(height: 16),
                    Text(
                      'Usa las flechas o WASD para mover y Espacio para pausar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(double extent, TileStyle style, bool animate) {
    final scheme = Theme.of(context).colorScheme;
    final paused = _status == GameStatus.paused;
    final solved = _status == GameStatus.won;

    return SizedBox(
      width: extent,
      height: extent,
      child: Stack(
        children: [
          GestureDetector(
            onPanEnd: _onSwipe,
            child: BoardView(
              board: _board,
              style: style,
              extent: extent,
              animate: animate,
              enabled:
                  _status == GameStatus.ready || _status == GameStatus.playing,
              solved: solved,
              onTileTap: _onTileTap,
            ),
          ),
          if (style == TileStyle.image && _peekImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(extent * 0.05),
              child: CustomPaint(
                size: Size.square(extent),
                painter: ScenePainter(
                  dark: scheme.brightness == Brightness.dark,
                ),
              ),
            ),
          // En pausa se tapa el tablero para que no se pueda pensar gratis.
          if (paused)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(extent * 0.05),
                child: Container(
                  color: scheme.surface.withValues(alpha: 0.96),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_rounded,
                        size: 64,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pausa',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _resume,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Reanudar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Linea de ayuda bajo el tablero; ocupa siempre lo mismo para que
  /// los botones no salten al empezar a jugar.
  Widget _buildHint() {
    final scheme = Theme.of(context).colorScheme;
    final text = switch (_status) {
      GameStatus.ready => 'El tiempo corre con tu primer movimiento',
      GameStatus.won => '¡Resuelto!',
      GameStatus.lost => 'Partida perdida',
      _ => '',
    };
    return SizedBox(
      height: 44,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _status == GameStatus.won
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: _status == GameStatus.won
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(TileStyle style, {required bool horizontal}) {
    final finished = _status == GameStatus.won || _status == GameStatus.lost;

    final buttons = <Widget>[
      if (finished)
        FilledButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Nueva partida'),
        )
      else
        OutlinedButton.icon(
          onPressed: _askRestart,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Mezclar'),
        ),
      if (style == TileStyle.image)
        // Mantener presionado para ver la imagen completa.
        GestureDetector(
          onTapDown: (_) => setState(() => _peekImage = true),
          onTapUp: (_) => setState(() => _peekImage = false),
          onTapCancel: () => setState(() => _peekImage = false),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.image_outlined),
            label: const Text('Ver imagen'),
          ),
        ),
      if (_inProgress)
        TextButton.icon(
          onPressed: _askSurrender,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Rendirse'),
        ),
      if (finished)
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Menú'),
        ),
    ];

    if (horizontal) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: buttons,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buttons) ...[b, const SizedBox(height: 10)],
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.moves,
    required this.elapsed,
    required this.limit,
    required this.inPlace,
    required this.total,
    this.vertical = false,
  });

  final int moves;
  final ValueNotifier<Duration> elapsed;
  final Duration? limit;
  final int inPlace;
  final int total;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final clock = ValueListenableBuilder<Duration>(
      valueListenable: elapsed,
      builder: (context, value, _) {
        if (limit == null) {
          return _Stat(
            icon: Icons.timer_outlined,
            label: 'Tiempo',
            value: formatClock(value),
          );
        }
        final left = limit! - value;
        final remaining = left.isNegative ? Duration.zero : left;
        final danger = remaining.inSeconds < 30;
        return _Stat(
          icon: Icons.hourglass_bottom_rounded,
          label: 'Restante',
          value: formatClock(remaining + const Duration(milliseconds: 999)),
          color: danger ? scheme.error : null,
        );
      },
    );

    final items = [
      _Stat(
        icon: Icons.swap_horiz_rounded,
        label: 'Movimientos',
        value: '$moves',
      ),
      clock,
      _Stat(
        icon: Icons.check_circle_outline_rounded,
        label: 'En su sitio',
        value: '$inPlace/$total',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: item,
                    ),
                  const SizedBox(height: 4),
                  _Progress(value: inPlace / total),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      for (final item in items)
                        Expanded(
                          child: FittedBox(fit: BoxFit.scaleDown, child: item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Progress(value: inPlace / total),
                ],
              ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(value: value, minHeight: 6),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color ?? scheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
