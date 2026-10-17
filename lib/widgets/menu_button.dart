import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Boton grande del menu: se encoge y cambia de color mientras se presiona.
class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onPressed;
  final bool primary;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animate = AppScope.settingsOf(context).animations;

    final base = widget.primary
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final pressedColor = widget.primary
        ? Color.lerp(scheme.primary, Colors.black, 0.18)!
        : scheme.primaryContainer;
    final foreground = widget.primary ? scheme.onPrimary : scheme.onSurface;

    final duration = animate
        ? const Duration(milliseconds: 140)
        : Duration.zero;

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : (_hovered ? 1.02 : 1),
            duration: duration,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: duration,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: _pressed ? pressedColor : base,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(
                      alpha: _pressed ? 0.08 : 0.18,
                    ),
                    blurRadius: _pressed ? 4 : 14,
                    offset: Offset(0, _pressed ? 2 : 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: foreground, size: 28),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: foreground.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
