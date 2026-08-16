import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Shared QuestLoad widgets — the plastic, launcher-style look used
/// everywhere: buttons, switches, text fields, checkboxes, segmented.
/// One look, every screen, no exceptions.

// ─── QL Button ────────────────────────────────────────────────────
// Solid matte fill, tight border, no glow. Slightly lifts on hover,
// flattens (pressed-in) on press.

class QLButton extends StatefulWidget {
  final String label;
  final Widget? icon;
  final bool loading;
  final VoidCallback? onPressed;

  const QLButton({
    super.key,
    required this.label,
    this.icon,
    this.loading = false,
    this.onPressed,
  });

  @override
  State<QLButton> createState() => _QLButtonState();
}

class _QLButtonState extends State<QLButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    final enabled = widget.onPressed != null;

    Color plastic(Color base, double t) =>
        Color.lerp(base, c.textPrimary, t)!;

    final fill = !enabled
        ? c.cardBorder.withValues(alpha: 0.35)
        : _pressed
        ? plastic(c.surfaceLight, 0.09)
        : _hovered
        ? plastic(c.surfaceLight, 0.05)
        : c.surfaceLight;

    final shadow = !enabled
        ? const <BoxShadow>[]
        : _pressed
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 1,
              offset: const Offset(0, 0),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.22 : 0.15),
              blurRadius: _hovered ? 5 : 4,
              offset: Offset(0, _hovered ? 2 : 1),
            ),
          ];

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.cardBorder),
            boxShadow: shadow,
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.textSecondary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 6),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: enabled ? c.textPrimary : c.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── QL TextField ─────────────────────────────────────────────────

class QLTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const QLTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  State<QLTextField> createState() => _QLTextFieldState();
}

class _QLTextFieldState extends State<QLTextField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? c.accent.withValues(alpha: 0.4) : c.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          style: TextStyle(color: c.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: _hovered
                  ? c.textMuted.withValues(alpha: 0.8)
                  : c.textMuted,
            ),
            prefixIcon: widget.prefixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ─── QL Switch ────────────────────────────────────────────────────

class QLSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const QLSwitch({super.key, required this.value, required this.onChanged});

  @override
  State<QLSwitch> createState() => _QLSwitchState();
}

class _QLSwitchState extends State<QLSwitch> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.value
                ? c.accent.withValues(alpha: 0.3)
                : c.cardBorder.withValues(alpha: 0.5),
            border: Border.all(
              color: widget.value
                  ? c.accent.withValues(alpha: 0.4)
                  : c.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: widget.value ? 22 : 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: _hovered ? 20 : 18,
                  height: _hovered ? 20 : 18,
                  decoration: BoxDecoration(
                    color: c.textPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── QL Checkbox ──────────────────────────────────────────────────
// Same plastic language as the switch: matte box, tight border,
// accent-tinted fill when checked.

class QLCheckbox extends StatelessWidget {
  final bool value;
  final String? label;
  final ValueChanged<bool> onChanged;

  const QLCheckbox({
    super.key,
    required this.value,
    this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    final box = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value
              ? c.accent.withValues(alpha: 0.3)
              : c.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? c.accent.withValues(alpha: 0.4) : c.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: value
            ? Icon(Icons.check_rounded, size: 14, color: c.textPrimary)
            : null,
      ),
    );

    if (label == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          const SizedBox(width: 8),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── QL Segmented ─────────────────────────────────────────────────

class QLSegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  const QLSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (option, label) in options)
            _QLSegment(
              label: label,
              selected: option == value,
              onTap: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _QLSegment extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QLSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_QLSegment> createState() => _QLSegmentState();
}

class _QLSegmentState extends State<_QLSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.selected
                ? c.accent.withValues(alpha: 0.15)
                : _hovered
                ? c.surfaceLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? c.accent : c.textSecondary,
              fontSize: 12,
              fontWeight: widget.selected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
