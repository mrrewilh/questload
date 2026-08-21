import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/update_dialogs.dart';
import 'services/log_service.dart';
import 'services/theme_service.dart';
import 'services/theme_brightness_service.dart';
import 'services/update_service.dart';
import 'l10n/app_localizations.dart';
import 'services/adb_service.dart';
import 'services/paths_service.dart';
import 'screens/layout_shell.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/device_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/settings_screen.dart';
import 'core/app_theme.dart';
import 'widgets/ql_widgets.dart';

class QuestLoadApp extends StatefulWidget {
  final AdbService adb;
  final ThemeService themes;

  const QuestLoadApp({super.key, required this.adb, required this.themes});

  @override
  State<QuestLoadApp> createState() => _QuestLoadAppState();
}

class _QuestLoadAppState extends State<QuestLoadApp>
    with WidgetsBindingObserver {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkMaximized();
  }

  @override
  void didChangeMetrics() {
    _checkMaximized();
  }

  void _checkMaximized() {
    windowManager
        .isMaximized()
        .then((maximized) {
          if (maximized != _isMaximized && mounted) {
            setState(() => _isMaximized = maximized);
          }
        })
        .catchError((e) {
          LogService.error('Window maximize check failed: $e');
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'QuestLoad',
      debugShowCheckedModeBanner: false,
      // Transparent so the ClipRRect corners show the desktop through on
      // Windows (rounded-corner recipe: MaterialApp must not paint).
      color: Colors.transparent,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(adb: widget.adb, themes: widget.themes),
    );

    final Widget shell = ClipRRect(
      borderRadius: BorderRadius.circular(_isMaximized ? 0 : 12),
      child: app,
    );

    // Desktop: invisible edge strips so the frameless window stays
    // resizable (native resize borders are gone with the custom frame).
    // Wrapped in Directionality — DragToResizeArea's Stack uses
    // AlignmentDirectional and sits above the MaterialApp, which would
    // otherwise have no text-direction ancestor.
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isDesktop
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: DragToResizeArea(resizeEdgeSize: 8, child: shell),
          )
        : shell;
  }
}

class AppShell extends StatefulWidget {
  final AdbService adb;
  final ThemeService themes;

  const AppShell({super.key, required this.adb, required this.themes});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final Widget _home;
  Widget _device = const SizedBox.shrink();
  late final LibraryScreen _library;
  late final DownloadsScreen _downloads;
  AppLayout _layout = AppLayout.compact;
  String _themeId = 'questload';
  String _themeMode = 'auto';
  bool _smoothScroll = true;
  bool _updateAutoCheck = true;
  bool _openLastPageOnStart = false;
  String _lastPage = 'home';
  String _updateSkipVersion = '';
  String _lastSeenVersion = '';
  bool _deviceConnected = false;
  ThemeData? _cachedThemeData;
  BuildContext? _themedContext;

  ThemeData get _themeData => _cachedThemeData ?? AppTheme.dark();

  /// A context under the nested selected Theme. Dialogs and toasts launched
  /// from this state must use it — the state's own [context] sits above the
  /// nested Theme and would resolve the app's base theme, not the selected
  /// one. One rule for every popup, no special cases.
  BuildContext get _uiContext => _themedContext ?? context;

  Future<String> get _settingsPath => PathsService.settingsPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeBrightnessService.instance.start();
    // Auto mode follows the OS brightness live.
    ThemeBrightnessService.instance.brightness.addListener(_onBrightness);
    _home = const HomeScreen();
    _library = const LibraryScreen();
    _device = _buildDeviceScreen();
    _downloads = const DownloadsScreen();
    _loadSettings();
  }

  void _onBrightness() {
    if (_themeMode == 'auto') _applyTheme(_themeId);
  }

  @override
  void didChangePlatformBrightness() {
    // Non-Linux: the engine already tracks the OS theme.
    if (!ThemeBrightnessService.instance.usesPortal) {
      ThemeBrightnessService.instance.brightness.value =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  Map<String, dynamic> _currentSettings() => {
    'layout_mode': _layout == AppLayout.sidebar ? 'sidebar' : 'compact',
    'theme_id': _themeId,
    'theme_mode': _themeMode,
    'smooth_scroll': _smoothScroll,
    'update_auto_check': _updateAutoCheck,
    'open_last_page_on_start': _openLastPageOnStart,
    'last_page': _lastPage,
    'update_skip_version': _updateSkipVersion,
    'last_seen_version': _lastSeenVersion,
  };

  Future<void> _loadSettings() async {
    try {
      final path = await _settingsPath;
      Map<String, dynamic> json;
      if (File(path).existsSync()) {
        json =
            jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      } else {
        json = <String, dynamic>{
          'layout_mode': 'compact',
          'theme_id': 'questload',
          'theme_mode': 'auto',
          'smooth_scroll': true,
          'update_auto_check': true,
        };
      }
      if (!mounted) return;
      _layout = (json['layout_mode'] as String?) == 'sidebar'
          ? AppLayout.sidebar
          : AppLayout.compact;
      _themeId = (json['theme_id'] as String?) ?? 'questload';
      _themeMode = (json['theme_mode'] as String?) ?? 'auto';
      _smoothScroll = (json['smooth_scroll'] as bool?) ?? true;
      _updateAutoCheck = (json['update_auto_check'] as bool?) ?? true;
      _openLastPageOnStart = (json['open_last_page_on_start'] as bool?) ?? false;
      _lastPage = (json['last_page'] as String?) ?? 'home';
      _updateSkipVersion = (json['update_skip_version'] as String?) ?? '';
      _lastSeenVersion = (json['last_seen_version'] as String?) ?? '';
      await _applyTheme(_themeId);
      _runUpdateFlow();
    } catch (e) {
      LogService.error('Settings load failed: $e');
      if (mounted) _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final path = await _settingsPath;
      await File(path).writeAsString(jsonEncode(_currentSettings()));
    } catch (e) {
      LogService.error('Settings save failed: $e');
    }
  }

  Future<void> _applyTheme(String id) async {
    final data = await _resolveTheme(id);
    if (mounted && data != null) {
      setState(() {
        _cachedThemeData = data;
      });
    }
  }

  /// Resolves the [ThemeData] for a theme id + the brightness mode.
  /// Only the questload theme honors light/dark/auto; gallery themes are
  /// fixed palettes.
  Future<ThemeData?> _resolveTheme(String id) async {
    if (id == 'questload') {
      return switch (_themeMode) {
        'light' => AppTheme.light(),
        'dark' => AppTheme.dark(),
        _ =>
          ThemeBrightnessService.instance.brightness.value == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
      };
    }
    final theme = await widget.themes.loadTheme(id);
    return theme?.buildThemeData();
  }

  void _selectThemeMode(String mode) {
    _themeMode = mode;
    _applyTheme(_themeId);
    _saveSettings();
  }

  void _toggleLayout() {
    setState(() {
      _layout = _layout == AppLayout.sidebar
          ? AppLayout.compact
          : AppLayout.sidebar;
    });
    _saveSettings();
  }

  void _toggleSmoothScroll() {
    setState(() {
      _smoothScroll = !_smoothScroll;
      // The device screen bakes the flag at construction; rebuild it so the
      // setting applies immediately.
      _device = _buildDeviceScreen();
    });
    _saveSettings();
  }

  void _toggleUpdateAutoCheck() {
    setState(() {
      _updateAutoCheck = !_updateAutoCheck;
    });
    _saveSettings();
  }

  void _toggleOpenLastPage() {
    setState(() {
      _openLastPageOnStart = !_openLastPageOnStart;
    });
    _saveSettings();
  }

  void _onPageChanged(AppPage page) {
    _lastPage = page.name;
    _saveSettings();
  }

  AppPage _initialPage() {
    if (!_openLastPageOnStart) return AppPage.home;
    return AppPage.values.firstWhere(
      (p) => p.name == _lastPage,
      orElse: () => AppPage.home,
    );
  }

  /// Launch flow: after-update changelog, pending apply, then the check.
  Future<void> _runUpdateFlow() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    if (current.isEmpty) return;

    // after an update: changelog once
    if (_lastSeenVersion != current) {
      final body = await UpdateService.embeddedChangelog(
        Platform.resolvedExecutable,
      );
      if (!mounted) return;
      await showChangelogDialog(_uiContext, body: body);
      _lastSeenVersion = current;
      _saveSettings();
    }

    // windows: a downloaded update waiting to be applied
    final hasStaged = await UpdateService.hasStagedUpdate(current);
    if (!mounted) return;
    if (defaultTargetPlatform == TargetPlatform.windows && hasStaged) {
      final apply = await showApplyUpdateDialog(_uiContext);
      if (apply) {
        await _applyStagedUpdate();
        return;
      }
    }
    if (!mounted) return;

    if (_updateAutoCheck && _updateSkipVersion != current) {
      await _checkForUpdates(showUpToDate: false, respectSkip: true);
    }
  }

  /// Manual check from settings. Ignores the skip so it can be undone.
  Future<void> _checkForUpdates({
    bool showUpToDate = true,
    bool respectSkip = false,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    final result = await UpdateService.check(currentVersion: current);
    if (!mounted) return;
    if (!result.reachable) {
      if (showUpToDate) {
        QLToast.show(
          _uiContext,
          AppLocalizations.of(_uiContext)!.updateUnreachable,
          kind: QLToastKind.error,
        );
      }
      return;
    }
    final update = result.info;
    if (update == null) {
      if (showUpToDate) {
        QLToast.show(
          _uiContext,
          AppLocalizations.of(_uiContext)!.updateNoUpdates,
          kind: QLToastKind.success,
        );
      }
      return;
    }
    if (respectSkip && update.version == _updateSkipVersion) return;

    final canDownload = defaultTargetPlatform == TargetPlatform.windows;
    final choice = await showDialog<UpdateChoice>(
      context: _uiContext,
      builder: (ctx) => Theme(
        data: _themeData,
        child: UpdateAvailableDialog(
          newVersion: update.version,
          currentVersion: current,
          canDownload: canDownload,
        ),
      ),
    );
    if (!mounted) return;
    if (choice == UpdateChoice.skip) {
      _updateSkipVersion = update.version;
      _saveSettings();
      return;
    }
    // Download only where the update can actually be applied — on Linux
    // 'Continue' just closes the popup, no pointless zip.
    if (canDownload && choice == UpdateChoice.download) {
      final zip = await UpdateService.downloadAndVerify(update);
      if (!mounted) return;
      if (zip == null) {
        QLToast.show(
          _uiContext,
          AppLocalizations.of(_uiContext)!.updateFailed,
          kind: QLToastKind.error,
        );
        return;
      }
      await UpdateService.markPending(update.version, update.sha256);
      // applied on next launch, when the popup asks
    }
  }

  Future<void> _applyStagedUpdate() async {
    final dir = await UpdateService.downloadsDir();
    final pending = await UpdateService.pendingInfo();
    if (pending == null) return;
    final zip = File('${dir.path}/questload-${pending.version}.zip');
    if (!await zip.exists()) return;
    final bytes = await zip.readAsBytes();
    if (sha256Of(bytes) != pending.sha256.toLowerCase()) {
      LogService.error('Staged update failed hash check');
      return;
    }
    final extracted = await UpdateService.extract(zip);
    if (extracted == null) return;
    final ok = await UpdateService.applyStaged(
      extracted,
      zip,
      Platform.resolvedExecutable,
    );
    if (!ok) return; // handoff didn't launch — stay running, don't exit
    await UpdateService.clearPending();
    // the handoff waits for us to exit, swaps, then relaunches
    exit(0);
  }

  Widget _buildDeviceScreen() => DeviceScreen(
    adb: widget.adb,
    smoothScroll: _smoothScroll,
    onConnectionChanged: () {
      widget.adb.refreshDevices().then((serials) {
        if (mounted) setState(() => _deviceConnected = serials.isNotEmpty);
      });
    },
  );

  Future<void> _selectTheme(String id) async {
    _themeId = id;
    await _applyTheme(id);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _themeData,
      child: Builder(
        builder: (context) {
          _themedContext = context;
          return LayoutShell(
            home: _home,
            library: _library,
            device: _device,
            downloads: _downloads,
            showDeviceTab: !widget.adb.isOnDevice,
            deviceConnected: _deviceConnected,
            layout: _layout,
            smoothScroll: _smoothScroll,
            onToggleLayout: _toggleLayout,
            initialPage: _initialPage(),
            onPageChanged: _onPageChanged,
            settings: SettingsScreen(
              adb: widget.adb,
              isSidebarLayout: _layout == AppLayout.sidebar,
              smoothScroll: _smoothScroll,
              themeId: _themeId,
              themeMode: _themeMode,
              themes: widget.themes,
              onToggleLayout: _toggleLayout,
              onToggleSmoothScroll: _toggleSmoothScroll,
              updateAutoCheck: _updateAutoCheck,
              onToggleUpdateAutoCheck: _toggleUpdateAutoCheck,
              onCheckForUpdates: () => _checkForUpdates(),
              openLastPageOnStart: _openLastPageOnStart,
              onToggleOpenLastPage: _toggleOpenLastPage,
              onSelectTheme: _selectTheme,
              onSelectThemeMode: _selectThemeMode,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeBrightnessService.instance.brightness.removeListener(_onBrightness);
    super.dispose();
  }
}
