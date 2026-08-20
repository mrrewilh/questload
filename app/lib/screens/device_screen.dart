import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:silky_scroll/silky_scroll.dart';
import '../l10n/app_localizations.dart';
import '../services/device_service.dart';
import '../services/adb_service.dart';
import '../services/log_service.dart';
import '../services/device_settings_service.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../widgets/ql_widgets.dart';
import '../widgets/device_art.dart';
import '../widgets/device_widget.dart';

class DeviceScreen extends StatefulWidget {
  final AdbService adb;
  final bool smoothScroll;
  final VoidCallback? onConnectionChanged;

  const DeviceScreen({
    super.key,
    required this.adb,
    this.smoothScroll = true,
    this.onConnectionChanged,
  });
  @override
  State<DeviceScreen> createState() => DeviceScreenState();
}

class DeviceScreenState extends State<DeviceScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  List<_GridItem> _gridItems = [];
  _GridItem? _viewing;
  bool _autoSelectApplied = false;
  List<MdnsDiscoveredDevice> _scanResults = [];
  bool _scanning = false;
  bool _syncing = false;
  bool _noAdb = false;
  Timer? _scanTimer;
  Timer? _adbTimer;
  late AnimationController _pingAnim;
  late Animation<double> _pingScale;
  late Animation<double> _pingOpacity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DeviceSettingsService.instance.load();

    // Re-scan every 30 seconds to discover new devices
    _scanTimer = Timer.periodic(kScanInterval, (_) {
      if (!_noAdb) _startScan();
    });

    // Poll ADB every 3 seconds to detect USB plug/unplug
    _adbTimer = Timer.periodic(kDevicePollInterval, (_) {
      if (!_noAdb) _pollAdb();
    });

    _pingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pingScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.9), weight: 1),
    ]).animate(CurvedAnimation(parent: _pingAnim, curve: Curves.easeInOut));

    _pingOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 1),
    ]).animate(CurvedAnimation(parent: _pingAnim, curve: Curves.easeInOut));

    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _adbTimer?.cancel();
    _pingAnim.dispose();
    super.dispose();
  }

  void _managePing() {
    if (_gridItems.isEmpty && !_pingAnim.isAnimating) {
      _pingAnim.repeat();
    } else if (_gridItems.isNotEmpty && _pingAnim.isAnimating) {
      _pingAnim.stop();
    }
  }

  /// Fetches connected devices from ADB and syncs the grid.
  /// If [triggerScan] is true, starts an mDNS scan after syncing.
  Future<void> _syncDevices({bool triggerScan = false}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      await widget.adb.refreshDevices();
      final serials = widget.adb.connectedSerials;
      final connectedItems = <_GridItem>[];

      for (final serial in serials) {
        final props = await widget.adb.getProperties(serial);
        final battery = await widget.adb.getBattery(serial);
        final ip = await widget.adb.getIpAddress(serial);
        final model = props['ro.product.model'] ?? 'Quest';
        // Real hardware serial (ro.serialno) — same on usb and wireless,
        // used to match device settings in devices.json.
        final realSerial = props['ro.serialno'];
        connectedItems.add(
          _GridItem.connected(
            serial: serial,
            model: model,
            battery: battery,
            ipAddress: ip,
            realSerial: realSerial,
          ),
        );
      }

      if (mounted) {
        final connectedSerials = connectedItems.map((i) => i.serial).toSet();
        final connectedIps = connectedItems
            .where((i) => i.ipAddress != null)
            .map((i) => i.ipAddress!)
            .toSet();

        final preserved = _gridItems.where((i) {
          if (i.isConnected) return false;
          if (connectedSerials.contains(i.serial)) return false;
          if (i.ipAddress != null && connectedIps.contains(i.ipAddress)) {
            return false;
          }
          return true;
        }).toList();

        setState(() => _gridItems = [...connectedItems, ...preserved]);
        _managePing();
        widget.onConnectionChanged?.call();
      }

      // Auto-open the auto-selected device once the grid is first filled.
      if (connectedItems.isNotEmpty && !_autoSelectApplied) {
        _autoSelectApplied = true;
        for (final it in connectedItems) {
          final rs = it.realSerial;
          if (rs != null && DeviceSettingsService.instance.autoSelectFor(rs)) {
            setState(() => _viewing = it);
            break;
          }
        }
      }

      // Start scan AFTER setState so connected devices are in the grid
      // when _mergeScanResults checks for duplicates.
      if (triggerScan && !_scanning) {
        _startScan();
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _refresh() async {
    try {
      final hasAdb = await widget.adb.hasAdb;
      if (!hasAdb) {
        if (mounted) {
          setState(() {
            _noAdb = true;
            _gridItems = [];
          });
          _managePing();
          widget.onConnectionChanged?.call();
        }
        return;
      }
      if (mounted && _noAdb) setState(() => _noAdb = false);
      await _syncDevices(triggerScan: true);
    } catch (e) {
      LogService.error('DeviceScreen refresh error: $e');
    }
  }

  Future<void> _pollAdb() async {
    try {
      await _syncDevices();
    } catch (e) {
      LogService.error('DeviceScreen ADB poll error: $e');
    }
  }

  List<String> _connectedSerials() =>
      _gridItems.where((i) => i.isConnected).map((i) => i.serial).toList();

  Future<void> _connectToIp(String ip, int port) async {
    final result = await widget.adb.connect(ip, port: port);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    if (result.success) {
      QLToast.show(context, '$ip ${l.connected}', kind: QLToastKind.success);
    } else {
      QLToast.show(
        context,
        adbErrorMessage(l, result.error ?? 'connect_failed', ip: ip),
        kind: QLToastKind.error,
      );
    }
    _refresh();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);

    try {
      final results = await widget.adb.scan(
        timeoutSeconds: kMdnsTimeoutSeconds,
      );
      if (mounted) {
        setState(() {
          _scanResults = results;
          _scanning = false;
        });
        _mergeScanResults();
      }
    } catch (e) {
      LogService.error('Scan error: $e');
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  void _mergeScanResults() {
    widget.onConnectionChanged?.call();
    final connectedSerials = _connectedSerials();
    final existingIps = _gridItems
        .where((i) => i.ipAddress != null)
        .map((i) => i.ipAddress)
        .toSet();
    final scanIps = _scanResults.map((s) => s.ip).toSet();

    final newItems = <_GridItem>[];
    for (final scan in _scanResults) {
      if (connectedSerials.any((s) => s.contains(scan.ip))) continue;
      if (existingIps.contains(scan.ip)) continue;

      newItems.add(
        _GridItem.discovered(
          serial: '${scan.ip}:${scan.port}',
          ipAddress: scan.ip,
          port: scan.port,
        ),
      );
    }

    // Discovered devices that are no longer announced are gone. Their
    // cached mDNS records expired, so they're absent from this scan —
    // drop them. A live device never flickers: the persistent client's
    // cache keeps it in results between announcements.
    final stale = _gridItems
        .where(
          (i) =>
              !i.isConnected &&
              i.ipAddress != null &&
              !scanIps.contains(i.ipAddress),
        )
        .toList();

    if (newItems.isNotEmpty || stale.isNotEmpty) {
      setState(() {
        if (stale.isNotEmpty) {
          _gridItems.removeWhere((i) => stale.contains(i));
        }
        _gridItems.addAll(newItems);
      });
    }
  }

  void _disconnect(String serial) async {
    await widget.adb.disconnect(serial);
    _refresh();
  }

  /// Right-click menu on a device card.
  void _showDeviceMenu(Offset globalPosition, _GridItem item) {
    final l = AppLocalizations.of(context)!;
    final items = <QLContextMenuItem>[];
    if (item.isConnected) {
      items.add(
        QLContextMenuItem(
          label: l.open,
          onTap: () => setState(() => _viewing = item),
        ),
      );
      // Auto-select: open this device automatically when the tab is shown.
      final rs = item.realSerial;
      if (rs != null) {
        items.add(
          QLContextMenuItem(
            label: l.rename,
            onTap: () async {
              final current =
                  DeviceSettingsService.instance.nameFor(rs) ??
                  item.model ??
                  item.serial;
              final name = await _promptDeviceName(context, current);
              if (name != null) {
                await DeviceSettingsService.instance.setName(rs, name);
                if (mounted) setState(() {});
              }
            },
          ),
        );
        final on = DeviceSettingsService.instance.autoSelectFor(rs);
        items.add(
          QLContextMenuItem(
            label: on ? l.autoSelectOn : l.autoSelect,
            highlighted: on,
            onTap: () => DeviceSettingsService.instance.setAutoSelect(rs, !on),
          ),
        );
      }
      // USB is a physical link — no disconnect.
      if (item.serial.contains(':')) {
        items.add(
          QLContextMenuItem(
            label: l.disconnect,
            onTap: () => _disconnect(item.serial),
          ),
        );
      }
    } else {
      items.add(
        QLContextMenuItem(
          label: l.connect,
          onTap: () => _connectToIp(
            item.ipAddress ?? item.serial,
            item.port ?? kDefaultAdbPort,
          ),
        ),
      );
    }
    showQLContextMenu(context, globalPosition, items: items);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    final textTheme = Theme.of(context).textTheme;

    // A connected device was opened — show its view inside this tab.
    final viewing = _viewing;

    final Widget page;
    if (viewing != null) {
      page = _DeviceViewBody(
        adb: widget.adb,
        item: viewing,
        smooth: widget.smoothScroll,
        onBack: () => setState(() => _viewing = null),
      );
    } else {
      final scroller = widget.smoothScroll
          ? SilkyCustomScrollView.new
          : CustomScrollView.new;
      page = Scaffold(
        backgroundColor: Colors.transparent,
        body: _gridItems.isEmpty
            ? _noAdb
                  ? _adbMissingLayout(l, c, textTheme)
                  : _emptyLayout(l, c, textTheme)
            : scroller(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200.0,
                        mainAxisExtent: 200.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _gridCard(_gridItems[index], l, c, textTheme),
                        childCount: _gridItems.length,
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    // Enter/exit crossfade + slide between the grid and the device view.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchOutCurve: Curves.easeInCubic,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(viewing?.serial ?? 'grid'),
        child: page,
      ),
    );
  }

  // ─── Empty state — centered mascot + fixed-height text area ────

  Widget _emptyLayout(
    AppLocalizations l,
    QuestLoadColors c,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pingAnim,
            builder: (context, _) {
              return SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140.0 * _pingScale.value,
                      height: 140.0 * _pingScale.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accent.withValues(alpha: _pingOpacity.value),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/mascot/checking.svg',
                      width: 140.0,
                      height: 140.0,
                      colorFilter: ColorFilter.mode(
                        c.textMuted.withValues(alpha: 0.3),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          Text(
            l.searchingForQuest,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          // Fixed height ensures first text stays at same Y regardless
          // of whether the subtitle wraps to 1 or 2 lines.
          SizedBox(
            height: 36.0,
            child: Center(
              child: Text(
                l.connectManuallyInstructions,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ADB missing state ────────────────────────────────────────────

  Widget _adbMissingLayout(
    AppLocalizations l,
    QuestLoadColors c,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: SvgPicture.asset(
              'assets/mascot/404.svg',
              colorFilter: ColorFilter.mode(
                c.textMuted.withValues(alpha: 0.3),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(l.adbNotFound, style: textTheme.bodyMedium),
          const SizedBox(height: 4.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.adbMissingHint,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grid card ───────────────────────────────────────────────────

  Widget _gridCard(
    _GridItem item,
    AppLocalizations l,
    QuestLoadColors c,
    TextTheme textTheme,
  ) {
    final isConnected = item.isConnected;
    final svgPath = isConnected
        ? headsetSvgForModel(item.model)
        : 'assets/headsets/unknown.svg';

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isConnected
              ? () => setState(() => _viewing = item)
              : () => _connectToIp(
                  item.ipAddress ?? item.serial,
                  item.port ?? kDefaultAdbPort,
                ),
          onSecondaryTapUp: (details) =>
              _showDeviceMenu(details.globalPosition, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 20.0,
                  child: Row(
                    children: [
                      if (isConnected && item.battery != null)
                        _BatteryIndicator(battery: item.battery!, color: c),
                      const Spacer(),
                      if (isConnected)
                        _DisconnectButton(
                          item: item,
                          onDisconnect: () => _disconnect(item.serial),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SvgPicture.asset(
                      svgPath,
                      width: 110.0,
                      height: 110.0,
                      colorFilter: ColorFilter.mode(
                        isConnected ? c.textPrimary : c.textMuted,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (_) => Icon(
                        Icons.vrpano_rounded,
                        size: 60,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  isConnected
                      ? (DeviceSettingsService.instance.nameFor(
                              item.realSerial ?? '',
                            ) ??
                            item.model ??
                            item.serial)
                      : (item.ipAddress ?? item.serial),
                  style: textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridItem {
  final String serial;
  final bool isConnected;
  final String? model;
  final String? battery;
  final String? ipAddress;
  final int? port;
  final String? realSerial;

  const _GridItem({
    required this.serial,
    required this.isConnected,
    this.model,
    this.battery,
    this.ipAddress,
    this.port,
    this.realSerial,
  });

  factory _GridItem.connected({
    required String serial,
    String? model,
    String? battery,
    String? ipAddress,
    String? realSerial,
  }) => _GridItem(
    serial: serial,
    isConnected: true,
    model: model,
    battery: battery,
    ipAddress: ipAddress,
    realSerial: realSerial,
  );

  factory _GridItem.discovered({
    required String serial,
    String? ipAddress,
    int? port,
  }) => _GridItem(
    serial: serial,
    isConnected: false,
    ipAddress: ipAddress,
    port: port,
  );
}

/// Battery indicator: shows charging icon and battery percentage.
class _BatteryIndicator extends StatelessWidget {
  final String battery;
  final QuestLoadColors color;

  const _BatteryIndicator({required this.battery, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/headsets/charging.svg',
          width: 12.0,
          height: 12.0,
          colorFilter: ColorFilter.mode(color.textSecondary, BlendMode.srcIn),
        ),
        const SizedBox(width: 3),
        Text(
          '$battery%',
          style: TextStyle(
            color: color.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Disconnect button: shows USB icon when connected via USB,
/// or a link‑off icon for wireless connections.
/// The USB icon uses the same [c.textPrimary] color as the headset art.
class _DisconnectButton extends StatelessWidget {
  final _GridItem item;
  final VoidCallback onDisconnect;

  const _DisconnectButton({required this.item, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    final l = AppLocalizations.of(context)!;
    // USB device serials don't contain ':' (they're plain hex/numbers).
    // Wireless serials are `ip:port`.
    final isUsb = !item.serial.contains(':');

    return Semantics(
      button: true,
      label: isUsb ? l.usb : l.disconnect,
      child: SizedBox(
        width: 20,
        height: 20.0,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isUsb ? null : onDisconnect,
            hoverColor: isUsb ? Colors.transparent : c.surfaceLight,
            child: isUsb
                ? SvgPicture.asset(
                    'assets/headsets/usb.svg',
                    width: 20,
                    height: 20.0,
                    colorFilter: ColorFilter.mode(
                      c.textPrimary,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(Icons.link_off_rounded, size: 13, color: c.textMuted),
          ),
        ),
      ),
    );
  }
}

/// In-tab device view: back bar + hero widget + info. Everything stays
/// inside the device tab, so the window title bar isn't touched.
class _DeviceViewBody extends StatefulWidget {
  final AdbService adb;
  final _GridItem item;
  final bool smooth;
  final VoidCallback onBack;

  const _DeviceViewBody({
    required this.adb,
    required this.item,
    required this.smooth,
    required this.onBack,
  });

  @override
  State<_DeviceViewBody> createState() => _DeviceViewBodyState();
}

class _DeviceViewBodyState extends State<_DeviceViewBody> {
  int? _headsetBattery;
  int? _leftBattery;
  int? _rightBattery;
  String? _serial;
  Timer? _batteryTimer;

  @override
  void initState() {
    super.initState();
    _loadBattery();
    _loadSerial();
    _batteryTimer = Timer.periodic(
      kDeviceBatteryRefresh,
      (_) => _loadBattery(),
    );
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSerial() async {
    final serial = await widget.adb.getDeviceSerial(widget.item.serial);
    if (mounted) setState(() => _serial = serial);
  }

  Future<void> _loadBattery() async {
    final h = await widget.adb.getBattery(widget.item.serial);
    final cc = await widget.adb.getControllerBatteries(widget.item.serial);
    if (!mounted) return;
    setState(() {
      // Keep the old value if a fetch comes back empty — no blanking on
      // the periodic refresh, the % just moves to the new one.
      final hs = int.tryParse(h ?? '');
      if (hs != null) _headsetBattery = hs;
      if (cc.left != null) _leftBattery = cc.left;
      if (cc.right != null) _rightBattery = cc.right;
    });
  }

  String _displayName() {
    final rs = widget.item.realSerial;
    final custom = rs == null
        ? null
        : DeviceSettingsService.instance.nameFor(rs);
    return custom ?? widget.item.model ?? widget.item.serial;
  }

  Future<void> _rename() async {
    final rs = widget.item.realSerial;
    if (rs == null) return;
    final name = await _promptDeviceName(context, _displayName());
    if (name != null) {
      await DeviceSettingsService.instance.setName(rs, name);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    final isUsb = !widget.item.serial.contains(':');

    final children = <Widget>[
      QLDeviceWidget(
        headsetSvg: headsetSvgForModel(widget.item.model),
        controllerSvg: controllerSvgForModel(widget.item.model),
        headsetBattery: _headsetBattery,
        leftBattery: _leftBattery,
        rightBattery: _rightBattery,
      ),
      const SizedBox(height: 26),
      Text(
        l.info,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          children: [
            _infoRow(c, l.infoModel, widget.item.model ?? '—'),
            _SerialInfo(c: c, serial: _serial, hint: l.serialUsbHint),
            _infoRow(c, l.infoIp, widget.item.ipAddress ?? '—'),
            if (!isUsb) _infoRow(c, l.infoPort, _wirelessPort()),
            _infoRow(c, l.connection, isUsb ? l.usb : l.wireless),
          ],
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
          child: Row(
            children: [
              _BackButton(onTap: widget.onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _displayName(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _PenButton(onTap: _rename),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.smooth
              ? SilkyListView(
                  padding: const EdgeInsets.all(24),
                  children: children,
                )
              : ListView(padding: const EdgeInsets.all(24), children: children),
        ),
      ],
    );
  }

  Widget _infoRow(QuestLoadColors c, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: c.textPrimary),
          ),
        ),
      ],
    ),
  );

  /// Wireless serial is `ip:port` — pull the port out of it.
  String _wirelessPort() {
    final s = widget.item.serial;
    final i = s.lastIndexOf(':');
    return i >= 0 ? s.substring(i + 1) : '—';
  }
}

/// Serial row: censored by default, hover or click reveals the real one.
class _SerialInfo extends StatefulWidget {
  final QuestLoadColors c;
  final String? serial;
  final String hint;

  const _SerialInfo({
    required this.c,
    required this.serial,
    required this.hint,
  });

  @override
  State<_SerialInfo> createState() => _SerialInfoState();
}

class _SerialInfoState extends State<_SerialInfo> {
  bool _revealed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = widget.c;
    final serial = widget.serial;

    // Can't read the hardware serial — tell the user how.
    final Widget value;
    if (serial == null || serial.isEmpty) {
      value = Text(
        widget.hint,
        style: TextStyle(fontSize: 13, color: c.textSecondary),
      );
    } else {
      final shown = (_revealed || _hover) ? serial : '••••••••';
      value = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => setState(() => _revealed = !_revealed),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  shown,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: c.textPrimary),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _revealed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 13,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              l.infoSerial,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : (_hover ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hover ? c.surface : c.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.cardBorder),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for a device name. Returns the trimmed name, or null when cancelled.
Future<String?> _promptDeviceName(BuildContext context, String current) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: current);
  final name = await showQLDialog<String>(
    context: context,
    title: l.renameDevice,
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: kDeviceNameMaxLength,
      style: TextStyle(color: context.ql.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: l.renameDeviceHint,
        hintStyle: TextStyle(color: context.ql.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.ql.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.ql.accent),
        ),
      ),
    ),
    leftAction: QLButton(
      label: l.cancel,
      onPressed: () => Navigator.of(context).pop(),
    ),
    rightAction: QLButton(
      label: l.save,
      onPressed: () => Navigator.of(context).pop(controller.text.trim()),
    ),
  );
  controller.dispose();
  return name;
}

/// Small pen that sits right after a title's text. Plain icon, lifts on
/// hover.
class _PenButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PenButton({required this.onTap});

  @override
  State<_PenButton> createState() => _PenButtonState();
}

class _PenButtonState extends State<_PenButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.18 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Icon(
            Icons.edit_rounded,
            size: 16,
            color: _hover ? c.textPrimary : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
