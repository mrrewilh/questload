import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/app_theme.dart';
import 'log_service.dart';

/// Metadata for a single theme (loaded from `assets/themes/index.json`).
class ThemeMeta {
  final String id;
  final String name;
  final String family;
  final bool isDark;

  const ThemeMeta({
    required this.id,
    required this.name,
    required this.family,
    required this.isDark,
  });

  factory ThemeMeta.fromJson(Map<String, dynamic> json) => ThemeMeta(
    id: json['id'] as String,
    name: json['name'] as String,
    family: json['family'] as String? ?? '',
    isDark: json['isDark'] as bool? ?? true,
  );
}

/// A fully loaded theme (metadata + colors).
class ThemeDefinition extends ThemeMeta {
  final Map<String, String> colors;

  const ThemeDefinition({
    required super.id,
    required super.name,
    required super.family,
    required super.isDark,
    required this.colors,
  });

  factory ThemeDefinition.fromJson(Map<String, dynamic> json) =>
      ThemeDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        family: json['family'] as String? ?? '',
        isDark: json['isDark'] as bool? ?? true,
        colors: Map<String, String>.from(json['colors'] as Map),
      );

  QuestLoadColors buildColors() {
    // 'card' ships with a 50% alpha in the theme files (a blending artifact)
    // — floating dialogs on top of other content end up see-through. Card
    // must be opaque; every other key keeps its alpha.
    const opaqueKeys = {'card'};
    Color c(String key) {
      final hex = colors[key];
      if (hex == null) return Colors.transparent;
      final raw = hex.startsWith('#') ? hex.substring(1) : hex;
      final buffer = StringBuffer('0x');
      if (raw.length == 8) {
        if (opaqueKeys.contains(key)) {
          buffer.write('FF${raw.substring(0, 6)}');
        } else {
          // #RRGGBBAA → we need 0xAARRGGBB for Dart's Color()
          buffer.write('${raw.substring(6, 8)}${raw.substring(0, 6)}');
        }
      } else if (raw.length == 6) {
        // RRGGBB → treat as FFRRGGBB
        buffer.write('FF$raw');
      } else {
        return Colors.transparent;
      }
      try {
        return Color(int.parse(buffer.toString()));
      } catch (_) {
        return Colors.transparent;
      }
    }

    return QuestLoadColors(
      navBg: c('navBg'),
      navActiveBg: c('navActiveBg'),
      surface: c('surface'),
      surfaceLight: c('surfaceLight'),
      card: c('card'),
      cardBorder: c('cardBorder'),
      accent: c('accent'),
      textPrimary: c('textPrimary'),
      textSecondary: c('textSecondary'),
      textMuted: c('textMuted'),
      error: c('error'),
      success: c('success'),
      warning: c('warning'),
      scaffoldBg: c('scaffoldBg'),
    );
  }

  ThemeData buildThemeData() {
    final ql = buildColors();
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: ql.scaffoldBg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: ql.accent,
        secondary: ql.accent,
        surface: ql.surface,
        error: ql.error,
        onPrimary: ql.textPrimary,
        onSecondary: ql.textPrimary,
        onSurface: ql.textPrimary,
        onError: ql.textPrimary,
      ),
      extensions: [ql],
      cardColor: ql.card,
      dividerColor: ql.cardBorder,
      textTheme: AppTheme.textTheme(
        ql.textPrimary,
        ql.textSecondary,
        ql.textMuted,
      ),
      iconTheme: IconThemeData(color: ql.textSecondary),
      useMaterial3: true,
    );
  }
}

/// Loads and provides access to all available themes.
///
/// Themes are stored as individual JSON files under `assets/themes/`.
/// Metadata is loaded eagerly from the index; full color data is
/// loaded on demand when a theme is selected.
class ThemeService {
  List<ThemeMeta> _index = [];
  final Map<String, ThemeDefinition> _cache = {};
  bool _loaded = false;

  List<ThemeMeta> get index => _index;
  bool get loaded => _loaded;

  /// Load the theme index from `assets/themes/index.json`.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final json = await rootBundle.loadString('assets/themes/index.json');
      final list = jsonDecode(json) as List<dynamic>;
      _index = list
          .map((e) => ThemeMeta.fromJson(e as Map<String, dynamic>))
          .toList();
      _loaded = true;
    } catch (e) {
      LogService.error('Failed to load theme index: $e');
      _index = [];
      _loaded = true;
    }
  }

  /// Load a single theme's full data from `assets/themes/{id}.json`.
  Future<ThemeDefinition?> loadTheme(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    try {
      final json = await rootBundle.loadString('assets/themes/$id.json');
      final def = ThemeDefinition.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      _cache[id] = def;
      return def;
    } catch (e) {
      LogService.error('Failed to load theme "$id": $e');
      return null;
    }
  }

  /// All distinct theme families, in index order.
  List<String> get families {
    final seen = <String>{};
    final result = <String>[];
    for (final t in _index) {
      if (seen.add(t.family)) result.add(t.family);
    }
    return result;
  }

  /// Themes belonging to a given family.
  List<ThemeMeta> byFamily(String family) =>
      _index.where((t) => t.family == family).toList();
}
