import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Builds the package defaults against a real Theme, which is what
  /// `BccmPlayerTheme.safeOf` does at runtime.
  Future<BccmControlsThemeData> defaults(WidgetTester tester) async {
    late BccmControlsThemeData result;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: Builder(builder: (context) {
        result = BccmControlsThemeData.defaultTheme(context);
        return const SizedBox.shrink();
      }),
    ));
    return result;
  }

  group('BccmControlsThemeData.fillWithDefaults', () {
    testWidgets('an explicitly set iconColor wins over primaryColor', (tester) async {
      // Regression: this read `primaryColor ?? iconColor ?? defaults.iconColor`,
      // so setting primaryColor made iconColor unreachable. It is an exported
      // theming API that all the consuming apps configure.
      final filled = BccmControlsThemeData(
        primaryColor: Colors.red,
        iconColor: Colors.blue,
      ).fillWithDefaults(await defaults(tester));

      expect(filled.iconColor, Colors.blue);
    });

    testWidgets('primaryColor still tints the icons when iconColor is unset', (tester) async {
      // Deliberate shorthand, matching what primaryColor does to the progress
      // bar below.
      final filled = BccmControlsThemeData(primaryColor: Colors.red)
          .fillWithDefaults(await defaults(tester));

      expect(filled.iconColor, Colors.red);
    });

    testWidgets('falls back to the default iconColor when neither is set', (tester) async {
      final base = await defaults(tester);
      final filled = BccmControlsThemeData().fillWithDefaults(base);

      expect(filled.iconColor, base.iconColor);
    });

    testWidgets('primaryColor recolors the progress bar track and thumb', (tester) async {
      final filled = BccmControlsThemeData(primaryColor: Colors.red)
          .fillWithDefaults(await defaults(tester));

      expect(filled.progressBarTheme?.activeTrackColor, Colors.red);
      expect(filled.progressBarTheme?.thumbColor, Colors.red);
    });

    testWidgets('an explicit progressBarTheme is left alone by primaryColor', (tester) async {
      final explicit = const SliderThemeData(activeTrackColor: Colors.purple);
      final filled = BccmControlsThemeData(primaryColor: Colors.red, progressBarTheme: explicit)
          .fillWithDefaults(await defaults(tester));

      expect(filled.progressBarTheme?.activeTrackColor, Colors.purple);
    });

    testWidgets('unset text styles come from the defaults', (tester) async {
      final base = await defaults(tester);
      final filled = BccmControlsThemeData().fillWithDefaults(base);

      expect(filled.durationTextStyle, base.durationTextStyle);
      expect(filled.settingsListTextStyle, base.settingsListTextStyle);
      expect(filled.fullscreenTitleStyle, base.fullscreenTitleStyle);
      expect(filled.settingsListBackgroundColor, base.settingsListBackgroundColor);
    });
  });

  group('BccmPlayerTheme.safeOf', () {
    testWidgets('yields the package defaults with no BccmPlayerTheme ancestor', (tester) async {
      late BccmPlayerThemeData theme;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          theme = BccmPlayerTheme.safeOf(context);
          return const SizedBox.shrink();
        }),
      ));

      // Both DefaultControls and PlayPauseButton do `.controls!`, so these must
      // never be null.
      expect(theme.controls, isNotNull);
      expect(theme.miniPlayer, isNotNull);
    });

    testWidgets('merges a partial theme over the defaults', (tester) async {
      late BccmPlayerThemeData theme;
      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerTheme(
          playerTheme: BccmPlayerThemeData(
            controls: BccmControlsThemeData(iconColor: Colors.orange),
          ),
          builder: (context) {
            theme = BccmPlayerTheme.safeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ));

      expect(theme.controls?.iconColor, Colors.orange);
      expect(theme.controls?.durationTextStyle, isNotNull, reason: 'unset fields still get defaults');
      expect(theme.miniPlayer, isNotNull, reason: 'the whole miniPlayer section defaults');
    });

    testWidgets('rejects setting both child and builder', (tester) async {
      expect(
        () => BccmPlayerTheme(
          playerTheme: BccmPlayerThemeData(),
          child: const SizedBox.shrink(),
          builder: (_) => const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('requires one of child or builder', (tester) async {
      expect(
        () => BccmPlayerTheme(playerTheme: BccmPlayerThemeData()),
        throwsAssertionError,
      );
    });
  });
}
