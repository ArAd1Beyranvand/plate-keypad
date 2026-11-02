/// The optional on-screen keypad for `plate_core`.
///
/// [PlateKeypad] is a soft keyboard drawn inside your layout, for hosts that
/// render none of their own. [PlateCharacterPicker] is the modal wheel a
/// `chosen`-alphabet slot opens. Both render through a `PlateAlphabet`; for
/// ready-made digit and letter alphabets use `plate_alphabet`.
///
/// Anything under `src/` not exported here is an implementation detail.
library;

/// The keypad, its theme, and the constants a typist syncs against
/// (`kPlateBackspaceKey`, `kPlateKeypadSlide`).
export 'src/plate_keypad.dart';
export 'src/plate_character_picker.dart';
