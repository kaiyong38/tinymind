import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tinymind_colors.dart';

ThemeData buildAppTheme() {
  GoogleFonts.config.allowRuntimeFetching = false;
  final baseTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: TinyMindColors.primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: TinyMindColors.background,
    textTheme: GoogleFonts.baloo2TextTheme().apply(
      bodyColor: TinyMindColors.textDark,
      displayColor: TinyMindColors.textDark,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      constraints: BoxConstraints(minHeight: 56),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      backgroundColor: Colors.white,
      indicatorColor: TinyMindColors.primaryTint,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.baloo2(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
  return baseTheme;
}
