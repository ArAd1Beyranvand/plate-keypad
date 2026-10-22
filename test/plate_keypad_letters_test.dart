import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_keypad/plate_keypad.dart';

/// The letters layer is not built while it is out of sight.
///
/// It is up to 30 keys — each a gesture detector, a scale and a decoration —
/// and it used to be built and laid out unconditionally, including on every
/// rebuild caused by focus moving between a digit slot and a letter slot, which
/// happens while the user is typing. This is the one-line guard against that
/// coming back.

Widget _pad({required bool showLetters}) => MaterialApp(
  home: Scaffold(
    body: PlateKeypad(
      highlightedKey: null,
      showLetters: showLetters,
      digitAlphabet: PlateAlphabet.latinDigits,
      letterAlphabet: PlateAlphabet.latinUppercase,
    ),
  ),
);

void main() {
  testWidgets('hidden letters are not in the tree', (tester) async {
    await tester.pumpWidget(_pad(showLetters: false));

    expect(find.text('A'), findsNothing);
    expect(find.text('Z'), findsNothing);
    // The digit pad is unaffected.
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shown letters are in the tree', (tester) async {
    await tester.pumpWidget(_pad(showLetters: true));

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
  });

  testWidgets('a switch shows one grid at a time, swapping at the midpoint', (tester) async {
    await tester.pumpWidget(_pad(showLetters: false));

    // Digits stagger out first; the letters are not built yet.
    await tester.pumpWidget(_pad(showLetters: true));
    await tester.pump(kPlateKeypadSlide * 0.25);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('A'), findsNothing);

    // Past the midpoint only the letters remain.
    await tester.pump(kPlateKeypadSlide * 0.5);
    expect(find.text('7'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_pad(showLetters: false));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('the pad resizes to the letters grid and back', (tester) async {
    await tester.pumpWidget(_pad(showLetters: false));
    final Size digits = tester.getSize(find.byType(PlateKeypad));

    // 26 letters lay out as 6 rows against the digits' 4.
    await tester.pumpWidget(_pad(showLetters: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PlateKeypad)).height, greaterThan(digits.height));

    await tester.pumpWidget(_pad(showLetters: false));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PlateKeypad)), digits);
  });
}
