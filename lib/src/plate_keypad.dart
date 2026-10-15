import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plate_core/plate_core.dart';

/// Backspace's key label; not a character any alphabet accepts.
const String kPlateBackspaceKey = 'BACKSPACE';

/// Letters alphabet of a numeric-only [PlateKeypad]; never shown.
const PlateAlphabet _noLetters = PlateAlphabet(
  id: 'keypad.noLetters',
  characters: <String>[],
  input: AlphabetInput.chosen,
  isNumeric: false,
);

/// Duration of the letters-pad slide; public so a typist can sync to it.
const Duration kPlateKeypadSlide = Duration(milliseconds: 260);

/// Colours of a [PlateKeypad] and its keys.
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

  /// Border of an enabled key.
  final Color keyBorder;
  final Color ink;
  final Color disabledInk;

  /// Fill and border of a flashed key.
  final Color highlight;
  final Color highlightInk;
}

/// A soft keyboard drawn in the layout, below the plate. Taps report through
/// [onKey]; a key flashes when its label is [highlightedKey].
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

  /// A digits-only keypad in the script of [digits] (such as
  /// `PlateAlphabetDigits.iranian`). It has no letters grid and reports each
  /// key in the script it shows; core folds that back to canonical storage.
  const PlateKeypad.numeric({
    super.key,
    required PlateAlphabet digits,
    this.highlightedKey,
    this.highlightedKeyListenable,
    this.compact = false,
    this.onKey,
    this.theme = const PlateKeypadTheme(),
  }) : digitAlphabet = digits,
       letterAlphabet = _noLetters,
       activeAlphabet = digits,
       showLetters = false;

  /// Label of the key to flash; ignored when [highlightedKeyListenable] is set.
  final String? highlightedKey;

  /// The key to flash, watched by the individual keys. Prefer it to
  /// [highlightedKey] for rapid flashing (an auto-typist, echoed hardware
  /// presses): a plain field rebuilds the whole pad per flash, whereas here
  /// only the keys re-evaluate.
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

  /// The focused slot's alphabet, possibly a subset of [digitAlphabet] or
  /// [letterAlphabet]. Keys outside it render disabled; null disables none.
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

  static final List<String> _digitLabels = _rows
      .expand((List<String> row) => row)
      .toList(growable: false);

  /// The letters grid for the alphabet it was computed from; the pad rebuilds
  /// on every focus move, so it is padded once per alphabet.
  ({PlateAlphabet alphabet, List<String> cells, int columns, int rows})?
  _letterGrid;

  @override
  void initState() {
    super.initState();
    if (widget.showLetters) _controller.value = 1.0;
    _controller.addStatusListener(_handleSlideStatus);
  }

  /// Rebuilds once the slide retracts so the letters layer leaves the tree.
  void _handleSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PlateKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLetters != oldWidget.showLetters) {
      widget.showLetters ? _controller.forward() : _controller.reverse();
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
    // Fixed, so the pad never resizes when the letters layer appears.
    final double innerHeight = _rows.length * keyHeight + 3 * 6;

    // Without this region, a TextField's default `onTapOutside` unfocuses on
    // desktop as a key goes down, so the tap lands on a plate with no active
    // slot.
    return TextFieldTapRegion(
      child: Container(
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
            // Mounted only while visible or moving: off-screen it is up to 30
            // keys laid out for nothing, and the fixed [innerHeight] means a
            // late mount shifts no layout.
            if (widget.showLetters || !_controller.isDismissed)
              Positioned.fill(
                child: _LettersLayer(
                  slide: _slide,
                  grid: _gridFor(widget.letterAlphabet),
                  innerHeight: innerHeight,
                  alphabet: widget.letterAlphabet,
                  theme: widget.theme,
                  highlightedKey: widget.highlightedKey,
                  highlightedKeyListenable: widget.highlightedKeyListenable,
                  onKey: widget.onKey,
                  keyEnabled: (key) => _keyEnabled(key, widget.letterAlphabet),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Whether [key] accepts taps: backspace always, otherwise only keys of the
  /// focused slot's alphabet (else the pad's own), which `submit()` would
  /// otherwise reject. A fact about the alphabet, not a validation policy.
  bool _keyEnabled(String key, PlateAlphabet ownAlphabet) {
    if (key.isEmpty) return false;
    if (key == kPlateBackspaceKey) return true;
    return (widget.activeAlphabet ?? ownAlphabet).accepts(key);
  }

  /// A roughly square grid sized from the letter count, so 16 and 26 letters
  /// both lay out sensibly. Derived from `letterAlphabet` alone: narrowing it
  /// by [PlateKeypad.activeAlphabet] would reflow the pad on focus moves.
  _Grid _gridFor(PlateAlphabet alphabet) {
    final cached = _letterGrid;
    if (cached != null && cached.alphabet == alphabet) return cached;
    final letters = alphabet.characters;
    final columns = math.sqrt(letters.length).ceil();
    final rows = (letters.length / columns).ceil();
    return _letterGrid = (
      alphabet: alphabet,
      // Blank spacers pad the last row to full width.
      cells: [
        ...letters,
        for (var i = letters.length; i < rows * columns; i++) '',
      ],
      columns: columns,
      rows: rows,
    );
  }
}

typedef _Grid = ({
  PlateAlphabet alphabet,
  List<String> cells,
  int columns,
  int rows,
});

/// The letters pad that slides over the digits.
class _LettersLayer extends StatelessWidget {
  const _LettersLayer({
    required this.slide,
    required this.grid,
    required this.innerHeight,
    required this.alphabet,
    required this.theme,
    required this.highlightedKey,
    required this.highlightedKeyListenable,
    required this.onKey,
    required this.keyEnabled,
  });

  final Animation<Offset> slide;
  final _Grid grid;
  final double innerHeight;
  final PlateAlphabet alphabet;
  final PlateKeypadTheme theme;
  final String? highlightedKey;
  final ValueListenable<String?>? highlightedKeyListenable;
  final ValueChanged<String>? onKey;
  final bool Function(String) keyEnabled;

  @override
  Widget build(BuildContext context) {
    // Rows share the fixed inner height so the pad ends flush with the digits.
    final rowHeight = (innerHeight - 6 * (grid.rows - 1)) / grid.rows;
    final direction = alphabet.direction;
    // No IgnorePointer: the layer exists only while on screen or moving.
    return SlideTransition(
      position: slide,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Directionality(
          textDirection: direction,
          child: _KeyGrid(
            labels: grid.cells,
            columns: grid.columns,
            rowHeight: rowHeight,
            textDirection: direction,
            alphabet: null,
            displayAlphabet: alphabet,
            theme: theme,
            highlightedKey: highlightedKey,
            highlightedKeyListenable: highlightedKeyListenable,
            onKey: onKey,
            keyEnabled: keyEnabled,
          ),
        ),
      ),
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
    this.displayAlphabet,
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

  /// Renders labels only; the reported key stays the raw label, so a letter
  /// shown as an icon still submits its character.
  final PlateAlphabet? displayAlphabet;
  final PlateKeypadTheme theme;
  final String? highlightedKey;
  final ValueListenable<String?>? highlightedKeyListenable;
  final ValueChanged<String>? onKey;
  final bool Function(String) keyEnabled;

  @override
  Widget build(BuildContext context) {
    final int rowCount = (labels.length / columns).ceil();
    final Color dimBorder = theme.keyBorder.withValues(
      alpha: theme.keyBorder.a * 0.5,
    );

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
                    child: _Key(
                      label: labels[r * columns + c],
                      index: r * columns + c,
                      count: labels.length,
                      highlightedKey: highlightedKey,
                      highlightListenable: highlightedKeyListenable,
                      keyEnabled: keyEnabled,
                      onKey: onKey,
                      theme: theme,
                      dimBorder: dimBorder,
                      digitAlphabet: alphabet,
                      displayAlphabet: displayAlphabet ?? alphabet,
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

class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.index,
    required this.count,
    required this.highlightedKey,
    required this.highlightListenable,
    required this.keyEnabled,
    required this.onKey,
    required this.theme,
    required this.dimBorder,
    this.digitAlphabet,
    this.displayAlphabet,
  });

  final String label;

  /// Position and grid size; they order the stagger as keys disable or return.
  final int index;
  final int count;

  /// The pad's highlight as a value; ignored if [highlightListenable] is set.
  final String? highlightedKey;
  final ValueListenable<String?>? highlightListenable;

  /// Whether this key is in the active alphabet. A disabled key keeps its
  /// place and is never highlighted.
  final bool Function(String) keyEnabled;

  /// Fires with the reported label when an enabled key is tapped.
  final ValueChanged<String>? onKey;
  final PlateKeypadTheme theme;

  /// [PlateKeypadTheme.keyBorder] at half alpha, shared by the grid.
  final Color dimBorder;

  /// Renders [label] into the reported key (digit grid); null reports it
  /// verbatim (letters, backspace).
  final PlateAlphabet? digitAlphabet;

  /// Renders [label] on the key face; null shows it verbatim.
  final PlateAlphabet? displayAlphabet;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  /// What this key reports: its label as the alphabet displays it (a Persian
  /// pad emits `'۵'`; core folds it back via `PlateAlphabet.canonical`), or
  /// the label verbatim without a `digitAlphabet`. Backspace is its own key.
  String get _key => widget.label == '⌫'
      ? kPlateBackspaceKey
      : widget.digitAlphabet == null
      ? widget.label
      : widget.digitAlphabet!.render(widget.label);

  /// Gap between neighbouring keys' turns when the enabled set changes.
  static const Duration _stagger = Duration(milliseconds: 18);

  /// The enabled state the face shows; trails the real one by the stagger.
  late bool _shown = widget.label.isNotEmpty && widget.keyEnabled(_key);
  Timer? _turn;

  @override
  void didUpdateWidget(_Key old) {
    super.didUpdateWidget(old);
    if (widget.label.isEmpty) return;
    final bool enabled = widget.keyEnabled(_key);
    if (enabled == _shown) {
      _turn?.cancel();
      return;
    }
    if (_turn?.isActive ?? false) return;
    // Keys going grey leave last-to-first; returning ones enter first-to-last.
    final int slot = enabled
        ? widget.count + widget.index
        : widget.count - 1 - widget.index;
    _turn = Timer(_stagger * slot, () {
      if (mounted) setState(() => _shown = widget.keyEnabled(_key));
    });
  }

  @override
  void dispose() {
    _turn?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A blank spacer: checked before subscribing, so it listens to nothing.
    if (widget.label.isEmpty) return const SizedBox.shrink();

    final key = _key;
    final listenable = widget.highlightListenable;
    final shown = _shown;
    return GestureDetector(
      onTap: widget.keyEnabled(key) ? () => widget.onKey?.call(key) : null,
      child: listenable == null
          ? _KeyFace(
              text: _text,
              highlighted: _isHighlight(widget.highlightedKey),
              enabled: shown,
              theme: widget.theme,
              dimBorder: widget.dimBorder,
            )
          : ValueListenableBuilder<String?>(
              valueListenable: listenable,
              builder: (context, held, _) => _KeyFace(
                text: _text,
                highlighted: _isHighlight(held),
                enabled: shown,
                theme: widget.theme,
                dimBorder: widget.dimBorder,
              ),
            ),
    );
  }

  String get _text => widget.label == '⌫' || widget.displayAlphabet == null
      ? widget.label
      : widget.displayAlphabet!.render(widget.label);

  /// Whether [candidate] names this key in either script: both sides are
  /// folded to canonical form, so a host highlighting with `'5'` still lights
  /// the `'۵'` key.
  bool _isHighlight(String? candidate) {
    if (candidate == null) return false;
    final key = _key;
    if (candidate == key) return true;
    final alphabet = widget.digitAlphabet;
    if (alphabet == null) return false;
    return alphabet.canonical(candidate) == alphabet.canonical(key);
  }
}

class _KeyFace extends StatelessWidget {
  const _KeyFace({
    required this.text,
    required this.highlighted,
    required this.enabled,
    required this.theme,
    required this.dimBorder,
  });

  final String text;
  final bool highlighted;
  final bool enabled;
  final PlateKeypadTheme theme;
  final Color dimBorder;

  // The grey-out is slower than a press so it reads as a fade, not a snap.
  static const Duration _flashIn = Duration(milliseconds: 90);
  static const Duration _flashOut = Duration(milliseconds: 160);
  static const Duration _greyOut = Duration(milliseconds: 180);
  static final BorderRadius _radius = BorderRadius.circular(8);

  @override
  Widget build(BuildContext context) {
    final ink = highlighted
        ? theme.highlightInk
        : enabled
        ? theme.ink
        : theme.disabledInk;
    final duration = highlighted ? _flashIn : (enabled ? _flashOut : _greyOut);

    // Colour-only tweens: radius, width and shape never change, so lerping a
    // whole BoxDecoration (as AnimatedContainer does) would be wasted across
    // the up to 42 keys a focus move restarts.
    return AnimatedScale(
      scale: highlighted ? 0.94 : 1.0,
      duration: duration,
      curve: Curves.easeOut,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          end: highlighted ? theme.highlight : Colors.transparent,
        ),
        duration: duration,
        curve: Curves.easeOut,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
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
              border: Border.all(color: border ?? theme.keyBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
