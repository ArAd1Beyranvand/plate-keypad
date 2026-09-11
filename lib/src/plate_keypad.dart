import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:core_plate/core_plate.dart';

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

  /// The focused slot's alphabet. Keys outside it render disabled — `submit()`
  /// would reject them anyway — since it may be a subset of [digitAlphabet] or
  /// [letterAlphabet]. Null disables no keys (e.g. no slot is focused).
  final PlateAlphabet? activeAlphabet;

  /// Colours used to paint the pad and its keys.
  final PlateKeypadTheme theme;

  @override
  State<PlateKeypad> createState() => _PlateKeypadState();
}

class _PlateKeypadState extends State<PlateKeypad> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: kPlateKeypadSlide);

  /// The letters pad's slide, built once.
  ///
  /// This used to be constructed inside `build`, so every rebuild of the pad —
  /// twice per keystroke while a typist is running — allocated a fresh [Tween]
  /// and [CurvedAnimation]. Harmless individually, but it is exactly the kind of
  /// steady per-frame garbage that turns into a GC pause partway through an
  /// animation and shows up as one dropped frame.
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  /// [_rows] flattened, once for the class rather than once per build.
  static final List<String> _digitLabels = _rows.expand((List<String> row) => row).toList(growable: false);

  /// [PlateKeypad.letterAlphabet]'s characters padded out to a full grid, and
  /// the alphabet they were computed from.
  ///
  /// The pad rebuilds whenever focus moves between a digit slot and a letter
  /// slot — during typing — and the padding walk is pure function of the
  /// alphabet, so it is done once per alphabet instead.
  List<String>? _letterCells;
  PlateAlphabet? _letterCellsFor;
  int _letterColumns = 1;
  int _letterRows = 1;

  @override
  void initState() {
    super.initState();
    if (widget.showLetters) {
      _controller.value = 1.0;
    }
    _controller.addStatusListener(_handleSlideStatus);
  }

  /// Rebuilds when the slide finishes retracting, so the letters layer can be
  /// dropped from the tree the moment it is fully out of sight. Without this
  /// the gate in [build] would only take effect at the pad's next rebuild.
  void _handleSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
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

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          SizedBox(
            height: innerHeight,
            child: _KeyGrid(
              labels: _digitLabels,
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
          // Built only while it is visible or moving. Off-screen it is up to 30
          // keys — a Builder, a GestureDetector, a scale and a decoration each
          // — laid out for something nobody can see, and the pad rebuilds every
          // time focus moves between a digit slot and a letter slot. The pad's
          // fixed [innerHeight] means mounting the layer late shifts no layout.
          if (widget.showLetters || !_controller.isDismissed) Positioned.fill(child: _buildLettersLayer(innerHeight)),
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

  /// Fills [_letterCells], [_letterColumns] and [_letterRows] for the current
  /// [PlateKeypad.letterAlphabet], reusing them when the alphabet has not
  /// changed.
  ///
  /// A roughly square grid, its width derived from how many letters there are
  /// rather than fixed, so a 16-letter and a 26-letter alphabet both lay out
  /// sensibly.
  ///
  /// Layout invariant: columns/rowCount are derived from
  /// letterAlphabet.characters.length only. activeAlphabet must never narrow
  /// the list the grid is built from — it only affects whether an
  /// already-placed key renders enabled — or the pad would reflow when focus
  /// moves to a slot with a subset alphabet.
  List<String> _letterCellsOf(PlateAlphabet alphabet) {
    final cached = _letterCells;
    if (cached != null && _letterCellsFor == alphabet) return cached;

    final List<String> alphabetLetters = alphabet.characters;
    _letterColumns = math.sqrt(alphabetLetters.length).ceil();
    _letterRows = (alphabetLetters.length / _letterColumns).ceil();

    // Pad the final row with blank spacers so every row has the same width.
    final List<String> letters = [...alphabetLetters];
    while (letters.length < _letterRows * _letterColumns) {
      letters.add('');
    }
    _letterCellsFor = alphabet;
    return _letterCells = letters;
  }

  Widget _buildLettersLayer(double innerHeight) {
    final List<String> letters = _letterCellsOf(widget.letterAlphabet);
    final int columns = _letterColumns;
    final int rowCount = _letterRows;
    // Divide the fixed inner height (minus the gaps between rows) so the
    // letters pad always ends flush with the digit pad.
    final double rowHeight = (innerHeight - 6 * (rowCount - 1)) / rowCount;

    final TextDirection direction = widget.letterAlphabet.direction;

    final Widget grid = Container(
      decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(12)),
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

    // No IgnorePointer: this layer only exists while it is on screen or moving
    // (see the gate in [build]), which is exactly when it used to be tappable.
    // The wrapper it replaces was an [AnimatedBuilder] rebuilding once per
    // frame of the slide to flip a bool that changes twice.
    return SlideTransition(position: _slide, child: grid);
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
    // Once per grid rather than once per disabled key per build.
    final Color dimBorder = theme.keyBorder.withValues(alpha: theme.keyBorder.a * 0.5);

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
                  // [_Key] derives its own reported key, enabled state and
                  // gesture from the label. This used to be a per-cell
                  // [Builder] wrapping a [GestureDetector], which bought
                  // nothing but an extra element per key — 42 on a full pad.
                  Expanded(
                    child: _Key(
                      label: labels[r * columns + c],
                      highlightedKey: highlightedKey,
                      highlightListenable: highlightedKeyListenable,
                      keyEnabled: keyEnabled,
                      onKey: onKey,
                      theme: theme,
                      dimBorder: dimBorder,
                      digitAlphabet: alphabet,
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
    required this.highlightedKey,
    required this.highlightListenable,
    required this.keyEnabled,
    required this.onKey,
    required this.theme,
    required this.dimBorder,
    this.digitAlphabet,
  });

  final String label;

  /// The pad's current highlight as a plain value. Ignored if
  /// [highlightListenable] is set — the key then watches that instead.
  final String? highlightedKey;

  /// The pad's current highlight, watched by this key alone.
  final ValueListenable<String?>? highlightListenable;

  /// Whether the key this cell reports is in the active alphabet. False leaves
  /// the key in the grid at the same position, rendered disabled; a disabled
  /// key is never highlighted, because it can't be tapped in the first place,
  /// so the two never conflict.
  final bool Function(String) keyEnabled;

  /// Fires with this key's reported label when it is tapped and enabled.
  final ValueChanged<String>? onKey;

  /// Colours used to paint this key.
  final PlateKeypadTheme theme;

  /// [PlateKeypadTheme.keyBorder] at half alpha, the disabled key's border.
  /// Computed once per grid by [_KeyGrid] rather than once per key per build.
  final Color dimBorder;

  /// When set, [label] is rendered through this alphabet (digit grid keys).
  /// When null, [label] is shown verbatim (letters grid keys, backspace).
  final PlateAlphabet? digitAlphabet;

  /// What this cell reports to [onKey]: its label, except for backspace.
  String get _key => label == '⌫' ? kPlateBackspaceKey : label;

  // Highlight presses stay quick (90ms in / 160ms out); an enabled<->disabled
  // transition tweens a bit slower (180ms) so the grey-out reads as a
  // deliberate fade rather than a snap. Const so no key allocates one.
  static const Duration _flashIn = Duration(milliseconds: 90);
  static const Duration _flashOut = Duration(milliseconds: 160);
  static const Duration _greyOut = Duration(milliseconds: 180);
  static final BorderRadius _radius = BorderRadius.circular(8);

  @override
  Widget build(BuildContext context) {
    // Empty label = blank spacer, no border. Checked before subscribing, so
    // spacer cells never listen to anything.
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final String key = _key;
    final bool enabled = keyEnabled(key);
    final Widget face;
    final listenable = highlightListenable;
    if (listenable == null) {
      face = _visual(key == highlightedKey, enabled);
    } else {
      face = ValueListenableBuilder<String?>(
        valueListenable: listenable,
        builder: (context, held, _) => _visual(held == key, enabled),
      );
    }

    return GestureDetector(onTap: enabled ? () => onKey?.call(key) : null, child: face);
  }

  Widget _visual(bool highlighted, bool enabled) {
    final Color ink = highlighted
        ? theme.highlightInk
        : enabled
        ? theme.ink
        : theme.disabledInk;

    final Duration duration = highlighted ? _flashIn : (enabled ? _flashOut : _greyOut);

    // Colour-only tweens rather than an [AnimatedContainer]. The corner radius,
    // border width and shape never change, so lerping a whole [BoxDecoration]
    // paid for a pile of always-constant fields — and a focus move between a
    // digit and a letter slot restarts this on every key whose membership
    // changed, up to 42 at once, while the user is typing. Same 180ms fade,
    // same look; two `Color.lerp`s instead of a `BoxDecoration.lerp`.
    return AnimatedScale(
      scale: highlighted ? 0.94 : 1.0,
      duration: duration,
      curve: Curves.easeOut,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: highlighted ? theme.highlight : Colors.transparent),
        duration: duration,
        curve: Curves.easeOut,
        child: Center(
          child: Text(
            label == '⌫' || digitAlphabet == null ? label : digitAlphabet!.render(label),
            style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        builder: (context, fill, child) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: highlighted
                ? theme.highlight
                : enabled
                ? theme.keyBorder
                : dimBorder,
          ),
          duration: duration,
          curve: Curves.easeOut,
          child: child,
          builder: (context, border, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: fill ?? Colors.transparent,
              borderRadius: _radius,
              border: Border.all(color: border ?? theme.keyBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
