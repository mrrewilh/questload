import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'services/log_service.dart';
import 'services/theme_service.dart';
import 'services/adb_service.dart';
import 'app.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary - catches all Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService.error('FLUTTER ERROR: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService.error('PLATFORM ERROR: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (details) => _ErrorScreen(details.exception);

  final themes = ThemeService();
  await themes.load();

  final adb = AdbService();

  runApp(QuestLoadApp(adb: adb, themes: themes));

  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = kWindowInitialSize;
    win.minSize = kWindowMinSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = 'QuestLoad';
    win.show();
  });
}

/// Fallback error screen shown when the entire app crashes.
/// Minimal styling — theme may be broken at this point.
class _ErrorScreen extends StatelessWidget {
  final Object error;
  const _ErrorScreen(this.error);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Something went wrong\n$error',
            style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
          ),
        ),
      ),
    );
  }
}
