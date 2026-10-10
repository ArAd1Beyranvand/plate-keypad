FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================


# plate_keypad example

The keypad on its own, with no plate in sight — it just echoes what you press into a
string. Proof that it doesn't need a `PlateCanvas` to be useful.

Run it with `flutter run` from this directory.

```dart
import 'package:flutter/material.dart';
import 'package:plate_core/plate_core.dart';
import 'package:plate_keypad/plate_keypad.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(child: Center(child: Text(_typed.isEmpty ? '—' : _typed))),
              PlateKeypad(
                highlightedKey: null,
                digitAlphabet: PlateAlphabet.latinDigits,
                letterAlphabet: PlateAlphabet.latinUppercase,
                onKey: (key) => setState(() {
                  _typed = key == kPlateBackspaceKey
                      ? _typed.substring(0, _typed.isEmpty ? 0 : _typed.length - 1)
                      : _typed + key;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

In a real app `onKey` goes to a `PlateInputController` instead of a `setState`, and
`highlightedKey` tracks whichever slot is focused.

The `dependency_overrides` block in `pubspec.yaml` resolves the sibling packages from
this checkout. Delete it when you copy this into an app of your own.
