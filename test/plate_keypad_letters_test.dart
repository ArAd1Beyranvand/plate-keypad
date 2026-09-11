import 'package:core_plate/core_plate.dart';
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

  testWidgets('the layer is mounted for the whole slide and dropped at the '
      'end of it', (tester) async {
    await tester.pumpWidget(_pad(showLetters: false));
    expect(find.text('A'), findsNothing);

    // Sliding in: present from the first frame, so nothing pops into view.
    await tester.pumpWidget(_pad(showLetters: true));
    await tester.pump(kPlateKeypadSlide ~/ 2);
    expect(find.text('A'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);

    // Sliding out: still present while it moves, gone once it is dismissed.
    await tester.pumpWidget(_pad(showLetters: false));
    await tester.pump(kPlateKeypadSlide ~/ 2);
    expect(find.text('A'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);
  });

  testWidgets('the pad does not resize when the letters layer appears', (tester) async {
    // What makes mounting the layer late safe: the pad's inner height is fixed
    // by the digit rows, so the letters layer never contributes to layout.
    await tester.pumpWidget(_pad(showLetters: false));
    final Size closed = tester.getSize(find.byType(PlateKeypad));

    await tester.pumpWidget(_pad(showLetters: true));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PlateKeypad)), closed);
  });
}
