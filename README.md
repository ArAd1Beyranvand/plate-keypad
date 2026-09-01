# plate_keypad

The optional on-screen keypad for the [`core_plate`](https://pub.dev/packages/core_plate) library.

Most hosts drive a `PlateCanvas` from the system keyboard, a hardware keyboard,
or their own UI and never need this package. It exists for the case where you
want a self-contained soft keyboard painted below the plate, plus the modal
character wheel a `chosen`-alphabet slot opens.

## Depends on

`core_plate` (`^0.1.0`), for `PlateAlphabet` — the character set
each key renders.

## Does not depend on

`iran_plate`, `germany_plate`, or anything else.

## Use

```dart
import 'package:core_plate/core_plate.dart';
import 'package:plate_keypad/plate_keypad.dart';

PlateKeypad(
  highlightedKey: null,
  digitAlphabet: PlateAlphabet.latinDigits,
  letterAlphabet: PlateAlphabet.latinUppercase,
  onKey: (key) => key == kPlateBackspaceKey
      ? controller.backspace()
      : controller.submit(key),
)
```

Pass `PlateCharacterPicker.show` as `PlateCanvas.onChooseCharacter` when a spec
has `chosen`-alphabet slots — `core_plate` ships no built-in picker.

## Contains

- `PlateKeypad`, `PlateKeypadTheme`, `kPlateBackspaceKey`, `kPlateKeypadSlide`.
- `PlateCharacterPicker` — the modal slot picker.
