import 'package:flutter/material.dart';

// ─── Custom Theme Extensions ───────────────────────────────────────
// Unified color system: 3 preset surface levels + accent + text.
// Nav areas use navBg, active states use navActiveBg.

class QuestLoadColors extends ThemeExtension<QuestLoadColors> {
  /// Navigation background (sidebar, compact bar, bottom nav, drawer)
  final Color navBg;

  /// Active/hover state for nav items
  final Color navActiveBg;

  /// Card / panel backgrounds
  final Color card;

  /// Card / panel / input backgrounds
  final Color surface;

  /// Lighter surface for input fields, secondary panels
  final Color surfaceLight;

  /// Card / panel borders
  final Color cardBorder;

  /// Highlight accent
  final Color accent;

  /// Primary text
  final Color textPrimary;

  /// Secondary text
  final Color textSecondary;

  /// Muted / hint text
  final Color textMuted;

  /// Error states
  final Color error;

  /// Success states
  final Color success;

  /// Warning states
  final Color warning;

  /// Scaffold / page background
  final Color scaffoldBg;

  const QuestLoadColors({
    required this.navBg,
    required this.navActiveBg,
    required this.card,
    required this.surface,
    required this.surfaceLight,
    required this.cardBorder,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.success,
    required this.warning,
    required this.scaffoldBg,
  });

  @override
  QuestLoadColors copyWith({
    Color? navBg,
    Color? navActiveBg,
    Color? card,
    Color? surface,
    Color? surfaceLight,
    Color? cardBorder,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? error,
    Color? success,
    Color? warning,
    Color? scaffoldBg,
  }) => QuestLoadColors(
    navBg: navBg ?? this.navBg,
    navActiveBg: navActiveBg ?? this.navActiveBg,
    card: card ?? this.card,
    surface: surface ?? this.surface,
    surfaceLight: surfaceLight ?? this.surfaceLight,
    cardBorder: cardBorder ?? this.cardBorder,
    accent: accent ?? this.accent,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    error: error ?? this.error,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    scaffoldBg: scaffoldBg ?? this.scaffoldBg,
  );

  @override
  QuestLoadColors lerp(ThemeExtension<QuestLoadColors>? other, double t) {
    if (other is! QuestLoadColors) return this;
    return QuestLoadColors(
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navActiveBg: Color.lerp(navActiveBg, other.navActiveBg, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
    );
  }
}

// ─── Convenience getter ────────────────────────────────────────────

extension QLTheme on BuildContext {
  QuestLoadColors get ql {
    final ext = Theme.of(this).extension<QuestLoadColors>();
    assert(ext != null, 'QuestLoadColors not registered in theme');
    return ext!;
  }
}

// ─── Pre-built themes ──────────────────────────────────────────────
// Dark: navBg=#111 (dark sidebar), surface=#1A (cards), accent=#E0
// Light: navBg=#F0 (light sidebar), surface=#FFF (cards), accent=#1A

class AppTheme {
  /// Build a QuestLoadColors variant for light or dark mode with optional accent.
  static QuestLoadColors buildQL({required bool isDark, Color? accent}) {
    final base = isDark ? _darkQL : _lightQL;
    if (accent == null) return base;
    return base.copyWith(accent: accent);
  }

  static final QuestLoadColors _darkQL = QuestLoadColors(
    navBg: const Color(0xFF111111),
    navActiveBg: const Color(0xFF1E1E1E),
    surface: const Color(0xFF1A1A1A),
    surfaceLight: const Color(0xFF242424),
    card: const Color(0xFF222222),
    cardBorder: const Color(0xFF333333),
    accent: const Color(0xFFE0E0E0),
    textPrimary: const Color(0xFFF0F0F0),
    textSecondary: const Color(0xFF9E9E9E),
    textMuted: const Color(0xFF616161),
    error: const Color(0xFFCF6679),
    success: const Color(0xFF81C784),
    warning: const Color(0xFFFFD54F),
    scaffoldBg: const Color(0xFF0D0D0D),
  );

  static final QuestLoadColors _lightQL = QuestLoadColors(
    navBg: const Color(0xFFF0F0F0),
    navActiveBg: const Color(0xFFE8E8E8),
    surface: const Color(0xFFFFFFFF),
    surfaceLight: const Color(0xFFF5F5F5),
    card: const Color(0xFFFFFFFF),
    cardBorder: const Color(0xFFE0E0E0),
    accent: const Color(0xFF1A1A1A),
    textPrimary: const Color(0xFF1A1A1A),
    textSecondary: const Color(0xFF616161),
    textMuted: const Color(0xFF9E9E9E),
    error: const Color(0xFFB00020),
    success: const Color(0xFF2E7D32),
    warning: const Color(0xFFF9A825),
    scaffoldBg: const Color(0xFFF5F5F5),
  );

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkQL.scaffoldBg,
    colorScheme: ColorScheme.dark(
      surface: _darkQL.surface,
      primary: _darkQL.accent,
      secondary: _darkQL.accent,
      error: _darkQL.error,
    ),
    extensions: [_darkQL],
    cardColor: _darkQL.card,
    dividerColor: _darkQL.cardBorder,
    textTheme: textTheme(
      _darkQL.textPrimary,
      _darkQL.textSecondary,
      _darkQL.textMuted,
    ),
    iconTheme: IconThemeData(color: _darkQL.textSecondary),
    useMaterial3: true,
  );

  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightQL.scaffoldBg,
    colorScheme: ColorScheme.light(
      surface: _lightQL.surface,
      primary: _lightQL.accent,
      secondary: _lightQL.accent,
      error: _lightQL.error,
    ),
    extensions: [_lightQL],
    cardColor: _lightQL.card,
    dividerColor: _lightQL.cardBorder,
    textTheme: textTheme(
      _lightQL.textPrimary,
      _lightQL.textSecondary,
      _lightQL.textMuted,
    ),
    iconTheme: IconThemeData(color: _lightQL.textSecondary),
    useMaterial3: true,
  );

  static TextTheme textTheme(Color primary, Color secondary, Color muted) =>
      TextTheme(
        headlineLarge: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: primary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: primary),
        bodyMedium: TextStyle(color: secondary),
        bodySmall: TextStyle(color: muted),
        labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w500),
      );
}
