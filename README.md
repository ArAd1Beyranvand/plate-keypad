FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

# plate_keypad

The optional on-screen input for [`plate_core`](https://pub.dev/packages/plate_core), for hosts that have no keyboard of their own. Two widgets, both rendered from a `PlateAlphabet`:

- **`PlateKeypad`** — a soft keyboard drawn in your layout beneath the plate. Digits, optional letters, a backspace key, the active alphabet highlighted. `PlateKeypad.numeric` is the digits-only variant in the script of the alphabet you pass (Persian, …).
- **`PlateCharacterPicker`** — the modal wheel a *chosen* slot opens (county letters, class symbols, region codes).

## Install

```yaml
dependencies:
  plate_core: ^0.12.0
  plate_keypad: ^0.1.2
```

## Use

```dart
final controller = PlateController(spec: IranPlates.civil);

Column(children: [
  PlateCanvas(
    spec: IranPlates.civil,
    controller: controller,
    onChooseCharacter: (alphabet) => PlateCharacterPicker.show(context, alphabet),
  ),
  PlateKeypad(
    highlightedKey: null,
    digitAlphabet: PersianAlphabets.digits,
    letterAlphabet: PersianAlphabets.privateLetters,
    onKey: (key) { /* feed the controller through a PlateInputSource */ },
  ),
]);
```

Core never depends on this package: the keypad reports key labels through `onKey` and the host decides where they go, so a plate can just as well be fed from a hardware keyboard or a scanner. Colours come from `PlateKeypadTheme`; `compact` shrinks the keys for narrow layouts.

## Part of plate

[`plate_core`](https://pub.dev/packages/plate_core) — the engine. [`plate_alphabet`](https://pub.dev/packages/plate_alphabet) — alphabets to render here.
