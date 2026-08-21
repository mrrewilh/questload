import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:silky_scroll/silky_scroll.dart';
import 'package:window_manager/window_manager.dart';
import '../l10n/app_localizations.dart';
import '../core/app_theme.dart';

enum AppLayout { sidebar, compact }

enum AppPage { home, library, device, downloads, settings }

bool _isDesktopPlatform() =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

class LayoutShell extends StatefulWidget {
  final Widget home, library, device, downloads, settings;
  final bool showDeviceTab;
  final bool deviceConnected;
  final AppLayout layout;
  final bool smoothScroll;
  final VoidCallback onToggleLayout;
  final AppPage initialPage;
  final ValueChanged<AppPage>? onPageChanged;

  const LayoutShell({
    super.key,
    required this.home,
    required this.library,
    required this.device,
    required this.downloads,
    required this.settings,
    this.showDeviceTab = true,
    this.deviceConnected = false,
    this.layout = AppLayout.sidebar,
    this.smoothScroll = true,
    required this.onToggleLayout,
    this.initialPage = AppPage.home,
    this.onPageChanged,
  });

  @override
  State<LayoutShell> createState() => LayoutShellState();
}

class LayoutShellState extends State<LayoutShell>
    with TickerProviderStateMixin {
  AppPage _currentPage = AppPage.home;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  static const double _break = 700.0;
  static const double _midBreak = 600.0;
  static const double _barHeight = 48.0;
  static const double _bottomNavHeight = 64.0;
  static const double _drawerHeaderHeight = 52.0;

  bool get _isDesktop => _isDesktopPlatform();

  Widget _moveWindow(Widget child) =>
      _isDesktop ? DragToMoveArea(child: child) : child;

  List<AppPage> get _visiblePages {
    if (widget.showDeviceTab) return AppPage.values;
    return AppPage.values.where((p) => p != AppPage.device).toList();
  }

  void navigate(AppPage page) {
    if (!_visiblePages.contains(page)) return;
    setState(() => _currentPage = page);
    widget.onPageChanged?.call(page);
  }

  Widget _buildCurrentPage() => switch (_currentPage) {
    AppPage.home => widget.home,
    AppPage.library => widget.library,
    AppPage.device => widget.device,
    AppPage.downloads => widget.downloads,
    AppPage.settings => widget.settings,
  };

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    if (!widget.showDeviceTab && _currentPage == AppPage.device) {
      _currentPage = AppPage.home;
    }
  }

  @override
  void didUpdateWidget(covariant LayoutShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPage != oldWidget.initialPage &&
        _currentPage == AppPage.home &&
        widget.initialPage != AppPage.home) {
      _currentPage = widget.initialPage;
      if (!_visiblePages.contains(_currentPage)) _currentPage = AppPage.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    final pages = _visiblePages;
    final isDesktop = _isDesktopPlatform();

    final scaffold = Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: DrawerBuilder(layout: widget.layout, pages: pages, parent: this),
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.navBg)),
          Row(
            children: [
              SidebarOrSpacer(
                layout: widget.layout,
                pages: pages,
                parent: this,
              ),
              Expanded(
                child: Column(
                  children: [
                    _BarSection(
                      layout: widget.layout,
                      pages: pages,
                      parent: this,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: KeyedSubtree(
                          key: ValueKey(_currentPage),
                          child: _buildCurrentPage(),
                        ),
                      ),
                    ),
                    _BottomNavBuilder(
                      layout: widget.layout,
                      pages: pages,
                      parent: this,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isDesktop)
            Positioned(
              top: 0,
              right: 4,
              height: _barHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: _windowButtons(c),
              ),
            ),
        ],
      ),
    );

    return scaffold;
  }

  // ─── LOGO ────────────────────────────────────────────────────────
  Widget _logoWidget({bool showBorder = false}) {
    final c = context.ql;
    return Container(
      height: _barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: c.cardBorder)),
            )
          : null,
      alignment: Alignment.centerLeft,
      child: _logoSvg(c),
    );
  }

  Widget _logoSvg(
    QuestLoadColors c, {
    double logoWidth = 90,
    double logoHeight = 28,
  }) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      image: true,
      label: l.logoAlt,
      child: IgnorePointer(
        child: SvgPicture.asset(
          'assets/text.svg',
          colorFilter: ColorFilter.mode(c.textPrimary, BlendMode.srcIn),
          width: logoWidth,
          height: logoHeight,
          placeholderBuilder: (_) => Text(
            l.logoAlt,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: logoHeight * 0.6,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  String _pageTitle(AppLocalizations l) => switch (_currentPage) {
    AppPage.home => l.home,
    AppPage.library => l.library,
    AppPage.device => l.device,
    AppPage.downloads => l.downloads,
    AppPage.settings => l.settings,
  };

  // ─── WINDOW BUTTONS (theme-aware) ─────────────────────────────
  Widget _windowButtons(QuestLoadColors c) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: l.windowControls,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleBtn(
            Icons.horizontal_rule_rounded,
            () async {
              if (await windowManager.isMaximized()) {
                await windowManager.restore();
              }
              await windowManager.minimize();
            },
            c.textSecondary,
            c.navActiveBg,
          ),
          _circleBtn(
            Icons.crop_square_rounded,
            () async {
              if (await windowManager.isMaximized()) {
                await windowManager.restore();
              } else {
                await windowManager.maximize();
              }
            },
            c.textSecondary,
            c.navActiveBg,
          ),
          _circleBtn(
            Icons.close,
            () => windowManager.close(),
            c.textSecondary,
            c.navActiveBg,
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
    IconData icon,
    VoidCallback onPressed,
    Color iconColor,
    Color hoverBg,
  ) {
    return Semantics(
      button: true,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isDesktop ? onPressed : null,
            hoverColor: hoverBg.withValues(alpha: 0.5),
            child: Center(child: Icon(icon, size: 12, color: iconColor)),
          ),
        ),
      ),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────
  Widget _sidebar(List<AppPage> pages) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    return Container(
      width: 220,
      color: c.navBg,
      child: Column(
        children: [
          _moveWindow(_logoWidget(showBorder: true)),
          const SizedBox(height: 4.0),
          ...pages.map((p) => _sItem(_iconFor(p), _labelFor(p, l), p)),
          const Spacer(),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _sItem(IconData icon, String label, AppPage page) {
    final c = context.ql;
    final textTheme = Theme.of(context).textTheme;
    final isActive = page == _currentPage;
    return Semantics(
      button: true,
      selected: isActive,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        child: Material(
          color: isActive ? c.navActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => navigate(page),
            hoverColor: c.navActiveBg.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  _maybeDeviceBadge(
                    Icon(
                      icon,
                      size: 20,
                      color: isActive ? c.textPrimary : c.textMuted,
                    ),
                    page,
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      color: isActive ? c.textPrimary : c.textSecondary,
                      fontWeight: isActive
                          ? FontWeight.w500
                          : FontWeight.normal,
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

  // ─── CONTENT TITLE BAR ──────────────────────────────────────────
  Widget _contentTitleBar() {
    final c = context.ql;
    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
      child: Row(children: [Expanded(child: _moveWindow(Container()))]),
    );
  }

  // ─── COMPACT BAR ────────────────────────────────────────────────
  Widget _compactBar(List<AppPage> pages) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double threshold = 760.0;
          final useSideBySide = constraints.maxWidth >= threshold;
          return Stack(
            children: [
              Positioned.fill(child: _moveWindow(Container())),
              Positioned(left: 0, top: 0, bottom: 0, child: _logoWidget()),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...pages.map(
                      (p) => _ctab(
                        _iconFor(p),
                        _labelFor(p, l),
                        p,
                        compact: !useSideBySide,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ctab(
    IconData icon,
    String label,
    AppPage page, {
    bool compact = false,
  }) {
    final c = context.ql;
    final isActive = page == _currentPage;
    return Semantics(
      button: true,
      selected: isActive,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: isActive ? c.navActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => navigate(page),
            hoverColor: c.navActiveBg.withValues(alpha: 0.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: compact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _maybeDeviceBadge(
                          Icon(
                            icon,
                            size: 18,
                            color: isActive ? c.textPrimary : c.textMuted,
                          ),
                          page,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? c.textPrimary : c.textMuted,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _maybeDeviceBadge(
                          Icon(
                            icon,
                            size: 16,
                            color: isActive ? c.textPrimary : c.textMuted,
                          ),
                          page,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: isActive ? c.textPrimary : c.textMuted,
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.normal,
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

  // ─── COMPACT NARROW TITLE BAR ───────────────────────────────────
  Widget _compactNarrowTitleBar() {
    final c = context.ql;
    return _moveWindow(
      Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: c.navBg,
          border: Border(bottom: BorderSide(color: c.cardBorder)),
        ),
        child: Row(children: [_logoWidget(), const Spacer()]),
      ),
    );
  }

  // ─── MOBILE TOP BAR ─────────────────────────────────────────────
  Widget _mobileTopBar() {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: _barHeight,
      padding: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: l.settings,
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: c.textSecondary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Expanded(
            child: _moveWindow(
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 12),
                child: Text(_pageTitle(l), style: textTheme.titleMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────
  Widget _bottomNav(List<AppPage> pages) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    return Container(
      height: _bottomNavHeight,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...pages.map((p) => _navItem(_iconFor(p), _labelFor(p, l), p)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, AppPage page) {
    final c = context.ql;
    final isActive = page == _currentPage;
    return Semantics(
      button: true,
      selected: isActive,
      child: Material(
        color: isActive
            ? c.navActiveBg.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => navigate(page),
          hoverColor: c.navActiveBg.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _maybeDeviceBadge(
                  Icon(
                    icon,
                    size: 22,
                    color: isActive ? c.textPrimary : c.textMuted,
                  ),
                  page,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: isActive ? c.textPrimary : c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── DRAWER ─────────────────────────────────────────────────────
  Widget _drawerMenu(List<AppPage> pages) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    final drawerChildren = [
      SizedBox(
        height: _drawerHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _logoSvg(c, logoWidth: 85, logoHeight: 26),
          ),
        ),
      ),
      ...pages.map((p) => _dItem(_iconFor(p), _labelFor(p, l), p)),
    ];
    return Drawer(
      backgroundColor: c.navBg,
      child: widget.smoothScroll
          ? SilkyListView(padding: EdgeInsets.zero, children: drawerChildren)
          : ListView(padding: EdgeInsets.zero, children: drawerChildren),
    );
  }

  Widget _dItem(IconData icon, String label, AppPage page) {
    final c = context.ql;
    final isActive = page == _currentPage;
    return ListTile(
      leading: _maybeDeviceBadge(
        Icon(icon, color: isActive ? c.textPrimary : c.textMuted),
        page,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? c.textPrimary : c.textSecondary,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: c.navActiveBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: c.navActiveBg,
      onTap: () {
        Navigator.pop(context);
        navigate(page);
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  /// Wraps [icon] with a green glow dot when the device page button
  /// should indicate a connected device.
  Widget _maybeDeviceBadge(Widget icon, AppPage page) {
    if (page != AppPage.device || !widget.deviceConnected) return icon;
    final c = context.ql;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(AppPage page) => switch (page) {
    AppPage.home => Icons.home_rounded,
    AppPage.library => Icons.grid_view_rounded,
    AppPage.device => Icons.tablet_rounded,
    AppPage.downloads => Icons.download_rounded,
    AppPage.settings => Icons.settings_rounded,
  };

  String _labelFor(AppPage page, AppLocalizations l) => switch (page) {
    AppPage.home => l.home,
    AppPage.library => l.library,
    AppPage.device => l.device,
    AppPage.downloads => l.downloads,
    AppPage.settings => l.settings,
  };
}

// ─── Layout-aware widgets ─────────────────────────────────────
///
/// These small widgets read [MediaQuery] width directly so they all see
/// the SAME window width, avoiding the constraint disagreement between
/// [SidebarOrSpacer] (before the sidebar steals 220px) and [_BarSection]
/// (inside [Expanded], after the sidebar takes its space).

/// Helper: window width from [MediaQuery].
double _w(BuildContext context) => MediaQuery.of(context).size.width;

/// Drawer that appears when sidebar + narrow.
class DrawerBuilder extends StatelessWidget {
  final AppLayout layout;
  final List<AppPage> pages;
  final LayoutShellState parent;

  const DrawerBuilder({
    super.key,
    required this.layout,
    required this.pages,
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final useSidebar = layout == AppLayout.sidebar;
    final isWide = _w(context) >= LayoutShellState._break;
    if (!useSidebar || isWide) return const SizedBox.shrink();
    return parent._drawerMenu(pages);
  }
}

/// Sidebar or empty spacer.
class SidebarOrSpacer extends StatelessWidget {
  final AppLayout layout;
  final List<AppPage> pages;
  final LayoutShellState parent;

  const SidebarOrSpacer({
    super.key,
    required this.layout,
    required this.pages,
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final useSidebar = layout == AppLayout.sidebar;
    final isWide = _w(context) >= LayoutShellState._break;
    if (useSidebar && isWide) return parent._sidebar(pages);
    return const SizedBox.shrink();
  }
}

/// The top bar — content title bar, mobile top bar, compact bar,
/// or compact narrow title bar depending on layout + width.
class _BarSection extends StatelessWidget {
  final AppLayout layout;
  final List<AppPage> pages;
  final LayoutShellState parent;

  const _BarSection({
    required this.layout,
    required this.pages,
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final w = _w(context);
    final isWide = w >= LayoutShellState._break;
    final isNarrow = w < LayoutShellState._midBreak;
    final useSidebar = layout == AppLayout.sidebar;

    if (useSidebar && isWide) return parent._contentTitleBar();
    if (useSidebar && !isWide) return parent._mobileTopBar();
    if (!useSidebar && !isNarrow) return parent._compactBar(pages);
    return parent._compactNarrowTitleBar();
  }
}

/// Bottom navigation bar — only visible in compact + narrow mode.
class _BottomNavBuilder extends StatelessWidget {
  final AppLayout layout;
  final List<AppPage> pages;
  final LayoutShellState parent;

  const _BottomNavBuilder({
    required this.layout,
    required this.pages,
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = _w(context) < LayoutShellState._midBreak;
    if (layout == AppLayout.sidebar || !isNarrow) {
      return const SizedBox.shrink();
    }
    return parent._bottomNav(pages);
  }
}
