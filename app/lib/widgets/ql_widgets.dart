import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    Color plastic(Color base, double t) => Color.lerp(base, c.textPrimary, t)!;

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

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
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
    // The InputDecorator owns border, padding and text centering as one
    // unit — no wrapper fighting it. Inter only for the text, so the
    // balanced metrics center the glyphs on every OS.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
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
            hintStyle: TextStyle(color: c.textMuted),
            prefixIcon: widget.prefixIcon,
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _hovered
                    ? c.accent.withValues(alpha: 0.4)
                    : c.cardBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.accent.withValues(alpha: 0.4)),
            ),
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
    return Semantics(
      button: true,
      toggled: widget.value,
      child: MouseRegion(
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
    final box = Semantics(
      button: true,
      checked: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: value ? c.accent.withValues(alpha: 0.3) : c.surfaceLight,
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
      ),
    );

    if (label == null) return box;
    return Semantics(
      button: true,
      checked: value,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          const SizedBox(width: 8),
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
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
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
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
      ),
    );
  }
}

// ─── QL Toast ──────────────────────────────────────────────────────
// Bottom-right matte cards, the plastic look, auto-dismiss. Replaces
// SnackBars everywhere — one look, matches the theme.

enum QLToastKind { info, success, error, warning }

class QLToast {
  QLToast._();

  /// Most toasts allowed on screen at once — older ones fall off the top.
  static const int maxToasts = 3;

  // Live toasts, oldest first. Each carries an offset notifier so its
  // position in the stack can be updated as the stack changes.
  static final List<_ToastEntry> _active = [];

  static void show(
    BuildContext context,
    String message, {
    QLToastKind kind = QLToastKind.info,
  }) {
    // Grab the colors and text style here — the overlay sits outside the
    // app's nested Theme, so the card can't resolve the selected theme.
    final colors = context.ql;
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final overlay = Overlay.of(context, rootOverlay: true);
    final offset = ValueNotifier<int>(0);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _QLToastCard(
        colors: colors,
        textStyle: textStyle,
        message: message,
        kind: kind,
        offset: offset,
        onDismissed: () {
          entry.remove();
          _active.removeWhere((e) => e.overlay == entry);
          _relayout();
        },
      ),
    );
    _active.add(_ToastEntry(entry, offset));
    overlay.insert(entry);
    // New toast sits at the bottom; drop the topmost when the stack is full.
    if (_active.length > maxToasts) {
      _active.removeAt(0).overlay.remove();
    }
    _relayout();
  }

  // Bottom-most toast gets offset 0, each one above gets +1.
  static void _relayout() {
    final n = _active.length;
    for (var i = 0; i < n; i++) {
      _active[i].offset.value = n - 1 - i;
    }
  }
}

class _ToastEntry {
  final OverlayEntry overlay;
  final ValueNotifier<int> offset;

  _ToastEntry(this.overlay, this.offset);
}

class _QLToastCard extends StatefulWidget {
  final QuestLoadColors colors;
  final TextStyle? textStyle;
  final String message;
  final QLToastKind kind;
  final ValueNotifier<int> offset;
  final VoidCallback onDismissed;

  const _QLToastCard({
    required this.colors,
    required this.textStyle,
    required this.message,
    required this.kind,
    required this.offset,
    required this.onDismissed,
  });

  @override
  State<_QLToastCard> createState() => _QLToastCardState();
}

class _QLToastCardState extends State<_QLToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 3500), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    // Art only for the special ones — neutral theme color, never success/
    // error red/green. Normal toasts are just text.
    final icon = switch (widget.kind) {
      QLToastKind.error => Icons.error_outline_rounded,
      QLToastKind.warning => Icons.warning_amber_rounded,
      _ => null,
    };

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ValueListenableBuilder<int>(
          valueListenable: widget.offset,
          builder: (context, off, _) => AnimatedPadding(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: 24 + off * 64.0),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_anim),
              child: FadeTransition(
                opacity: _anim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: c.textSecondary),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Text(widget.message, style: widget.textStyle),
                        ),
                      ],
                    ),
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

// ─── QL Context Menu ─────────────────────────────────────────────
// Desktop context menu in the style of Flutter's text selection toolbar:
// 222px card, 7px radius, 1px elevation, left-aligned 36px items.

class QLContextMenuItem {
  final String label;
  final VoidCallback onTap;

  /// Accent-highlight this item (e.g. an active toggle).
  final bool highlighted;

  const QLContextMenuItem({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });
}

/// Shows a desktop-style context menu at [globalPosition].
void showQLContextMenu(
  BuildContext context,
  Offset globalPosition, {
  required List<QLContextMenuItem> items,
}) {
  if (items.isEmpty) return;
  final colors = context.ql;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _QLContextMenu(
      colors: colors,
      items: items,
      position: globalPosition,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _QLContextMenu extends StatefulWidget {
  final QuestLoadColors colors;
  final List<QLContextMenuItem> items;
  final Offset position;
  final VoidCallback onDismiss;

  const _QLContextMenu({
    required this.colors,
    required this.items,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_QLContextMenu> createState() => _QLContextMenuState();
}

class _QLContextMenuState extends State<_QLContextMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 290),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double width = 222.0;
    const double itemHeight = 36.0;
    final size = MediaQuery.sizeOf(context);
    final height = widget.items.length * itemHeight;
    final left = widget.position.dx.clamp(8.0, size.width - width - 8.0);
    final top = widget.position.dy.clamp(8.0, size.height - height - 8.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: _opacity,
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  widget.onDismiss();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Material(
                color: widget.colors.card,
                borderRadius: BorderRadius.circular(7),
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in widget.items)
                        _QLContextMenuItemButton(
                          label: item.label,
                          colors: widget.colors,
                          highlighted: item.highlighted,
                          onTap: () {
                            item.onTap();
                            widget.onDismiss();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QLContextMenuItemButton extends StatelessWidget {
  final String label;
  final QuestLoadColors colors;
  final bool highlighted;
  final VoidCallback onTap;

  const _QLContextMenuItemButton({
    required this.label,
    required this.colors,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: InkWell(
        onTap: onTap,
        hoverColor: c.textPrimary.withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          height: 36,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 3),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              letterSpacing: -0.15,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
              color: highlighted ? c.accent : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── QL Dialog ────────────────────────────────────────────────────
// Clean custom dialog: a card with a title up top and two actions spread
// left and right. No Material dialog chrome.

class QLDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final Widget leftAction;
  final Widget rightAction;

  const QLDialog({
    super.key,
    this.title,
    required this.content,
    required this.leftAction,
    required this.rightAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return Container(
      width: 380,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          content,
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [leftAction, rightAction],
          ),
        ],
      ),
    );
  }
}

/// Shows a [QLDialog] in a modal barrier.
Future<T?> showQLDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required Widget leftAction,
  required Widget rightAction,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Center(
      child: QLDialog(
        title: title,
        content: content,
        leftAction: leftAction,
        rightAction: rightAction,
      ),
    ),
  );
}
