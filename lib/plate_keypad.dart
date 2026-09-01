/// The optional on-screen keypad for the `core_plate` library.
///
/// A [PlateKeypad] is a fake soft keyboard drawn inside your layout, for hosts
/// that do not render their own. [PlateCharacterPicker] is the modal wheel a
/// `chosen`-alphabet slot opens. Both render characters through a `PlateAlphabet`
/// from the core package and depend on nothing else in it.
///
/// Everything reachable from this file is API this package supports. Anything
/// under `src/` that this file does not export is an implementation detail:
/// `_KeyGrid` and `_Key` are the keypad's own business, not a consumer's.
library;

/// The soft keyboard, its theme, and the two constants a typist syncs against
/// (`kPlateBackspaceKey`, `kPlateKeypadSlide`).
export 'src/plate_keypad.dart';

/// The modal character wheel a `chosen`-alphabet slot opens; pass its `show`
/// to `PlateCanvas.onChooseCharacter`.
export 'src/plate_character_picker.dart';
