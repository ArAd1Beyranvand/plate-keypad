import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';

/// Backspace's key label; not a character any alphabet accepts.
const String kPlateBackspaceKey = 'BACKSPACE';

/// Duration of the letters-pad slide in/out. Public because a typist can
/// await this same constant to sync with the animation.
const Duration kPlateKeypadSlide = Duration(milliseconds: 260);

/// Colours used to paint a [PlateKeypad] and its keys.
///
/// Immutable; supply a custom instance to restyle the pad, or use the const
/// default.
@immutable
class PlateKeypadTheme {
  const PlateKeypadTheme({
    this.surface = const Color(0xFF1C1F26),
    this.keyBorder = const Color(0x3DFFFFFF),
    this.ink = Colors.white,
    this.disabledInk = const Color(0x4DFFFFFF),
    this.highlight = const Color(0xFFE8A33D),
    this.highlightInk = const Color(0xFF05080B),
  });

  /// Background of the pad and the letters layer.
  final Color surface;

  /// Hairline border drawn around each enabled key.
  final Color keyBorder;

  /// Label colour of an enabled key.
  final Color ink;

  /// Label colour of a disabled key.
  final Color disabledInk;

  /// Fill and border colour of a flashed (highlighted) key.
  final Color highlight;

  /// Label colour of a flashed (highlighted) key.
  final Color highlightInk;
}

/// A fake soft keyboard drawn inside the device screen, below the plate.
///
/// Taps report through [onKey] when set; a key can also be flashed
/// programmatically by passing its label as [highlightedKey].
class PlateKeypad extends StatefulWidget {
  const PlateKeypad({
    super.key,
    required this.highlightedKey,
    this.highlightedKeyListenable,
    this.compact = false,
    this.showLetters = false,
    this.onKey,
    required this.digitAlphabet,
    required this.letterAlphabet,
    this.activeAlphabet,
    this.theme = const PlateKeypadTheme(),
  });

  /// Label of the key to flash; null flashes nothing.
  ///
  /// Ignored when [highlightedKeyListenable] is supplied.
  final String? highlightedKey;

  /// The key to flash, as something the individual keys can watch.
  ///
  /// Prefer this over [highlightedKey] for anything that flashes keys rapidly —
  /// an auto-typist, or a host echoing hardware presses. Passing the label as a
  /// plain field means a new [PlateKeypad] per flash, which rebuilds the whole
  /// pad: the digit grid, the letters grid (~30 keys, built even while it is
  /// slid out of sight), every [GestureDetector], and the row/column structure
  /// the grid is laid out from. With a listenable the structure is built once
  /// and only the keys re-evaluate whether they are lit.
  final ValueListenable<String?>? highlightedKeyListenable;

  /// true on mobile (shorter keys), false on tablet.
  final bool compact;

  /// When true, the letters pad slides in over the digit pad.
  final bool showLetters;

  /// Fires with the tapped letter from the letters pad.
  final ValueChanged<String>? onKey;

  /// Alphabet used to render the digit grid's labels.
  final PlateAlphabet digitAlphabet;

  /// Alphabet used to render the letters pad's labels.
  final PlateAlphabet letterAlphabet;

  /// The focused slot's alphabet. Keys outside it render disabled — submit()
  /// would reject them anyway — since it may be a subset of [digitAlphabet]
  /// or [letterAlphabet]. Null disables no keys (e.g. no slot is focused).
  final PlateAlphabet? activeAlphabet;

  /// Colours used to paint the pad and its keys.
  final PlateKeypadTheme theme;

  @override
  State<PlateKeypad> createState() => _PlateKeypadState();
}

class _PlateKeypadState extends State<PlateKeypad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kPlateKeypadSlide,
  );

  /// The letters pad's slide, built once.
  ///
  /// This used to be constructed inside `build`, so every rebuild of the pad —
  /// twice per keystroke while a typist is running — allocated a fresh [Tween]
  /// and [CurvedAnimation]. Harmless individually, but it is exactly the kind of
  /// steady per-frame garbage that turns into a GC pause partway through an
  /// animation and shows up as one dropped frame.
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showLetters) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PlateKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLetters != oldWidget.showLetters) {
      if (widget.showLetters) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyHeight = widget.compact ? 44 : 56;
    // Fixed inner height so the pad never resizes when the letters layer
    // appears: 4 digit rows plus the three 6px gaps between them.
    final double innerHeight = _rows.length * keyHeight + 3 * 6;

    // Flatten digit rows into a single list.
    final List<String> digitLabels = _rows.expand((row) => row).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: innerHeight,
            child: _KeyGrid(
              labels: digitLabels,
              columns: _rows[0].length,
              rowHeight: keyHeight,
              textDirection: TextDirection.ltr,
              alphabet: widget.digitAlphabet,
              theme: widget.theme,
              highlightedKey: widget.highlightedKey,
              highlightedKeyListenable: widget.highlightedKeyListenable,
              onKey: widget.onKey,
              keyEnabled: (key) => _keyEnabled(key, widget.digitAlphabet),
            ),
          ),
          Positioned.fill(child: _buildLettersLayer(innerHeight)),
        ],
      ),
    );
  }

  /// Whether [key] should accept taps: always true for backspace, otherwise
  /// only when it is in [PlateAlphabet.characters] for the alphabet driving
  /// the pad it belongs to (the focused slot's alphabet when known, else the
  /// pad's own alphabet) — submit() would reject anything else. This is a fact
  /// about the alphabet, not a validation policy: a key in the active alphabet
  /// is always tappable, even when typing it would make the plate invalid.
  bool _keyEnabled(String key, PlateAlphabet ownAlphabet) {
    if (key.isEmpty) return false;
    if (key == kPlateBackspaceKey) return true;
    return (widget.activeAlphabet ?? ownAlphabet).accepts(key);
  }

  Widget _buildLettersLayer(double innerHeight) {
    final List<String> alphabetLetters = widget.letterAlphabet.characters;
    // A roughly square grid, its width derived from how many letters there
    // are rather than fixed, so a 16-letter and a 26-letter alphabet both
    // lay out sensibly.
    //
    // Layout invariant: columns/rowCount are derived from
    // letterAlphabet.characters.length only. activeAlphabet must never narrow
    // the list the grid is built from — it only affects whether an
    // already-placed key renders enabled — or the pad would reflow when focus
    // moves to a slot with a subset alphabet.
    final int columns = math.sqrt(alphabetLetters.length).ceil();
    final int rowCount = (alphabetLetters.length / columns).ceil();
    // Divide the fixed inner height (minus the gaps between rows) so the
    // letters pad always ends flush with the digit pad.
    final double rowHeight =
        (innerHeight - 6 * (rowCount - 1)) / rowCount;

    // Pad the final row with blank spacers so every row has the same width.
    final List<String> letters = [...alphabetLetters];
    while (letters.length < rowCount * columns) {
      letters.add('');
    }

    final TextDirection direction = widget.letterAlphabet.direction;

    final Widget grid = Container(
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: direction,
        child: _KeyGrid(
          labels: letters,
          columns: columns,
          rowHeight: rowHeight,
          textDirection: direction,
          alphabet: null,
          theme: widget.theme,
          highlightedKey: widget.highlightedKey,
          highlightedKeyListenable: widget.highlightedKeyListenable,
          onKey: widget.onKey,
          keyEnabled: (key) => _keyEnabled(key, widget.letterAlphabet),
        ),
      ),
    );

    final slide = SlideTransition(position: _slide, child: grid);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => IgnorePointer(
        ignoring: _controller.isDismissed,
        child: child,
      ),
      child: slide,
    );
  }
}

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({
    required this.labels,
    required this.columns,
    required this.rowHeight,
    required this.textDirection,
    required this.alphabet,
    required this.theme,
    required this.highlightedKey,
    required this.highlightedKeyListenable,
    required this.onKey,
    required this.keyEnabled,
  });

  final List<String> labels;
  final int columns;
  final double rowHeight;
  final TextDirection textDirection;
  final PlateAlphabet? alphabet;
  final PlateKeypadTheme theme;
  final String? highlightedKey;
  final ValueListenable<String?>? highlightedKeyListenable;
  final ValueChanged<String>? onKey;
  final bool Function(String) keyEnabled;

  @override
  Widget build(BuildContext context) {
    final int rowCount = (labels.length / columns).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rowCount; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final label = labels[r * columns + c];
                        final key = label == '⌫' ? kPlateBackspaceKey : label;
                        final enabled = keyEnabled(key);

                        return GestureDetector(
                          onTap: enabled ? () => onKey?.call(key) : null,
                          child: _Key(
                            label: label,
                            highlighted: highlightedKeyListenable == null &&
                                label.isNotEmpty &&
                                key == highlightedKey,
                            highlightListenable: highlightedKeyListenable,
                            highlightKey: key,
                            enabled: enabled,
                            theme: theme,
                            digitAlphabet: alphabet,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.highlighted,
    required this.enabled,
    required this.theme,
    this.digitAlphabet,
    this.highlightListenable,
    this.highlightKey,
  });

  final String label;

  /// Whether this key is lit, when the pad was handed a plain label. Ignored if
  /// [highlightListenable] is set — the key then works it out itself.
  final bool highlighted;

  /// The pad's current highlight, watched by this key alone.
  final ValueListenable<String?>? highlightListenable;

  /// The label this key reports; compared against [highlightListenable].
  final String? highlightKey;

  /// False when [label] is outside the active alphabet. Stays in the grid at
  /// the same position; a disabled key is never highlighted — [highlighted]
  /// always wins visually because a disabled key can't be tapped in the first
  /// place, so the two never conflict.
  final bool enabled;

  /// Colours used to paint this key.
  final PlateKeypadTheme theme;

  /// When set, [label] is rendered through this alphabet (digit grid keys).
  /// When null, [label] is shown verbatim (letters grid keys, backspace).
  final PlateAlphabet? digitAlphabet;

  @override
  Widget build(BuildContext context) {
    // Empty label = blank spacer, no border. Checked before subscribing, so
    // spacer cells never listen to anything.
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final listenable = highlightListenable;
    if (listenable == null) return _visual(highlighted);
    return ValueListenableBuilder<String?>(
      valueListenable: listenable,
      builder: (context, held, _) =>
          _visual(highlightKey != null && held == highlightKey),
    );
  }

  Widget _visual(bool highlighted) {
    final Color ink = highlighted
        ? theme.highlightInk
        : enabled
            ? theme.ink
            : theme.disabledInk;

    // Highlight presses stay quick (90ms in / 160ms out); an enabled<->
    // disabled transition tweens a bit slower (180ms) so the grey-out reads
    // as a deliberate fade rather than a snap.
    final Duration duration = Duration(
      milliseconds: highlighted ? 90 : (enabled ? 160 : 180),
    );

    return AnimatedScale(
      scale: highlighted ? 0.94 : 1.0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? theme.highlight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted
                ? theme.highlight
                : enabled
                    ? theme.keyBorder
                    : theme.keyBorder.withValues(
                        alpha: theme.keyBorder.a * 0.5,
                      ),
            width: 1,
          ),
        ),
        child: Text(
          label == '⌫' || digitAlphabet == null
              ? label
              : digitAlphabet!.render(label),
          style: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
