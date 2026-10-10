import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinymind/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all packaged Baloo 2 weights load through google_fonts', () async {
    const fontAssets = {
      'assets/fonts/Baloo2-Regular.ttf',
      'assets/fonts/Baloo2-Medium.ttf',
      'assets/fonts/Baloo2-SemiBold.ttf',
      'assets/fonts/Baloo2-Bold.ttf',
      'assets/fonts/Baloo2-ExtraBold.ttf',
    };
    for (final asset in fontAssets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
    }

    final theme = buildAppTheme();
    final weights = [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
    ];
    final styles = [
      for (final weight in weights) GoogleFonts.baloo2(fontWeight: weight),
    ];

    await expectLater(GoogleFonts.pendingFonts(), completes);

    final themeStyles = [
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
      theme.textTheme.bodySmall,
      theme.textTheme.titleLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.titleSmall,
      theme.textTheme.labelLarge,
      theme.textTheme.labelMedium,
      theme.textTheme.labelSmall,
      theme.navigationBarTheme.labelTextStyle?.resolve({}),
    ].whereType<TextStyle>();
    for (final style in [...styles, ...themeStyles]) {
      expect(
        style.fontFamily,
        startsWith('Baloo2'),
        reason: 'Baloo 2 style unexpectedly fell back: $style',
      );
    }
  });
}
