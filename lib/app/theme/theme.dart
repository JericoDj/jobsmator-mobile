import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

export 'tokens.dart';
export 'typography.dart';

/// ThemeData built from the design-guide tokens.
///
/// ColorScheme mapping (guide §09): primary = Cobalt, secondary = Azure,
/// tertiary = Match, error = Danger, surface = Surface, onSurface = Ink.
/// Volt is not a scheme slot — it lives in [JmTierColors].
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? JmColors.dark : JmColors.light;
  final tiers = dark ? JmTierColors.dark : JmTierColors.light;
  final type = JmText.forPalette(c);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.ocean,
    onPrimary: Colors.white,
    primaryContainer: c.oceanTint,
    onPrimaryContainer: c.oceanDeep,
    secondary: c.sky,
    onSecondary: JmColors.navy,
    secondaryContainer: c.skyTint,
    onSecondaryContainer: c.skyDeep,
    tertiary: c.match,
    onTertiary: JmColors.navy,
    tertiaryContainer: c.matchTint,
    onTertiaryContainer: c.matchDeep,
    error: c.danger,
    onError: Colors.white,
    errorContainer: c.dangerTint,
    onErrorContainer: c.danger,
    surface: c.ground,
    onSurface: c.ink,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.card,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface2,
    outline: c.lineStrong,
    outlineVariant: c.line,
    shadow: JmColors.navy,
    inverseSurface: JmColors.navy,
    onInverseSurface: Colors.white,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness);

  final textTheme = base.textTheme.copyWith(
    displayLarge: type.display,
    displayMedium: type.display,
    displaySmall: type.display,
    headlineLarge: type.title,
    headlineMedium: type.title,
    headlineSmall: type.title,
    titleLarge: type.title,
    titleMedium: type.heading,
    titleSmall: type.uiStrong,
    bodyLarge: type.body,
    bodyMedium: type.body.copyWith(fontSize: 15, height: 22 / 15),
    bodySmall: type.meta,
    labelLarge: type.uiStrong,
    labelMedium: type.ui,
    labelSmall: type.label,
  );

  // Buttons: height 40, radius 10, labels are verbs that name the outcome.
  final buttonShape = RoundedRectangleBorder(borderRadius: JmRadius.mdR);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 18);

  return base.copyWith(
    scaffoldBackgroundColor: c.ground,
    canvasColor: c.ground,
    cardColor: c.card,
    dividerColor: c.line,
    focusColor: c.focus,
    hoverColor: c.surface2,
    splashFactory: InkSparkle.splashFactory,
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    extensions: [c, tiers, type],
    appBarTheme: AppBarTheme(
      backgroundColor: c.ground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.ink,
      titleTextStyle: type.heading,
      iconTheme: IconThemeData(color: c.ink, size: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: buttonPadding,
            shape: buttonShape,
            backgroundColor: c.ocean,
            foregroundColor: Colors.white,
            disabledBackgroundColor: c.ocean.withValues(alpha: .45),
            disabledForegroundColor: Colors.white.withValues(alpha: .9),
            textStyle: type.uiStrong,
            elevation: 0,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)
                  ? c.oceanDeep.withValues(alpha: dark ? .35 : .6)
                  : null,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: buttonPadding,
            shape: buttonShape,
            foregroundColor: c.oceanDeep,
            side: BorderSide(color: c.lineStrong),
            textStyle: type.uiStrong,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered) ? c.oceanTint : null,
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: buttonShape,
            foregroundColor: c.text,
            textStyle: type.uiStrong,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered) ? c.surface2 : null,
            ),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(JmLayout.touchTarget, JmLayout.touchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: type.uiStrong.copyWith(fontSize: 14),
      floatingLabelStyle: type.uiStrong.copyWith(fontSize: 14, color: c.ink),
      hintStyle: type.ui.copyWith(color: c.faint, fontWeight: FontWeight.w400),
      helperStyle: type.meta,
      errorStyle: type.meta.copyWith(color: c.danger),
      border: OutlineInputBorder(
        borderRadius: JmRadius.mdR,
        borderSide: BorderSide(color: c.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: JmRadius.mdR,
        borderSide: BorderSide(color: c.lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: JmRadius.mdR,
        borderSide: BorderSide(color: c.ocean, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: JmRadius.mdR,
        borderSide: BorderSide(color: c.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: JmRadius.mdR,
        borderSide: BorderSide(color: c.danger, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: JmRadius.lgR,
        side: BorderSide(color: c.line),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: c.card,
      selectedColor: c.oceanTint,
      side: BorderSide(color: c.lineStrong),
      shape: RoundedRectangleBorder(borderRadius: JmRadius.pillR),
      labelStyle: type.ui.copyWith(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: true,
      checkmarkColor: c.oceanDeep,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.ocean,
      linearTrackColor: c.surface2,
      circularTrackColor: c.surface2,
      linearMinHeight: 5,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: JmColors.navy,
      contentTextStyle: type.ui.copyWith(color: Colors.white),
      actionTextColor: c.sky,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: JmRadius.lgR),
      titleTextStyle: type.title,
      contentTextStyle: type.body,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(JmRadius.lg))),
      showDragHandle: true,
      dragHandleColor: c.lineStrong,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : c.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ocean : c.surface2),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.ocean : c.lineStrong,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.ocean,
      inactiveTrackColor: c.surface2,
      thumbColor: c.ocean,
      overlayColor: c.sky.withValues(alpha: .2),
      trackHeight: 5,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.muted,
      textColor: c.ink,
      titleTextStyle: type.ui,
      subtitleTextStyle: type.meta,
      shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _JmPageTransitions(),
        TargetPlatform.iOS: _JmPageTransitions(),
        TargetPlatform.macOS: _JmPageTransitions(),
        TargetPlatform.linux: _JmPageTransitions(),
        TargetPlatform.windows: _JmPageTransitions(),
      },
    ),
  );
}

/// 200 ms enter/exit with the guide's easing; a short slide, never from
/// opacity 0 on a resting state — the incoming page starts at 60 % opacity.
class _JmPageTransitions extends PageTransitionsBuilder {
  const _JmPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: JmMotion.ease);
    return FadeTransition(
      opacity: Tween<double>(begin: .6, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
