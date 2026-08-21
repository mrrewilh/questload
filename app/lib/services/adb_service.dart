import 'dart:async';
import 'dart:io';

import 'device_service.dart';
import 'log_service.dart';
import 'mdns_scanner.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';

/// ADB service using the bundled ADB binary.
///
/// The ADB binary is shipped inside the app bundle (next to the executable
/// as `platform-tools/adb`). No system ADB is needed, no PATH lookup.
///
/// On first run the binary is verified; if missing the app shows an error.
///
/// Error reporting: controlled failures return a short error *code*
/// (see [adbErrorMessage]); raw adb output passes through unchanged.
class AdbService {
  String? _adbPath;
  MdnsScanner? _scanner;
  bool _checkedAdb = false;
  Completer<String>? _pendingFind;

  bool get isOnDevice => false;

  //- Find bundled ADB ─

  /// Locate the ADB binary — system PATH on Linux, bundled platform-tools
  /// on Windows/macOS with a PATH fallback.
  ///
  /// Uses a [Completer] so concurrent callers wait for the first result
  /// instead of racing and getting an empty string.
  Future<String> _findAdb() async {
    if (_adbPath != null) return _adbPath!;
    if (_pendingFind != null) return _pendingFind!.future;
    if (_checkedAdb) return _adbPath ?? '';
    _checkedAdb = true;
    _pendingFind = Completer<String>();

    if (Platform.isLinux) {
      // Linux: system ADB only, bundled from distro
      try {
        final result = await Process.run('adb', [
          '--version',
        ]).timeout(kAdbCommandTimeout);
        if (result.exitCode == 0) {
          LogService.info('ADB found on system PATH');
          return _completeFind('adb');
        }
      } on TimeoutException {
        LogService.warning('ADB version check timed out');
      } catch (e) {
        LogService.error('ADB system PATH check failed: $e');
      }
      LogService.warning('ADB not found — is android-tools installed?');
      return _completeFind('');
    }

    // Windows / macOS: try bundled first, then PATH. With qlapp layout
    // the exe is .../qlapp/questload.exe and adb is .../qlapp/adb.exe or
    // .../qlapp/platform-tools/adb.exe
    final dirs = <String>{};

    // 1. From the running executable's directory (qlapp)
    try {
      final execPath = Platform.resolvedExecutable;
      if (execPath.isNotEmpty) {
        final execDir = Directory(execPath).parent;
        dirs.add(execDir.path);
        // qlapp's parent = QuestLoad root — also check there for legacy
        try {
          dirs.add(execDir.parent.path);
          dirs.add('${execDir.parent.path}/qlapp');
        } catch (_) {}
      }
    } catch (_) {
      LogService.warning('Could not resolve executable path');
    }

    // 2. From Platform.script (Dart snapshot path)
    try {
      final script = Platform.script;
      if (script.scheme == 'file') {
        dirs.add(Directory(script.toFilePath()).parent.path);
      }
    } catch (_) {
      LogService.warning('Could not resolve script path');
    }

    // 3. Current working directory
    try {
      dirs.add(Directory.current.path);
    } catch (_) {
      LogService.warning('Could not resolve current directory');
    }

    final binary = Platform.isWindows ? 'adb.exe' : 'adb';
    for (final dir in dirs) {
      final adbPath = '$dir/platform-tools/$binary';
      try {
        final file = File(adbPath);
        if (await file.exists()) {
          final result = await Process.run(adbPath, [
            '--version',
          ]).timeout(kAdbCommandTimeout);
          if (result.exitCode == 0) {
            LogService.info('ADB found at $adbPath');
            return _completeFind(adbPath);
          }
        }
      } on TimeoutException {
        LogService.warning('ADB check timed out at $adbPath');
      } catch (_) {
        LogService.warning('ADB check failed at $adbPath');
      }
    }

    // Fallback: system PATH
    try {
      final result = await Process.run('adb', [
        '--version',
      ]).timeout(kAdbCommandTimeout);
      if (result.exitCode == 0) {
        LogService.info('ADB found on system PATH');
        return _completeFind('adb');
      }
    } on TimeoutException {
      LogService.warning('System PATH ADB check timed out');
    } catch (_) {
      LogService.warning('System PATH ADB check failed');
    }

    LogService.warning('ADB not found');
    return _completeFind('');
  }

  /// Complete the pending find future and cache the result.
  String _completeFind(String path) {
    _adbPath = path;
    _pendingFind?.complete(path);
    _pendingFind = null;
    return path;
  }

  Future<bool> get hasAdb async {
    final path = await _findAdb();
    return path.isNotEmpty;
  }

  // ─── Pairing (Android 11+ wireless debugging) ────────────────────

  Future<AdbPairResult> pair(String ip, int port, String code) async {
    final adb = await _findAdb();
    if (adb.isEmpty) {
      return const AdbPairResult(success: false, error: 'adb_missing');
    }

    LogService.info('Pairing with $ip:$port');

    try {
      final result = await Process.run(adb, [
        'pair',
        '$ip:$port',
        code,
      ]).timeout(kAdbCommandTimeout);

      final output =
          (result.stdout?.toString() ?? '') + (result.stderr?.toString() ?? '');

      if (output.contains('Successfully paired') ||
          output.contains('already paired')) {
        // After pairing, the device appears on a different port for connect.
        // We can discover it via `adb mdns services` or prompt the user.
        return AdbPairResult(success: true);
      }

      if (output.contains('wrong code') || output.contains('incorrect')) {
        return const AdbPairResult(success: false, error: 'pair_wrong_code');
      }

      if (output.contains('refused')) {
        return const AdbPairResult(success: false, error: 'pair_refused');
      }

      return AdbPairResult(
        success: false,
        error: output.isNotEmpty ? output.trim() : 'pair_failed',
      );
    } on TimeoutException {
      return const AdbPairResult(success: false, error: 'pair_timeout');
    } catch (e) {
      LogService.error('Pairing failed: $e');
      return const AdbPairResult(success: false, error: 'pair_error');
    }
  }

  // ─── Connection ──────────────────────────────────────────────────

  Future<AdbConnectResult> connect(
    String ip, {
    int port = kDefaultAdbPort,
  }) async {
    final adb = await _findAdb();
    if (adb.isEmpty) {
      return const AdbConnectResult(success: false, error: 'adb_corrupted');
    }

    LogService.info('Connecting to $ip:$port');

    try {
      final result = await Process.run(adb, [
        'connect',
        '$ip:$port',
      ]).timeout(kAdbCommandTimeout);

      // Only check stdout — stderr may contain noise even on success.
      final stdout = (result.stdout?.toString() ?? '').trim();

      if (stdout.contains('connected to') ||
          stdout.contains('already connected')) {
        LogService.info('Connected to $ip:$port');
        await refreshDevices();

        final serialResult = await Process.run(adb, [
          '-s',
          '$ip:$port',
          'shell',
          'getprop',
          'ro.serialno',
        ]).timeout(kAdbShellTimeout);
        final serial = (serialResult.stdout?.toString() ?? '').trim();
        final deviceSerial = serial.isNotEmpty ? serial : '$ip:$port';

        if (!_cachedSerials.contains(deviceSerial)) {
          _cachedSerials.add(deviceSerial);
        }

        return AdbConnectResult(success: true, serial: deviceSerial);
      }

      // Unsuccessful — check stderr for more details.
      final stderr = (result.stderr?.toString() ?? '').trim();
      final full = '$stdout\n$stderr';

      if (full.contains('refused') || full.contains('unable to connect')) {
        LogService.warning('Connect to $ip:$port failed: $full');
        return const AdbConnectResult(success: false, error: 'connect_refused');
      }

      final msg = [stdout, stderr].where((s) => s.isNotEmpty).join('\n');
      LogService.warning(
        'Connect to $ip:$port failed: ${msg.isEmpty ? '(no output)' : msg}',
      );
      return AdbConnectResult(
        success: false,
        error: msg.isNotEmpty ? msg.trim() : 'connect_failed',
      );
    } on TimeoutException {
      LogService.warning('Connect to $ip:$port timed out');
      return const AdbConnectResult(success: false, error: 'connect_timeout');
    } on SocketException catch (e) {
      LogService.error('Network error while connecting: $e');
      return const AdbConnectResult(success: false, error: 'network_error');
    } catch (e) {
      LogService.error('Connect failed: $e');
      return const AdbConnectResult(success: false, error: 'connect_error');
    }
  }

  Future<bool> disconnect(String serial) async {
    final adb = await _findAdb();
    if (adb.isEmpty) return false;

    try {
      final result = await Process.run(adb, [
        'disconnect',
        serial,
      ]).timeout(kAdbConnectTimeout);
      _cachedSerials.remove(serial);
      return result.exitCode == 0;
    } catch (_) {
      LogService.warning('Disconnect failed for $serial');
      _cachedSerials.remove(serial);
      return false;
    }
  }

  bool isConnected(String serial) => _cachedSerials.contains(serial);

  List<String> get connectedSerials => List.unmodifiable(_cachedSerials);

  final List<String> _cachedSerials = [];

  /// Refresh the cached list of connected devices from `adb devices`.
  Future<List<String>> refreshDevices() async {
    final adb = await _findAdb();
    if (adb.isEmpty) {
      _checkedAdb = false;
      return [];
    }

    _cachedSerials.clear();

    try {
      final result = await Process.run(adb, [
        'devices',
      ]).timeout(kAdbConnectTimeout);
      final lines = (result.stdout?.toString() ?? '').split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('List')) continue;
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 2 && parts[1] == 'device') {
          _cachedSerials.add(parts[0]);
        }
      }
    } catch (_) {
      LogService.warning('refreshDevices failed');
    }

    return List.from(_cachedSerials);
  }

  // ─── Shell ───────────────────────────────────────────────────────

  Future<String> shell(String serial, String command) async {
    final adb = await _findAdb();
    if (adb.isEmpty) return '';

    try {
      final result = await Process.run(adb, [
        '-s',
        serial,
        'shell',
        command,
      ]).timeout(kAdbShellTimeout);
      return result.stdout?.toString() ?? '';
    } catch (e) {
      LogService.error('ADB shell error: $e');
      return '';
    }
  }

  // ─── Device Info ─────────────────────────────────────────────────

  Future<Map<String, String>> getProperties(String serial) async {
    final output = await shell(serial, 'getprop');
    final props = <String, String>{};
    for (final line in output.split('\n')) {
      final match = RegExp(r'\[([^\]]+)\]:\s*\[([^\]]*)\]').firstMatch(line);
      if (match != null) {
        props[match.group(1)!] = match.group(2)!;
      }
    }
    return props;
  }

  Future<String?> getBattery(String serial) async {
    final output = await shell(serial, 'dumpsys battery');
    final match = RegExp(r'level:\s*(\d+)').firstMatch(output);
    return match?.group(1);
  }

  /// Controller battery levels from the touch service.
  /// Output order is left then right; null when a level is missing.
  Future<({int? left, int? right})> getControllerBatteries(
    String serial,
  ) async {
    final output = await shell(serial, 'dumpsys OVRRemoteService');
    final levels = RegExp(r'Battery:\s*(\d+)')
        .allMatches(output)
        .map((m) => int.tryParse(m.group(1)!))
        .whereType<int>()
        .toList();
    if (levels.isEmpty) return (left: null, right: null);
    return (left: levels.first, right: levels.length > 1 ? levels[1] : null);
  }

  /// Real hardware serial via `getprop ro.serialno`.
  /// Works for both usb and wireless transports; null when unreadable.
  Future<String?> getDeviceSerial(String serial) async {
    final out = (await shell(serial, 'getprop ro.serialno')).trim();
    return out.isEmpty ? null : out;
  }

  Future<String?> getIpAddress(String serial) async {
    final output = await shell(serial, 'ip -4 addr show wlan0');
    final match = RegExp(r'inet\s+(\d+\.\d+\.\d+\.\d+)').firstMatch(output);
    return match?.group(1);
  }

  Future<List<String>> getInstalledPackages(String serial) async {
    final output = await shell(serial, 'pm list packages -3 --user 0');
    return output
        .split('\n')
        .map((l) => l.trim().replaceFirst('package:', ''))
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ─── Install / Uninstall ────────────────────────────────────────

  Future<bool> installApk(String serial, String apkPath) async {
    final adb = await _findAdb();
    if (adb.isEmpty) return false;

    try {
      final result = await Process.run(adb, [
        '-s',
        serial,
        'install',
        '-r',
        '-d',
        apkPath,
      ]).timeout(kAdbInstallTimeout);
      return (result.stdout?.toString() ?? '').contains('Success');
    } catch (e) {
      LogService.error('ADB install error: $e');
      return false;
    }
  }

  Future<bool> uninstall(String serial, String packageName) async {
    final adb = await _findAdb();
    if (adb.isEmpty) return false;

    try {
      final result = await Process.run(adb, [
        '-s',
        serial,
        'uninstall',
        packageName,
      ]).timeout(kAdbUninstallTimeout);
      final output = result.stdout?.toString() ?? '';
      return output.contains('Success') || output.contains('Deleted');
    } catch (e) {
      LogService.error('ADB uninstall error: $e');
      return false;
    }
  }

  // ─── Discovery ───────────────────────────────────────────────────

  Future<List<MdnsDiscoveredDevice>> scan({
    int timeoutSeconds = kMdnsTimeoutSeconds,
  }) async {
    _scanner ??= MdnsScanner();
    return await _scanner!.scan(timeoutSeconds: timeoutSeconds);
  }

  void stopScan() {
    _scanner?.stop();
    _scanner = null;
  }

  // ─── Version ─────────────────────────────────────────────────────

  String getVersion() => 'ADB (bundled)';

  // ─── Cleanup ─────────────────────────────────────────────────────

  Future<void> dispose() async {
    stopScan();
  }
}

/// Maps an [AdbService] error code to a localized message. Unknown codes
/// (raw adb output) pass through unchanged.
String adbErrorMessage(AppLocalizations l, String code, {String? ip}) {
  return switch (code) {
    'adb_missing' => l.adbMissingShort,
    'adb_corrupted' => l.adbCorrupted,
    'pair_wrong_code' => l.pairWrongCode,
    'pair_refused' => l.pairRefused,
    'pair_failed' => l.pairingFailed,
    'pair_timeout' => l.pairTimeout(ip ?? ''),
    'pair_error' => l.pairError,
    'connect_refused' => l.connectRefused,
    'connect_failed' => l.connectionFailed,
    'connect_timeout' => l.connectTimeout(ip ?? ''),
    'network_error' => l.connectNetworkError,
    'connect_error' => l.connectError,
    _ => code,
  };
}
