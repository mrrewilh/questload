import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:silky_scroll/silky_scroll.dart';
import '../l10n/app_localizations.dart';
import '../services/adb_service.dart';
import '../services/log_service.dart';
import '../core/app_theme.dart';
import '../services/theme_service.dart';
import '../core/constants.dart';
import '../widgets/ql_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final AdbService adb;
  final VoidCallback onToggleLayout;
  final VoidCallback onToggleSmoothScroll;
  final bool isSidebarLayout;
  final bool smoothScroll;
  final String themeId;
  final String themeMode;
  final ThemeService themes;
  final ValueChanged<String> onSelectTheme;
  final ValueChanged<String> onSelectThemeMode;
  final bool updateAutoCheck;
  final VoidCallback onToggleUpdateAutoCheck;
  final VoidCallback onCheckForUpdates;

  const SettingsScreen({
    super.key,
    required this.adb,
    required this.onToggleLayout,
    required this.onToggleSmoothScroll,
    this.isSidebarLayout = true,
    this.smoothScroll = true,
    required this.themeId,
    this.themeMode = 'auto',
    required this.themes,
    required this.onSelectTheme,
    required this.onSelectThemeMode,
    this.updateAutoCheck = true,
    required this.onToggleUpdateAutoCheck,
    required this.onCheckForUpdates,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pairIpCtrl = TextEditingController();
  final TextEditingController _pairCodeCtrl = TextEditingController();
  final TextEditingController _connectIpCtrl = TextEditingController();
  bool _pairing = false;
  bool _connecting = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      // no package metadata (e.g. running raw) — leave blank
    }
  }

  @override
  void dispose() {
    _pairIpCtrl.dispose();
    _pairCodeCtrl.dispose();
    _connectIpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.smoothScroll
          ? SilkyListView(
              padding: const EdgeInsets.all(24),
              children: _content(),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: _content(),
            ),
    );
  }

  List<Widget> _content() {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    final textTheme = Theme.of(context).textTheme;

    return [
          // ─── Appearance ──────────────────────────────────────────
          Text(l.appearance, style: textTheme.titleLarge),
          const SizedBox(height: 12.0),
          _SectionCard(
            c: c,
            children: [
              _SettingRow(
                title: l.toggleLayout,
                subtitle: widget.isSidebarLayout ? l.sidebar : l.compactMode,
                trailing: QLSwitch(
                  value: widget.isSidebarLayout,
                  onChanged: (_) => widget.onToggleLayout(),
                ),
              ),
              const SizedBox(height: 12),
              _SettingRow(
                title: l.smoothScroll,
                subtitle: widget.smoothScroll
                    ? l.smoothScrollOn
                    : l.smoothScrollOff,
                trailing: QLSwitch(
                  value: widget.smoothScroll,
                  onChanged: (_) => widget.onToggleSmoothScroll(),
                ),
              ),
              const SizedBox(height: 12),
              _ThemePicker(
                themes: widget.themes,
                selectedId: widget.themeId,
                isSidebarLayout: widget.isSidebarLayout,
                smoothScroll: widget.smoothScroll,
                onSelect: widget.onSelectTheme,
              ),
              if (widget.themeId == 'questload') ...[
                const SizedBox(height: 12),
                _ThemeModeRow(
                  mode: widget.themeMode,
                  onChanged: widget.onSelectThemeMode,
                ),
              ],
            ],
          ),

          // ─── Update ─────────────────────────────────────────────
          const SizedBox(height: 24),
          Text(l.updates, style: textTheme.titleLarge),
          const SizedBox(height: 12.0),
          _SectionCard(
            c: c,
            children: [
              _SettingRow(
                title: l.updateAutoCheck,
                subtitle: '',
                trailing: QLSwitch(
                  value: widget.updateAutoCheck,
                  onChanged: (_) => widget.onToggleUpdateAutoCheck(),
                ),
              ),
              const SizedBox(height: 8),
              QLButton(
                label: l.updateCheck,
                loading: false,
                onPressed: widget.onCheckForUpdates,
              ),
            ],
          ),

          // ─── Advanced (pair + connect) ───────────────────────────
          const SizedBox(height: 24),
          Text(l.advanced, style: textTheme.titleLarge),
          const SizedBox(height: 12.0),
          _SectionCard(
            c: c,
            children: [
              Text(l.pairWithCode, style: textTheme.bodyLarge),
              const SizedBox(height: 8.0),
              Text(l.pairWithCodeInstructions, style: textTheme.bodySmall),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: QLTextField(
                        controller: _pairIpCtrl,
                        hint: 'IP:Port (e.g. 192.168.1.100:42831)',
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: QLTextField(
                        controller: _pairCodeCtrl,
                        hint: 'Code',
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    QLButton(
                      label: l.pair,
                      loading: _pairing,
                      onPressed: _pairing ? null : _doPair,
                    ),
                  ],
                ),
              ),
              Divider(height: 24, color: c.cardBorder),
              Text(l.connectDevice, style: textTheme.bodyLarge),
              const SizedBox(height: 8.0),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: QLTextField(
                        controller: _connectIpCtrl,
                        hint: '192.168.1.100',
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    QLButton(
                      label: l.connect,
                      loading: _connecting,
                      onPressed: _connecting ? null : _doConnect,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ─── Logs ───────────────────────────────────────────────
          const SizedBox(height: 24),
          Row(
            children: [
              Text(l.logs, style: textTheme.titleLarge),
              const Spacer(),
              QLButton(
                label: l.copy,
                icon: Icon(Icons.copy, size: 14, color: c.textSecondary),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: LogService.exportAll()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.logsCopied),
                      backgroundColor: c.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _LogBox(c: c, textTheme: textTheme, l: l),

          // ─── About ───────────────────────────────────────────────
          const SizedBox(height: 24),
          Text(l.about, style: textTheme.titleLarge),
          const SizedBox(height: 12.0),
          _SectionCard(
            c: c,
            children: [
              _infoRow(l.version, _appVersion.isEmpty ? '—' : _appVersion),
              const SizedBox(height: 4.0),
              _infoRow(l.framework, _frameworkString()),
              const SizedBox(height: 4.0),
              _infoRow(l.platform, _platformString()),
            ],
          ),
          const SizedBox(height: 32),
    ];
  }

  Future<void> _doPair() async {
    final ipPort = _pairIpCtrl.text.trim();
    final code = _pairCodeCtrl.text.trim();
    if (ipPort.isEmpty || code.isEmpty) return;

    final l = AppLocalizations.of(context)!;
    final c = context.ql;

    if (!ipPort.contains(':') || ipPort.split(':').length != 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.invalidPairAddress),
          backgroundColor: c.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final parts = ipPort.split(':');
    final ip = parts[0].trim();
    final port = int.tryParse(parts[1].trim());
    if (port == null || ip.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.invalidPairAddress),
          backgroundColor: c.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _pairing = true);
    final result = await widget.adb.pair(ip, port, code);
    if (!mounted) return;
    setState(() => _pairing = false);

    ScaffoldMessenger.of(context).clearSnackBars();
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.pairedSuccessfully),
          backgroundColor: c.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _connectIpCtrl.text = ip;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? l.pairingFailed),
          backgroundColor: c.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _doConnect() async {
    var input = _connectIpCtrl.text.trim();
    if (input.isEmpty) return;

    String ip = input;
    int port = kDefaultAdbPort;
    if (input.contains(':')) {
      final parts = input.split(':');
      ip = parts[0].trim();
      port = int.tryParse(parts[1].trim()) ?? kDefaultAdbPort;
    }

    setState(() => _connecting = true);
    final result = await widget.adb.connect(ip, port: port);
    if (!mounted) return;
    setState(() => _connecting = false);

    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    ScaffoldMessenger.of(context).clearSnackBars();
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$ip ${l.connected}'),
          backgroundColor: c.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? l.connectionFailed),
          backgroundColor: c.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );

  String _frameworkString() {
    final dartVersion = Platform.version.split(' ').first;
    return 'Flutter • Dart $dartVersion';
  }

  String _platformString() {
    if (widget.adb.isOnDevice) return 'VR (Android)';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'Mobile (iOS)';
      case TargetPlatform.linux:
        return 'Linux (Desktop)';
      case TargetPlatform.windows:
        return 'Windows (Desktop)';
      case TargetPlatform.macOS:
        return 'macOS (Desktop)';
      default:
        return 'Unknown';
    }
  }
}

// ─── Section Card (skeuomorphic, launcher-style) ─────────────────

class _SectionCard extends StatefulWidget {
  final QuestLoadColors c;
  final List<Widget> children;
  const _SectionCard({required this.c, required this.children});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? widget.c.accent.withValues(alpha: 0.4)
                : widget.c.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.children,
        ),
      ),
    );
  }
}

// ─── Setting Row ─────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        trailing,
      ],
    );
  }
}

// ─── Log Box ─────────────────────────────────────────────────────

class _LogBox extends StatelessWidget {
  final QuestLoadColors c;
  final TextTheme textTheme;
  final AppLocalizations l;

  const _LogBox({required this.c, required this.textTheme, required this.l});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 200,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LogService.entries.isEmpty
          ? Center(
              child: Text(l.noLogsYet, style: TextStyle(color: c.textMuted)),
            )
          : ListView.builder(
              // I keep this a plain ListView on purpose. Smooth scrolling here
              // hijacks the mouse wheel and blocks the whole page from
              // scrolling once the cursor is over this box.
              padding: const EdgeInsets.all(12),
              itemCount: LogService.entries.length,
              itemBuilder: (context, index) {
                final entry =
                    LogService.entries[LogService.entries.length - 1 - index];
                final color = switch (entry.level) {
                  LogLevel.error => c.error,
                  LogLevel.warning => c.warning,
                  LogLevel.info => c.textMuted,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    entry.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Theme Picker (searchable combobox, launcher-style) ──────────

class _ThemePicker extends StatelessWidget {
  final ThemeService themes;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool isSidebarLayout;
  final bool smoothScroll;

  const _ThemePicker({
    required this.themes,
    required this.selectedId,
    required this.onSelect,
    required this.isSidebarLayout,
    required this.smoothScroll,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.theme, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                l.themeSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        _ThemeLauncherButton(
          themes: themes,
          selectedId: selectedId,
          isSidebarLayout: isSidebarLayout,
          smoothScroll: smoothScroll,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

// ─── Theme brightness mode (questload theme only) ──────────────

class _ThemeModeRow extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _ThemeModeRow({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.themeMode, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                switch (mode) {
                  'light' => l.themeModeHintLight,
                  'dark' => l.themeModeHintDark,
                  _ => l.themeModeHint,
                },
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        QLSegmented<String>(
          options: [
            ('light', l.light),
            ('dark', l.dark),
            ('auto', l.auto),
          ],
          value: mode,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ThemeLauncherButton extends StatefulWidget {
  final ThemeService themes;
  final String selectedId;
  final bool isSidebarLayout;
  final bool smoothScroll;
  final ValueChanged<String> onSelect;

  const _ThemeLauncherButton({
    required this.themes,
    required this.selectedId,
    required this.isSidebarLayout,
    required this.smoothScroll,
    required this.onSelect,
  });

  @override
  State<_ThemeLauncherButton> createState() => _ThemeLauncherButtonState();
}

class _ThemeLauncherButtonState extends State<_ThemeLauncherButton> {
  bool _hovered = false;

  String get _name =>
      widget.themes.index
          .where((t) => t.id == widget.selectedId)
          .firstOrNull
          ?.name ??
      widget.selectedId;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? c.accent.withValues(alpha: 0.4)
                  : c.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _hovered ? c.textPrimary : c.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim, _) => _ThemeGalleryDialog(
        themes: widget.themes,
        selectedId: widget.selectedId,
        isSidebarLayout: widget.isSidebarLayout,
        smoothScroll: widget.smoothScroll,
        onSelect: widget.onSelect,
        anim: anim,
      ),
    );
  }
}

class _ThemeGalleryDialog extends StatefulWidget {
  final ThemeService themes;
  final String selectedId;
  final bool isSidebarLayout;
  final bool smoothScroll;
  final ValueChanged<String> onSelect;
  final Animation<double> anim;

  const _ThemeGalleryDialog({
    required this.themes,
    required this.selectedId,
    required this.isSidebarLayout,
    required this.smoothScroll,
    required this.onSelect,
    required this.anim,
  });

  @override
  State<_ThemeGalleryDialog> createState() => _ThemeGalleryDialogState();
}

class _ThemeGalleryDialogState extends State<_ThemeGalleryDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<ThemeData> _shellThemeFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _shellThemeFuture = _loadShellTheme();
  }

  /// The shell must match whatever the app is currently showing — the
  /// dialog route sits outside the app's nested Theme, so grab the
  /// selected theme's data here.
  Future<ThemeData> _loadShellTheme() async {
    if (widget.selectedId == 'questload') return AppTheme.dark();
    final theme = await widget.themes.loadTheme(widget.selectedId);
    return theme?.buildThemeData() ?? AppTheme.dark();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ThemeMeta> _filter(List<ThemeMeta> metas) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return metas;
    return metas
        .where(
          (theme) =>
              theme.name.toLowerCase().contains(query) ||
              theme.id.toLowerCase().contains(query) ||
              theme.family.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.anim,
      child: FutureBuilder<ThemeData>(
        future: _shellThemeFuture,
        builder: (context, shellSnap) {
          final shell = shellSnap.data ?? AppTheme.dark();
          return Theme(
            data: shell,
            child: Builder(
              builder: (context) {
                final c = context.ql;
                return GestureDetector(
                  onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: FractionallySizedBox(
                        widthFactor: 0.9,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 760,
                            maxHeight: 620,
                          ),
                          child: Material(
                            color: c.card.withValues(alpha: 1),
                            elevation: 24,
                            shadowColor: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  _ThemeGallerySearch(
                                    controller: _searchController,
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                  ),
                                  Divider(height: 1, color: c.cardBorder),
                                  Expanded(
                                    // Themes load lazily inside each card as
                                    // tiles become visible; only metadata is
                                    // awaited up front.
                                    child: Builder(
                                      builder: (context) {
                                        final metas = _filter(
                                          widget.themes.index,
                                        );
                                        if (metas.isEmpty) {
                                          return Center(
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.noThemesFound,
                                              style: TextStyle(
                                                color: c.textMuted,
                                              ),
                                            ),
                                          );
                                        }
                                        return _ThemeGrid(
                                          smooth: widget.smoothScroll,
                                          gridDelegate:
                                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                                maxCrossAxisExtent: 190,
                                                childAspectRatio: 0.86,
                                                crossAxisSpacing: 14,
                                                mainAxisSpacing: 14,
                                              ),
                                          itemCount: metas.length,
                                          itemBuilder: (context, index) {
                                            final meta = metas[index];
                                            return _ThemeCard(
                                              // Key by theme id so the card's
                                              // loaded preview stays with its
                                              // theme when the filter re-sorts.
                                              key: ValueKey(meta.id),
                                              themes: widget.themes,
                                              meta: meta,
                                              active:
                                                  meta.id == widget.selectedId,
                                              isSidebarLayout:
                                                  widget.isSidebarLayout,
                                              onTap: () {
                                                Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).pop();
                                                widget.onSelect(meta.id);
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ThemeGallerySearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _ThemeGallerySearch({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: SizedBox(
        height: 38,
        child: QLTextField(
          controller: controller,
          hint: AppLocalizations.of(context)!.searchThemes,
          autofocus: true,
          onChanged: onChanged,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 17,
            color: c.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final ThemeService themes;
  final ThemeMeta meta;
  final bool active;
  final bool isSidebarLayout;
  final VoidCallback onTap;

  const _ThemeCard({
    super.key,
    required this.themes,
    required this.meta,
    required this.active,
    required this.isSidebarLayout,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  Future<ThemeData?>? _previewData;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  /// Lazy: only cards that are actually built (visible in the grid)
  /// pull their theme file. Loaded themes are cached by [ThemeService].
  void _loadPreview() {
    _previewData = widget.themes
        .loadTheme(widget.meta.id)
        .then((d) => d?.buildThemeData());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ql; // the currently selected (shell) theme
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.card.withValues(alpha: 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? c.accent.withValues(alpha: 0.7)
                    : widget.active
                    ? c.accent
                    : c.cardBorder,
                width: _hovered || widget.active ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  // Only the thumbnail previews its own theme; the rest of the
                  // card (bg, name, family) stays on the shell theme.
                  child: FutureBuilder<ThemeData?>(
                    future: _previewData,
                    builder: (context, snap) {
                      final data = snap.data;
                      if (data == null) {
                        return _previewPlaceholder(c);
                      }
                      return Theme(
                        data: data,
                        child: Builder(
                          builder: (context) => _MiniPreview(
                            isSidebarLayout: widget.isSidebarLayout,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.meta.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 12,
                    fontWeight: widget.active
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                Text(
                  widget.meta.family,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewPlaceholder(QuestLoadColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 1),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─── Theme gallery grid (silky or stock) ────────────────────────

class _ThemeGrid extends StatelessWidget {
  final bool smooth;
  final SliverGridDelegate gridDelegate;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _ThemeGrid({
    required this.smooth,
    required this.gridDelegate,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.all(18);
    return smooth
        ? SilkyGridView.builder(
            padding: padding,
            gridDelegate: gridDelegate,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          )
        : GridView.builder(
            padding: padding,
            gridDelegate: gridDelegate,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
  }
}

class _MiniPreview extends StatelessWidget {
  final bool isSidebarLayout;

  const _MiniPreview({required this.isSidebarLayout});

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: c.scaffoldBg.withValues(alpha: 1),
        child: isSidebarLayout ? _sidebarPreview(c) : _compactPreview(c),
      ),
    );
  }

  Widget _sidebarPreview(QuestLoadColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 42,
          child: ColoredBox(
            color: c.navBg,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
                  child: SizedBox(height: 10, child: _previewLogo(c)),
                ),
                // Full-width divider under the logo — spans the whole sidebar.
                Container(height: 1, color: c.cardBorder),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? c.navActiveBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _previewContentBar(c),
              Expanded(child: _previewContent(c)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactPreview(QuestLoadColors c) {
    return Column(
      children: [
        Container(
          height: 30,
          color: c.navBg,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            children: [
              SizedBox(width: 35, height: 12, child: _previewLogo(c)),
              const Spacer(),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 16,
                    height: 14,
                    decoration: BoxDecoration(
                      color: index == 0 ? c.navActiveBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Full-width divider under the compact bar.
        Container(height: 1, color: c.cardBorder),
        Expanded(child: _previewContent(c)),
      ],
    );
  }

  Widget _previewLogo(QuestLoadColors c) {
    // Rounded wordmark pill standing in for the text logo.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 26,
        height: 8,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _previewContentBar(QuestLoadColors c) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
    );
  }

  Widget _previewContent(QuestLoadColors c) {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Content header representation: the accent rounded shape belongs here.
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _previewCard(c)),
                const SizedBox(width: 5),
                Expanded(child: _previewCard(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(QuestLoadColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.cardBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
