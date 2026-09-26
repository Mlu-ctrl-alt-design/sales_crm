import 'package:flutter/material.dart';

/// Direction A "Ledger": calm, white, type-led. One brand blue for actions;
/// green and red only for money in and out. See docs/design/board.md.
abstract final class DaystarColors {
  static const ink = Color(0xFF131B24);
  static const muted = Color(0xFF6B7682);
  static const line = Color(0xFFDCE2E8);
  static const divider = Color(0xFFEDF0F3);
  static const surface = Color(0xFFFFFFFF);
  static const subtle = Color(0xFFF4F6F8);
  static const brand = Color(0xFF1F4E79);
  static const brandSoft = Color(0xFFE3ECF5);
  static const moneyIn = Color(0xFF16794A);
  static const moneyOut = Color(0xFFB3372F);

  /// Borrowed from direction C: the quick-create button only.
  static const marigold = Color(0xFFF2A516);
  static const onMarigold = Color(0xFF1E1A0E);
}

abstract final class DaystarRadius {
  static const field = 10.0;
  static const button = 12.0;
  static const card = 16.0;
}

class DaystarTheme {
  static const fontFamily = 'Manrope';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: DaystarColors.brand,
      onPrimary: Colors.white,
      primaryContainer: DaystarColors.brandSoft,
      onPrimaryContainer: DaystarColors.brand,
      secondary: DaystarColors.marigold,
      onSecondary: DaystarColors.onMarigold,
      error: DaystarColors.moneyOut,
      onError: Colors.white,
      surface: DaystarColors.surface,
      onSurface: DaystarColors.ink,
      onSurfaceVariant: DaystarColors.muted,
      outline: DaystarColors.line,
      outlineVariant: DaystarColors.divider,
      surfaceContainerHighest: DaystarColors.subtle,
    );

    const tabular = [FontFeature.tabularFigures()];
    final text =
        const TextTheme(
          displaySmall: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.05,
            fontFeatures: tabular,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, height: 1.45),
          bodyMedium: TextStyle(fontSize: 14, height: 1.45),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          bodySmall: TextStyle(fontSize: 12, color: DaystarColors.muted),
        ).apply(
          fontFamily: fontFamily,
          bodyColor: DaystarColors.ink,
          displayColor: DaystarColors.ink,
        );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DaystarRadius.button),
    );
    const buttonSize = Size.fromHeight(52);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: DaystarColors.surface,
      dividerColor: DaystarColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: DaystarColors.surface,
        foregroundColor: DaystarColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
          side: const BorderSide(color: DaystarColors.line),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: DaystarColors.muted),
        border: _fieldBorder(DaystarColors.line),
        enabledBorder: _fieldBorder(DaystarColors.line),
        focusedBorder: _fieldBorder(DaystarColors.brand, width: 1.5),
        errorBorder: _fieldBorder(DaystarColors.moneyOut),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DaystarColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: DaystarColors.brandSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? DaystarColors.brand
                : DaystarColors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? DaystarColors.brand
                : DaystarColors.muted,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DaystarColors.marigold,
        foregroundColor: DaystarColors.onMarigold,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DaystarColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DaystarRadius.card),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DaystarColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaystarRadius.button),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(DaystarRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );
}
