import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:silky_scroll/silky_scroll.dart';
import '../l10n/app_localizations.dart';
import '../services/device_service.dart';
import '../services/adb_service.dart';
import '../services/log_service.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../widgets/ql_widgets.dart';

/// Maps a device model name to the matching headset SVG asset.
String _svgForModel(String? model) {
  if (model == null) return 'assets/headsets/unknown.svg';
  final m = model.toLowerCase();
  if (m.contains('quest 3s') || m.contains('quest3s')) {
    return 'assets/headsets/metaquest3s.svg';
  }
  if (m.contains('quest 3') || m.contains('quest3')) {
    return 'assets/headsets/metaquest3.svg';
  }
  if (m.contains('quest pro') || m.contains('questpro')) {
    return 'assets/headsets/metaquestpro.svg';
  }
  if (m.contains('quest 2') ||
      m.contains('quest2') ||
      m.contains('oculus quest 2')) {
    return 'assets/headsets/oculusquest2.svg';
  }
  if (m.contains('quest 1') ||
      m.contains('quest1') ||
      m.contains('oculus quest')) {
    return 'assets/headsets/oculusquest1.svg';
  }
  return 'assets/headsets/unknown.svg';
}

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
        connectedItems.add(
          _GridItem.connected(
            serial: serial,
            model: model,
            battery: battery,
            ipAddress: ip,
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
  /// Right-click menu on a device card.
  void _showDeviceMenu(Offset globalPosition, _GridItem item) {
    final l = AppLocalizations.of(context)!;
    final items = <QLContextMenuItem>[];
    if (item.isConnected) {
      // USB is a physical link — no disconnect; more actions come later.
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
    final scroller = widget.smoothScroll
        ? SilkyCustomScrollView.new
        : CustomScrollView.new;

    return Scaffold(
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
        ? _svgForModel(item.model)
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
              ? null
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
                      ? (item.model ?? item.serial)
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

  const _GridItem({
    required this.serial,
    required this.isConnected,
    this.model,
    this.battery,
    this.ipAddress,
    this.port,
  });

  factory _GridItem.connected({
    required String serial,
    String? model,
    String? battery,
    String? ipAddress,
  }) => _GridItem(
    serial: serial,
    isConnected: true,
    model: model,
    battery: battery,
    ipAddress: ipAddress,
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
