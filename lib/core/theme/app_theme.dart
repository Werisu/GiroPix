import 'package:flutter/material.dart';

/// Paleta de destaque escolhida pelo usuário. O fundo permanece escuro.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String id;
  final String label;
  final Color primary;
  final Color secondary;
  final Color onPrimary;
  final Color onSecondary;

  static const verde = AppPalette(
    id: 'verde',
    label: 'Verde',
    primary: Color(0xFF00FF9C),
    secondary: Color(0xFF00D4FF),
    onPrimary: Color(0xFF001A10),
    onSecondary: Color(0xFF001820),
  );

  static const azul = AppPalette(
    id: 'azul',
    label: 'Azul',
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF22D3EE),
    onPrimary: Colors.white,
    onSecondary: Color(0xFF042028),
  );

  static const violeta = AppPalette(
    id: 'violeta',
    label: 'Violeta',
    primary: Color(0xFFC084FC),
    secondary: Color(0xFF818CF8),
    onPrimary: Color(0xFF1A1028),
    onSecondary: Color(0xFF101428),
  );

  static const ambar = AppPalette(
    id: 'ambar',
    label: 'Âmbar',
    primary: Color(0xFFFFB020),
    secondary: Color(0xFFFF7A18),
    onPrimary: Color(0xFF1A1200),
    onSecondary: Color(0xFF1A0C00),
  );

  static const rosa = AppPalette(
    id: 'rosa',
    label: 'Rosa',
    primary: Color(0xFFFF4D8D),
    secondary: Color(0xFFFF8AC4),
    onPrimary: Colors.white,
    onSecondary: Color(0xFF2A1020),
  );

  static const ciano = AppPalette(
    id: 'ciano',
    label: 'Ciano',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF00B4D8),
    onPrimary: Color(0xFF001418),
    onSecondary: Color(0xFF001820),
  );

  static const presets = [verde, azul, violeta, ambar, rosa, ciano];

  static AppPalette byId(String? id) {
    for (final palette in presets) {
      if (palette.id == id) return palette;
    }
    return verde;
  }
}

extension AppAccent on BuildContext {
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get accentAlt => Theme.of(this).colorScheme.secondary;
  Color get onAccent => Theme.of(this).colorScheme.onPrimary;
  Color get onAccentAlt => Theme.of(this).colorScheme.onSecondary;
}

/// Paleta dark com acentos neon (Pix / tech).
class AppColors {
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF121826);
  static const Color surfaceLight = Color(0xFF1A2235);
  static const Color border = Color(0xFF2A3548);

  static const Color neonGreen = Color(0xFF00FF9C);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonCyan = Color(0xFF00F0FF);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8B9BB8);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color warning = Color(0xFFFFB020);
  static const Color profit = Color(0xFF00FF9C);
  static const Color expense = Color(0xFFFF6B6B);
}

class AppTheme {
  static ThemeData forPalette(AppPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: palette.onPrimary,
        onSecondary: palette.onSecondary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary.withValues(alpha: 0.45);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return null;
        }),
        checkColor: WidgetStateProperty.all(palette.onPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
