import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core_plate/core_plate.dart';

class PlateCharacterPicker extends StatefulWidget {
  const PlateCharacterPicker({super.key, required this.alphabet, this.scrollController});

  final PlateAlphabet alphabet;
  final FixedExtentScrollController? scrollController;

  static Future<String?> show(
    BuildContext context,
    PlateAlphabet alphabet, {
    FixedExtentScrollController? scrollController,
  }) => showModalBottomSheet<String>(
    context: context,
    builder: (_) => PlateCharacterPicker(alphabet: alphabet, scrollController: scrollController),
  );

  @override
  State<PlateCharacterPicker> createState() => _PlateCharacterPickerState();
}

class _PlateCharacterPickerState extends State<PlateCharacterPicker> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: CupertinoPicker(
              itemExtent: 44,
              scrollController: widget.scrollController,
              onSelectedItemChanged: (i) => _index = i,
              children: [
                for (final c in widget.alphabet.characters)
                  Center(child: Text(widget.alphabet.render(c), style: const TextStyle(fontSize: 22))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(widget.alphabet.characters[_index]),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
