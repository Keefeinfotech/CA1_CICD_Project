import 'package:flutter/material.dart';

/// Shared design tokens for Auxilia's enterprise visual language.
class AuxiliaColors {
  const AuxiliaColors._();

  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoDeep = Color(0xFF3730A3);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDeep = Color(0xFF0891B2);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color canvas = Color(0xFFF5F7FB);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color darkCanvas = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceAlt = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF273449);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkMuted = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkCyan = Color(0xFF22D3EE);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[indigoDeep, indigo, cyanDeep],
    stops: <double>[0, 0.55, 1],
  );
}

class AuxiliaTheme {
  const AuxiliaTheme._();

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AuxiliaColors.indigo,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF312E81),
    secondary: AuxiliaColors.cyanDeep,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFCFFAFE),
    onSecondaryContainer: Color(0xFF155E75),
    tertiary: AuxiliaColors.violet,
    onTertiary: Colors.white,
    error: AuxiliaColors.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Colors.white,
    onSurface: AuxiliaColors.slate900,
    onSurfaceVariant: AuxiliaColors.slate500,
    surfaceContainerHighest: AuxiliaColors.slate100,
    outline: AuxiliaColors.slate300,
    outlineVariant: AuxiliaColors.slate200,
    shadow: Color(0x1F0F172A),
    scrim: Color(0x660F172A),
    inverseSurface: AuxiliaColors.slate900,
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFFA5B4FC),
    surfaceTint: AuxiliaColors.indigo,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AuxiliaColors.darkPrimary,
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF312E81),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: AuxiliaColors.darkCyan,
    onSecondary: Color(0xFF083344),
    secondaryContainer: Color(0xFF155E75),
    onSecondaryContainer: Color(0xFFCFFAFE),
    tertiary: Color(0xFFC4B5FD),
    onTertiary: Color(0xFF2E1065),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AuxiliaColors.darkSurface,
    onSurface: AuxiliaColors.darkText,
    onSurfaceVariant: AuxiliaColors.darkMuted,
    surfaceContainerHighest: AuxiliaColors.darkSurfaceAlt,
    outline: Color(0xFF334155),
    outlineVariant: AuxiliaColors.darkBorder,
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    inverseSurface: AuxiliaColors.darkText,
    onInverseSurface: AuxiliaColors.darkCanvas,
    inversePrimary: AuxiliaColors.indigo,
    surfaceTint: AuxiliaColors.darkPrimary,
  );

  static ThemeData light() => _build(_lightScheme, AuxiliaColors.canvas);

  static ThemeData dark() => _build(_darkScheme, AuxiliaColors.darkCanvas);

  static ThemeData _build(ColorScheme scheme, Color canvas) {
    final bool isLight = scheme.brightness == Brightness.light;
    final ThemeData base = ThemeData(
      brightness: scheme.brightness,
      useMaterial3: true,
    );
    final TextTheme applied = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final TextTheme textTheme = applied.copyWith(
      headlineMedium: applied.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: applied.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: applied.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: applied.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleSmall: applied.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: applied.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: applied.bodyMedium?.copyWith(height: 1.45),
    );

    final BorderRadius fieldRadius = BorderRadius.circular(14);
    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final Color fieldFill = isLight
        ? AuxiliaColors.slate100
        : AuxiliaColors.darkSurfaceAlt;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.12),
        disabledColor: scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: scheme.outline),
          shape: buttonShape,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: textTheme.labelLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AuxiliaColors.slate900
            : AuxiliaColors.darkSurfaceAlt,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: const Color(0xFFA5B4FC),
        elevation: 3,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: scheme.outline, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
    );
  }
}
