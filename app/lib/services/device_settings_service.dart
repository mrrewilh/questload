import 'dart:convert';
import 'dart:io';

import 'log_service.dart';
import 'paths_service.dart';

/// Per-device settings, keyed by the real hardware serial (ro.serialno).
/// Persisted to `devices.json` next to settings.json.
class DeviceSettingsService {
  DeviceSettingsService._();
  static final DeviceSettingsService instance = DeviceSettingsService._();

  final Map<String, Map<String, dynamic>> _devices = {};
  bool _loaded = false;

  Future<String> get _path async => '${await PathsService.root}/devices.json';

  /// Loads devices.json once (in-memory cache after that).
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = File(await _path);
      if (f.existsSync()) {
        final data = jsonDecode(f.readAsStringSync());
        if (data is Map<String, dynamic>) {
          _devices.addAll(
            data.map((k, v) => MapEntry(k, (v as Map).cast<String, dynamic>())),
          );
        }
      }
    } catch (e) {
      LogService.error('Failed to read devices.json: $e');
    }
  }

  Future<void> _save() async {
    try {
      await File(await _path).writeAsString(jsonEncode(_devices));
    } catch (e) {
      LogService.error('Failed to write devices.json: $e');
    }
  }

  String? nameFor(String realSerial) =>
      _devices[realSerial]?['name'] as String?;

  bool autoSelectFor(String realSerial) =>
      _devices[realSerial]?['autoSelect'] as bool? ?? false;

  Future<void> setName(String realSerial, String name) async {
    (_devices[realSerial] ??= {})['name'] = name;
    await _save();
  }

  /// Only one device is auto-selected at a time — turning it on for one
  /// clears it on every other.
  Future<void> setAutoSelect(String realSerial, bool value) async {
    if (value) {
      for (final k in _devices.keys) {
        if (k != realSerial) _devices[k]?.remove('autoSelect');
      }
    }
    (_devices[realSerial] ??= {})['autoSelect'] = value;
    await _save();
  }
}
