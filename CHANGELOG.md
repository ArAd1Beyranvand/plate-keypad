## 0.1.1

- Repaired a corrupted doc comment on `activeAlphabet` (P9 of the refactor
  roadmap). No API or behaviour change.

## 0.1.0

First pub.dev release.

- Depends on the published `core_plate: ^0.1.0` (was a sibling `path:`
  dependency). The import is `package:core_plate/core_plate.dart`. No API of
  `plate_keypad` changed.

- Extracted from `plate-core` (package `plate_number`) at commit `9c443e6`,
  core version `0.1.0` (unreleased), as phase P7 of the library split. This is
  a plain move — no code was rewritten in the transfer.
- Contains the library's optional on-screen keypad — `PlateKeypad`,
  `PlateKeypadTheme`, `kPlateBackspaceKey`, `kPlateKeypadSlide` — and the modal
  slot picker `PlateCharacterPicker`. Depends on `plate_number` by path for
  `PlateAlphabet` and nothing else.
- Consequence in core: `PlateCanvas.onChooseCharacter` is now **required** —
  core no longer ships a built-in picker to fall back to. A host that has
  `chosen`-alphabet slots supplies one, typically `PlateCharacterPicker.show`
  from this package.
