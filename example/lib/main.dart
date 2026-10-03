import 'package:flutter/material.dart';
import 'package:core_plate/core_plate.dart';
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
              Expanded(
                child: Center(child: Text(_typed.isEmpty ? '—' : _typed)),
              ),
              PlateKeypad(
                highlightedKey: null,
                digitAlphabet: PlateAlphabet.latinDigits,
                letterAlphabet: PlateAlphabet.latinUppercase,
                onKey: (key) => setState(() {
                  _typed = key == kPlateBackspaceKey
                      ? _typed.substring(
                          0,
                          _typed.isEmpty ? 0 : _typed.length - 1,
                        )
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
