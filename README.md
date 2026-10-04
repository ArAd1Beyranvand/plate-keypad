FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

The optional on-screen keypad for [`plate_core`](https://pub.dev/packages/plate_core),
for the hosts that don't already have a keyboard lying around.

## Also available

- [`plate_core`](https://pub.dev/packages/plate_core) - Paint license plates.
- [`plate_core_bloc`](https://pub.dev/packages/plate_core_bloc) - The optional bloc layer for `plate_core`.
- [`iran_plate`](https://pub.dev/packages/iran_plate) - Iran's plates.
- [`germany_plate`](https://pub.dev/packages/germany_plate) - Germany's plates.
- [`palestine_plate`](https://pub.dev/packages/palestine_plate) - Palestine's plates.
- [`yemen_plate`](https://pub.dev/packages/yemen_plate) - Yemen's plates.

# plate_keypad

Most apps drive a `PlateCanvas` from the system keyboard, a hardware keyboard, or their
own UI and never need this. It's here for when you want a self-contained soft keyboard
under the plate, plus the modal character wheel a letter slot opens.

## Depends on

`plate_core` (`^0.1.0`), for `PlateAlphabet` - the characters each key renders.
Nothing else.

## Use

```dart
import 'package:plate_core/plate_core.dart';
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
letter slots - `plate_core` ships no picker of its own. The repo's `plate_gallery/`
app drives both the pad and the picker against every country package it ships.

## Contains

- `PlateKeypad`, `PlateKeypadTheme`, `kPlateBackspaceKey`, `kPlateKeypadSlide`.
- `PlateCharacterPicker` - the modal slot picker.
