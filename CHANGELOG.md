## Unreleased

### P9 — the core is renamed

- The core dependency is now **`core_plate`** (was `plate_number`), resolved at
  `{path: ../core-plate}` (was `../plate-core`). The import inside this package
  is `package:core_plate/core_plate.dart`. No API of `plate_keypad` changed.
- Path-only: this package is not published to pub.dev (`core-plate/docs/split/PLAN.md`
  §6.6).

## 0.1.0

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
