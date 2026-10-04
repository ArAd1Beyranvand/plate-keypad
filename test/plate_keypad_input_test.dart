import 'package:plate_core/plate_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_keypad/plate_keypad.dart';

/// The pad wired to a plate, exactly as a host wires it: taps go to
/// [PlateController.submit], and the pad reads which layer to show off the
/// controller's active slot.

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _letters = PlateAlphabet(
  id: 'zz.letters',
  characters: ['A', 'B', 'C'],
  input: AlphabetInput.chosen,
  isNumeric: false,
);

/// One chosen letter then two typed digits — Lebanon's shape.
final PlateSpec _spec = PlateSpec(
  id: 'zz.keypad',
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: const PlatePanel(box: PlateBox(0, 0, 10, 40)),
  slots: <PlateSlot>[
    PlateSlot(alphabet: _letters, box: const PlateBox(20, 5, 20, 30)),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: const PlateBox(45, 5, 20, 30),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: const PlateBox(70, 5, 20, 30),
    ),
  ],
);

class _Host extends StatelessWidget {
  const _Host({required this.controller});

  final PlateController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          PlateCanvas(
            spec: _spec,
            controller: controller,
            inputSource: PlateInputSource.packageKeypad,
            onChooseCharacter: (PlateAlphabet a) async => null,
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, _) {
              final PlateSlot? active = controller.activeSlot;
              return PlateKeypad(
                highlightedKey: null,
                showLetters: active != null && !active.alphabet.isNumeric,
                digitAlphabet: PlateAlphabet.latinDigits,
                letterAlphabet: _letters,
                activeAlphabet: active?.alphabet,
                onKey: (String key) => key == kPlateBackspaceKey
                    ? controller.backspace()
                    : controller.submit(key),
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Runs the body on [platform]. Desktop is the interesting one: there a
/// TextField's default `onTapOutside` unfocuses the field on pointer-down, so
/// a pad key press used to steal the plate's active slot before the tap it
/// belonged to could submit anything.
void _on(
  TargetPlatform platform,
  String description,
  WidgetTesterCallback body,
) {
  testWidgets('$description (${platform.name})', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body(tester);
    } finally {
      // Reset inside the body: flutter_test asserts no foundation debug
      // variable outlives it, and that check runs before any tearDown.
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.linux,
    TargetPlatform.android,
  ]) {
    _on(platform, 'tapping a digit key fills the focused digit slot', (
      tester,
    ) async {
      final PlateController controller = PlateController(spec: _spec);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_Host(controller: controller));

      await tester.tap(find.byType(TextField).at(0));
      await tester.pumpAndSettle();
      expect(
        controller.activeIndex,
        1,
        reason: 'tapping the digit slot focuses it',
      );

      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      expect(controller.values[1], '7');
    });

    _on(platform, 'the letter then the digits, all from the pad', (
      tester,
    ) async {
      final PlateController controller = PlateController(spec: _spec);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_Host(controller: controller));

      controller.focusSlot(0);
      await tester.pumpAndSettle();

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(controller.values[0], 'B');
      expect(
        controller.activeIndex,
        1,
        reason: 'the letter advances focus to the first digit',
      );

      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(controller.values, <String?>['B', '4', '2']);
    });
  }
}
