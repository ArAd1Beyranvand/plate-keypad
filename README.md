# plate_keypad

The optional on-screen keypad for the [`plate_number`](../plate-core) plate
library (renamed `core_plate` in a later phase of the split).

Most hosts drive a `PlateCanvas` from the system keyboard, a hardware keyboard,
or their own UI and never need this package. It exists for the case where you
want a self-contained soft keyboard painted below the plate, plus the modal
character wheel a `chosen`-alphabet slot opens.

## Depends on

`plate_number` (by path), for `PlateAlphabet` — the character set each key
renders. Nothing else.

## Use

```dart
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
has `chosen`-alphabet slots.
