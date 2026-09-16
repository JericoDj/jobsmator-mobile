import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsmator_mobile/app/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Fonts are fetched at runtime in the app; tests use the fallback stack.
  setUpAll(() => JmText.useGoogleFonts = false);

  test('ColorScheme follows the design guide mapping', () {
    final t = buildTheme(Brightness.light);
    expect(t.colorScheme.primary, JmColors.light.ocean);
    expect(t.colorScheme.secondary, JmColors.light.sky);
    expect(t.colorScheme.tertiary, JmColors.light.match);
    expect(t.colorScheme.error, JmColors.light.danger);
    expect(t.colorScheme.onSurface, JmColors.light.ink);
    expect(t.extension<JmTierColors>(), JmTierColors.light);
    expect(t.extension<JmText>(), isNotNull);
  });

  test('dark theme swaps the palette and tier colours', () {
    final t = buildTheme(Brightness.dark);
    expect(t.scaffoldBackgroundColor, JmColors.dark.ground);
    expect(t.extension<JmTierColors>(), JmTierColors.dark);
  });

  test('gutter grows with width', () {
    expect(JmSpace.gutter(390), 16);
    expect(JmSpace.gutter(800), 24);
    expect(JmSpace.gutter(1400), 32);
  });
}
