import 'package:flutter/foundation.dart'
    show PlatformDispatcher, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';
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

  await windowManager.ensureInitialized();
  await Window.initialize();

  final windowOptions = WindowOptions(
    size: kWindowInitialSize,
    minimumSize: kWindowMinSize,
    center: true,
    title: 'QuestLoad',
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      // Rounded-corner recipe (window_manager + flutter_acrylic):
      // drop the outline frame, then composition-level transparency.
      // Resize still works via DragToResizeArea -> startResizing.
      await windowManager.setAsFrameless();
      await Window.setEffect(effect: WindowEffect.transparent);
    }
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(QuestLoadApp(adb: adb, themes: themes));
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
