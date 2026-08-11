import 'dart:async';
import 'dart:io' show Platform;

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart' show Brightness, ValueNotifier;
import 'package:flutter/widgets.dart' show WidgetsBinding;

import '../core/constants.dart';
import 'log_service.dart';

/// Reports the OS-wide brightness (dark/light) for the app's "auto" mode.
///
/// Linux: reads the XDG Desktop Portal `org.freedesktop.appearance
/// color-scheme` setting. GNOME, KDE Plasma and Flatpak all implement it,
/// so it's the one API that works across desktops — including sandboxed
/// apps. Polled (same idiom as the device poll) so auto mode follows live
/// changes without DBus match-rule fragility. Falls back to Flutter's
/// platform brightness if the portal isn't available.
///
/// Windows/macOS: Flutter's platform brightness (the engine already reads
/// the OS theme there), updated via WidgetsBindingObserver.
class ThemeBrightnessService {
  ThemeBrightnessService._();

  static final ThemeBrightnessService instance = ThemeBrightnessService._();

  /// Whether we read from the Linux portal instead of the engine.
  final bool usesPortal = Platform.isLinux;

  final ValueNotifier<Brightness> brightness =
      ValueNotifier<Brightness>(_engineBrightness);

  DBusClient? _client;
  Timer? _pollTimer;

  static Brightness get _engineBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  /// Starts watching the OS brightness. Safe to call multiple times.
  Future<void> start() async {
    if (usesPortal && _client == null) {
      try {
        _client = DBusClient.session();
        await _poll();
        _pollTimer ??= Timer.periodic(kThemeBrightnessPoll, (_) => _poll());
      } catch (e) {
        LogService.error('DBus session failed: $e');
        _client = null;
      }
    }
  }

  Future<void> _poll() async {
    final client = _client;
    if (client == null) return;
    try {
      final response = await client.callMethod(
        destination: 'org.freedesktop.portal.Desktop',
        path: DBusObjectPath('/org/freedesktop/portal/desktop'),
        interface: 'org.freedesktop.portal.Settings',
        name: 'Read',
        values: const [
          DBusString('org.freedesktop.appearance'),
          DBusString('color-scheme'),
        ],
        replySignature: DBusSignature('v'),
      );
      final code = _colorCode(response.values.first);
      final next = switch (code) {
        1 => Brightness.dark,
        2 => Brightness.light,
        _ => _engineBrightness,
      };
      if (next != brightness.value) brightness.value = next;
    } catch (e) {
      LogService.error('Portal brightness read failed: $e');
    }
  }

  /// The portal wraps the reply in at least one [DBusVariant] — unwrap any
  /// nesting to reach the actual uint32 color-scheme code.
  static int _colorCode(Object? value) {
    while (value is DBusVariant) {
      value = value.value;
    }
    return value is DBusUint32 ? value.value : -1;
  }
}
