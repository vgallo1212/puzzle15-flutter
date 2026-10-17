import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/transitions.dart';
import '../widgets/entrance.dart';
import '../widgets/game_logo.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null) {
      final animate = AppScope.settingsOf(context).animations;
      _timer = Timer(Duration(milliseconds: animate ? 2600 : 1200), _goToMenu);
    }
  }

  void _goToMenu() {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    final animate = AppScope.settingsOf(context).animations;
    Navigator.of(context)
        .pushReplacement(fadeRoute(const MenuScreen(), animate: animate));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = (shortest * 0.32).clamp(110.0, 180.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(scheme),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Entrance(
                      from: EntranceFrom.zoom,
                      child: GameLogo(size: logoSize),
                    ),
                    const SizedBox(height: 32),
                    Entrance(
                      delay: const Duration(milliseconds: 350),
                      child: Text(
                        '15-Puzzle Flutter',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Entrance(
                      delay: const Duration(milliseconds: 600),
                      child: Text(
                        'Desliza, ordena y gana',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 8,
                child: TextButton.icon(
                  onPressed: _goToMenu,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Saltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
