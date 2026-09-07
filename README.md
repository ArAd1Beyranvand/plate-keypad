FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

The optional on-screen keypad for [`core_plate`](https://pub.dev/packages/core_plate),
for the hosts that don't already have a keyboard lying around.

## Also available

- [`core_plate`](https://pub.dev/packages/core_plate) - Paint license plates.
- [`core_plate_bloc`](https://pub.dev/packages/core_plate_bloc) - The optional bloc layer for `core_plate`.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's plates.

# plate_keypad

Most apps drive a `PlateCanvas` from the system keyboard, a hardware keyboard, or their
own UI and never need this. It's here for when you want a self-contained soft keyboard
under the plate, plus the modal character wheel a letter slot opens.

## Depends on

`core_plate` (`^0.1.0`), for `PlateAlphabet` - the characters each key renders.
Nothing else.

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

Pass `PlateCharacterPicker.show` as `PlateCanvas.onChooseCharacter` when a spec has
letter slots - `core_plate` ships no picker of its own.

## Contains

- `PlateKeypad`, `PlateKeypadTheme`, `kPlateBackspaceKey`, `kPlateKeypadSlide`.
- `PlateCharacterPicker` - the modal slot picker.
