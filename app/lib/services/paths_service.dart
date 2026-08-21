import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Single source of truth for all QuestLoad data paths.
///
/// Windows/macOS: portable model — data lives in a `userdata/` folder next
/// to the executable, so deleting the app folder removes the app and its
/// data. Linux: the exe dir is a read-only AppImage mount or a system
/// folder, so data goes to the standard user data dir instead.
/// The only leftover anywhere is adb's own adbkey, which adb writes to
/// the user home by itself.
class PathsService {
  PathsService._();

  static String? _cachedRoot;

  /// The root QuestLoad data directory (cached after first resolution).
  static Future<String> get root async {
    if (_cachedRoot != null) return _cachedRoot!;
    if (Platform.isLinux) {
      final dir = await getApplicationSupportDirectory();
      final d = Directory(dir.path);
      if (!await d.exists()) await d.create(recursive: true);
      _cachedRoot = dir.path;
      return _cachedRoot!;
    }
    // Portable: data in a userdata/ folder next to the install root, so the
    // app files and user files don't mix in one folder. New layout is
    // ./qlapp/questload.exe + ./userdata, old layout was ./questload.exe +
    // ./userdata — both are handled.
    final execPath = Platform.resolvedExecutable;
    final exeDir = Directory(execPath).parent;
    final isQlapp = exeDir.path.split(Platform.pathSeparator).last == 'qlapp';
    final rootDir = isQlapp ? exeDir.parent : exeDir;
    final dir = Directory('${rootDir.path}/userdata');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedRoot = dir.path;
    return _cachedRoot!;
  }

  /// Full path to `settings.json`.
  static Future<String> get settingsPath async => "${await root}/settings.json";
}
