import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color deepMaroon = Color(0xFF5E1236);

  static const Color primary = Color(0xFF861A4C);

  static const Color gold = Color(0xFFC9A24B);

  static const Color tint = Color(0xFFF6E7EE);
  static const Color background = Color(0xFFF7F4F5);
  static const Color text = Color(0xFF2A1A22);
  static const Color textMuted = Color(0xFF6E6168);
  static const Color border = Color(0xFFE8DDE2);
  static const Color surface = Colors.white;

  static const Color success = Color(0xFF2E7D4F);
  static const Color danger = Color(0xFFC0392B);
  static const Color warning = Color(0xFFB7791F);
  static const Color info = Color(0xFF1F5FA8);

  static const List<Color> blockColors = [
    Color(0xFFF6E0EA),
    Color(0xFFDCEBFA),
    Color(0xFFDFF3E5),
    Color(0xFFFFF0CC),
    Color(0xFFE8DEF8),
    Color(0xFFFFE3D6),
    Color(0xFFD9F2F2),
  ];

  static Color blockColorFor(String key) {
    final hash = key.codeUnits.fold<int>(7, (sum, unit) => sum * 31 + unit) & 0x7fffffff;
    return blockColors[hash % blockColors.length];
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Poppins');
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tint,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.danger),
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppColors.tint,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.text, fontSize: 13),
        checkmarkColor: AppColors.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.tint,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textMuted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textMuted,
            )),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
