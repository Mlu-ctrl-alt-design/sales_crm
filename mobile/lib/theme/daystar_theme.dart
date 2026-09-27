import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Daystar Editorial": the brand the Daystar site already wears on Desk
/// (website theme `daystar_editorial` on crm-staging). Warm paper, navy ink,
/// one orange for the primary action, square corners throughout.
/// See docs/design/board.md.
abstract final class DaystarColors {
  /// Headings, body text, the app bar and outlines (`--ds-navy`).
  static const ink = Color(0xFF1A2332);

  /// The deepest navy, for pressed and emphasised states (`--ds-ink`).
  static const deepInk = Color(0xFF0B1220);
  static const muted = Color(0xFF6B7280);

  /// Hairlines: field underlines, list separators (`--ds-rule-soft`).
  static const line = Color(0x1F1A2332);
  static const divider = Color(0x1F1A2332);

  /// Page background (`--ds-paper`).
  static const surface = Color(0xFFFAF7F2);

  /// Hover, selected rows, icon tiles (`--ds-paper-2`).
  static const subtle = Color(0xFFF2EDE4);

  /// Actions that aren't the primary one: text buttons, focus, selection.
  static const brand = ink;
  static const brandSoft = subtle;

  /// The primary action, the + button and focus underlines (`--ds-orange`).
  /// Text on it is navy, as on Desk.
  static const accent = Color(0xFFFF5A1F);
  static const accentDeep = Color(0xFFE84A12);
  static const onAccent = ink;

  /// Money in and out only.
  static const moneyIn = Color(0xFF2F6B3A);
  static const moneyOut = Color(0xFFB3372F);
}

abstract final class DaystarFonts {
  /// Titles and money (Fraunces, `--ds-serif`).
  static const serif = 'Fraunces';

  /// Body and controls (Inter Tight, `--ds-sans`).
  static const sans = 'InterTight';

  /// Small uppercase labels, ids and dates (JetBrains Mono, `--ds-mono`).
  static const mono = 'JetBrainsMono';
}

class DaystarTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: DaystarColors.ink,
      onPrimary: DaystarColors.surface,
      primaryContainer: DaystarColors.subtle,
      onPrimaryContainer: DaystarColors.ink,
      secondary: DaystarColors.accent,
      onSecondary: DaystarColors.onAccent,
      error: DaystarColors.moneyOut,
      onError: Colors.white,
      surface: DaystarColors.surface,
      onSurface: DaystarColors.ink,
      onSurfaceVariant: DaystarColors.muted,
      outline: DaystarColors.line,
      outlineVariant: DaystarColors.divider,
      surfaceContainerHighest: DaystarColors.subtle,
      surfaceContainerHigh: DaystarColors.subtle,
      surfaceContainer: DaystarColors.surface,
      surfaceContainerLow: DaystarColors.surface,
    );

    const tabular = [FontFeature.tabularFigures()];
    const serif = TextStyle(
      fontFamily: DaystarFonts.serif,
      fontWeight: FontWeight.w800,
      color: DaystarColors.ink,
    );
    final text =
        TextTheme(
          displaySmall: serif.copyWith(
            fontSize: 36,
            letterSpacing: -0.7,
            height: 1.05,
            fontFeatures: tabular,
          ),
          headlineSmall: serif.copyWith(fontSize: 28, letterSpacing: -0.55),
          titleLarge: serif.copyWith(fontSize: 22, letterSpacing: -0.4),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          bodySmall: const TextStyle(fontSize: 12, color: DaystarColors.muted),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          // Eyebrows and field labels; pass the text through [eyebrow].
          labelSmall: const TextStyle(
            fontFamily: DaystarFonts.mono,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.6,
            color: DaystarColors.muted,
          ),
        ).apply(
          fontFamily: DaystarFonts.sans,
          bodyColor: DaystarColors.ink,
          displayColor: DaystarColors.ink,
        );
    // `apply` overrides every family; put the serif and mono ones back.
    final themed = text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontFamily: DaystarFonts.serif),
      headlineSmall: text.headlineSmall?.copyWith(
        fontFamily: DaystarFonts.serif,
      ),
      titleLarge: text.titleLarge?.copyWith(fontFamily: DaystarFonts.serif),
      labelSmall: text.labelSmall?.copyWith(
        fontFamily: DaystarFonts.mono,
        color: DaystarColors.muted,
      ),
    );

    const square = RoundedRectangleBorder();
    const buttonSize = Size.fromHeight(52);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: DaystarFonts.sans,
      textTheme: themed,
      scaffoldBackgroundColor: DaystarColors.surface,
      canvasColor: DaystarColors.surface,
      dividerColor: DaystarColors.divider,
      dividerTheme: const DividerThemeData(
        color: DaystarColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DaystarColors.ink,
        foregroundColor: DaystarColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: themed.titleLarge?.copyWith(
          color: DaystarColors.surface,
          fontSize: 21,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DaystarColors.accent,
          foregroundColor: DaystarColors.onAccent,
          disabledBackgroundColor: DaystarColors.subtle,
          disabledForegroundColor: DaystarColors.muted,
          minimumSize: buttonSize,
          shape: square,
          textStyle: themed.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DaystarColors.ink,
          minimumSize: buttonSize,
          shape: square,
          side: const BorderSide(color: DaystarColors.ink),
          textStyle: themed.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DaystarColors.ink,
          shape: square,
          textStyle: themed.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        labelStyle: themed.bodyLarge?.copyWith(color: DaystarColors.muted),
        floatingLabelStyle: themed.labelSmall?.copyWith(fontSize: 13),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: DaystarColors.line),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: DaystarColors.line),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: DaystarColors.accent, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: DaystarColors.moneyOut),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: DaystarColors.ink,
        selectionHandleColor: DaystarColors.accent,
        selectionColor: Color(0x40FF5A1F),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DaystarColors.accent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DaystarColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: DaystarColors.ink,
        indicatorShape: square,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => themed.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 1.2,
            color: states.contains(WidgetState.selected)
                ? DaystarColors.ink
                : DaystarColors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? DaystarColors.surface
                : DaystarColors.muted,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DaystarColors.accent,
        foregroundColor: DaystarColors.onAccent,
        elevation: 2,
        shape: square,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DaystarColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: DaystarColors.line,
        shape: Border(top: BorderSide(color: DaystarColors.ink)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: DaystarColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: Border.fromBorderSide(BorderSide(color: DaystarColors.ink)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DaystarColors.ink,
        contentTextStyle: themed.bodyMedium?.copyWith(
          color: DaystarColors.surface,
        ),
        actionTextColor: DaystarColors.accent,
        shape: square,
      ),
      listTileTheme: const ListTileThemeData(
        shape: square,
        selectedTileColor: DaystarColors.subtle,
      ),
    );
  }
}

/// Small uppercase mono label, as Desk uses for section heads and field
/// labels.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
  }
}
