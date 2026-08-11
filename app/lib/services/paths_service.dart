import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Single source of truth for all QuestLoad data paths.
///
/// Every consumer — settings, database, downloads — reads its paths from here.
/// There is no duplicated `$XDG_DATA_HOME` parsing anywhere else. Man i love tidy things.
///
/// 
///
/// Desktop: `getApplicationSupportDirectory()` (`~/.local/share/<bundle>/`)
/// Mobile: platform‑specific app‑internal storage 
///
/// The root directory is created on first access if it doesn't exist.
class PathsService {
  PathsService._();

  static String? _cachedRoot;

  /// The root QuestLoad data directory (cached after first resolution).
  static Future<String> get root async {
    if (_cachedRoot != null) return _cachedRoot!;
    final dir = await getApplicationSupportDirectory();
    final d = Directory(dir.path);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    _cachedRoot = dir.path;
    return _cachedRoot!;
  }

  /// Full path to `settings.json`.
  static Future<String> get settingsPath async =>
      "${await root}/settings.json";
}
