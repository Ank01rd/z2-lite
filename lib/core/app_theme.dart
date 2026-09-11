import 'package:flutter/material.dart';

/// Единая точка стиля: палитра, ThemeData и константы анимаций.
/// Строго нейтральный grayscale — ни одного синего оттенка.
/// Одни и те же duration/curve для ВСЕХ анимаций, поэтому тема
/// интерполируется целиком и одновременно во всём дереве.
class AppTheme {
  static const Duration animDuration = Duration(milliseconds: 260);
  static const Curve animCurve = Curves.easeInOutCubic;

  // Dark (чистый чёрный + нейтральные серые)
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF151515);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkMuted = Color(0xFF9A9A9A);

  // Light (чистый белый + нейтральные серые)
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightBorder = Color(0xFFE2E2E2);
  static const Color lightText = Color(0xFF0A0A0A);
  static const Color lightMuted = Color(0xFF666666);

  static ThemeData light() => _build(false);
  static ThemeData dark() => _build(true);

  static ThemeData _build(bool dark) {
    final bg = dark ? darkBg : lightBg;
    final surface = dark ? darkSurface : lightSurface;
    final border = dark ? darkBorder : lightBorder;
    final text = dark ? darkText : lightText;
    final muted = dark ? darkMuted : lightMuted;

    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: text,
      onPrimary: bg,
      secondary: muted,
      onSecondary: bg,
      error: text,
      onError: bg,
      surface: surface,
      onSurface: text,
      surfaceTint: Colors.transparent, // убирает синеватый tint Material 3
      outline: border,
      outlineVariant: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: border,
      splashFactory: NoSplash.splashFactory, // нет лишних вспышек
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: IconThemeData(color: muted, size: 17),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12.5),
        labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ).apply(bodyColor: text, displayColor: text),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: text,
          foregroundColor: bg,
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 44),
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          textStyle: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(
            color: text, fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text, fontSize: 12.5),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}