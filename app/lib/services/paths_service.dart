import 'dart:io';

/// Single source of truth for all QuestLoad data paths.
///
/// Portable model: everything lives next to the executable, so deleting
/// the app folder removes the app and its data. The only leftover is adb's
/// own adbkey, which adb writes to the user home by itself.
class PathsService {
  PathsService._();

  static String? _cachedRoot;

  /// The root QuestLoad data directory (cached after first resolution).
  static Future<String> get root async {
    if (_cachedRoot != null) return _cachedRoot!;
    final execPath = Platform.resolvedExecutable;
    final dir = Directory(execPath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedRoot = dir.path;
    return _cachedRoot!;
  }

  /// Full path to `settings.json`.
  static Future<String> get settingsPath async =>
      "${await root}/settings.json";
}
