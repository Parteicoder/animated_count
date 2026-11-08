import 'package:flutter/widgets.dart';

/// Delay between two neighbouring digit wheels, the ones digit starts first.
const _stagger = Duration(milliseconds: 40);

/// An integer shown as odometer-style digit wheels that roll to the new number.
///
/// Every digit is its own wheel. When [value] changes, each wheel rolls through
/// the digits in between (up when the number grows, down when it shrinks), the
/// wheels start one after another from the right, and the default [curve]
/// overshoots a little so they settle with a small bounce. Digits that appear or
/// disappear (12 to 142, 142 to 7) slide in or out and the row of digits grows or
/// shrinks smoothly.
///
/// Anything in [format], [prefix] and [suffix] that is not a digit (a thousands
/// separator, a unit) stays plain text. Screen readers always get the final
/// text, never a rolling wheel. If the system disables animations, the number
/// jumps to its target.
///
/// Unlike [AnimatedCount] this needs a custom layout (one fixed-width cell per
/// digit, tabular figures), so it is not a single `Text`.
///
/// ```dart
/// RollingCount(
///   value: posterCount,
///   suffix: posterCount == 1 ? ' poster' : ' posters',
///   style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
/// )
/// ```
class RollingCount extends StatefulWidget {
  /// Creates a rolling number.
  ///
  /// [value] is the number to show. [prefix] and [suffix] are plain text around
  /// it. Set [countFromZero] to also animate the first appearance, or
  /// [initialValue] to start that first roll from a number you remembered.
  /// [format] turns the number into text, for example to add thousands separators.
  const RollingCount({
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.countFromZero = false,
    this.initialValue,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutBack,
    this.format = _plain,
    super.key,
  });

  /// The number to show.
  final int value;

  /// Text before the number, e.g. `'Total: '`.
  final String prefix;

  /// Text after the number, e.g. `' items'`.
  final String suffix;

  /// The text style of everything. Falls back to the ambient
  /// [DefaultTextStyle] when null. Digits use tabular figures.
  final TextStyle? style;

  /// Roll up from 0 when the widget first appears.
  ///
  /// When false, the first frame shows [value] right away and only later
  /// changes are animated. Ignored when [initialValue] is set.
  final bool countFromZero;

  /// The number the very first roll starts from, usually the number this widget
  /// showed last time (kept by you, for example in `shared_preferences`).
  ///
  /// If it equals [value], nothing is animated. If it is null, the first roll
  /// follows [countFromZero].
  final int? initialValue;

  /// How long one wheel rolls. The last wheel starts a little later, so the
  /// whole effect takes slightly longer. Ignored (jumps instantly) if the system
  /// disables animations.
  final Duration duration;

  /// The easing of every wheel. Defaults to [Curves.easeOutBack], which settles
  /// with a small bounce.
  final Curve curve;

  /// Turns the number into text, e.g. to add thousands separators. Defaults to
  /// `int.toString`.
  final String Function(int number) format;

  /// The full text in its final state, e.g. what a screen reader announces.
  String get text => '$prefix${format(value)}$suffix';

  @override
  State<RollingCount> createState() => _RollingCountState();
}

class _RollingCountState extends State<RollingCount> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late int _from;
  int _totalMs = 0;

  TextStyle? _metricsStyle;
  TextScaler? _metricsScaler;
  double _digitWidth = 0;
  double _height = 0;
  final _glyphWidths = <String, double>{};

  @override
  void initState() {
    super.initState();
    _from = widget.initialValue ?? (widget.countFromZero ? 0 : widget.value);
    _roll();
  }

  @override
  void didUpdateWidget(RollingCount old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // ponytail: a change in the middle of a roll restarts from the old target
      // (a visible snap); animate from the shown position if that bothers you.
      _from = old.value;
      _roll();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _roll() {
    if (_from == widget.value) return;
    final columns = [widget.format(_from).length, widget.format(widget.value).length].reduce((a, b) => a > b ? a : b);
    _totalMs = widget.duration.inMilliseconds + _stagger.inMilliseconds * (columns - 1);
    _controller
      ..duration = Duration(milliseconds: _totalMs)
      ..forward(from: 0);
  }

  /// Measures the digit cell (widest digit, line height) once per style/scale.
  void _measure(TextStyle style, TextScaler scaler) {
    if (style == _metricsStyle && scaler == _metricsScaler) return;
    _metricsStyle = style;
    _metricsScaler = scaler;
    _glyphWidths.clear();
    _digitWidth = 0;
    _height = 0;
    for (var d = 0; d < 10; d++) {
      final painter = _painter('$d', style, scaler);
      if (painter.width > _digitWidth) _digitWidth = painter.width;
      if (painter.height > _height) _height = painter.height;
      painter.dispose();
    }
  }

  TextPainter _painter(String text, TextStyle style, TextScaler scaler) =>
      TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout();

  double _width(String? glyph, TextStyle style, TextScaler scaler) {
    if (glyph == null) return 0;
    if (_isDigit(glyph)) return _digitWidth;
    return _glyphWidths.putIfAbsent(glyph, () {
      final painter = _painter(glyph, style, scaler);
      final width = painter.width;
      painter.dispose();
      return width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = DefaultTextStyle.of(context).style
        .merge(widget.style)
        .merge(const TextStyle(fontFeatures: [FontFeature.tabularFigures()]));
    _measure(style, scaler);
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final elapsed = animate && _totalMs > 0 ? _controller.value * _totalMs : double.infinity;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.prefix.isNotEmpty) Text(widget.prefix, style: style),
              ..._columns(style, scaler, elapsed),
              if (widget.suffix.isNotEmpty) Text(widget.suffix, style: style),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _columns(TextStyle style, TextScaler scaler, double elapsedMs) {
    final from = widget.format(_from);
    final to = widget.format(widget.value);
    final up = widget.value >= _from;
    final count = from.length > to.length ? from.length : to.length;
    final result = <Widget>[];
    for (var i = count - 1; i >= 0; i--) {
      final a = i < from.length ? from[from.length - 1 - i] : null;
      final b = i < to.length ? to[to.length - 1 - i] : null;
      final local = ((elapsedMs - _stagger.inMilliseconds * i) / widget.duration.inMilliseconds).clamp(0.0, 1.0);
      final p = widget.curve.transform(local);
      if (a == b && !_isDigit(a)) {
        result.add(_cell(style, _width(b, style, scaler), [_glyph(b, style, 0)]));
      } else if (_isDigit(a) && _isDigit(b)) {
        final s = int.parse(a!);
        final e = int.parse(b!);
        final steps = up ? (e - s) % 10 : -((s - e) % 10);
        final x = s + steps * p;
        final floor = x.floor();
        result.add(_cell(style, _digitWidth, _slide('${floor % 10}', '${(floor + 1) % 10}', x - floor, 1, style)));
      } else {
        final width = _width(a, style, scaler) + (_width(b, style, scaler) - _width(a, style, scaler)) * p.clamp(0.0, 1.0);
        result.add(_cell(style, width, _slide(a, b, p, up ? 1 : -1, style)));
      }
    }
    return result;
  }

  /// One clipped cell with the glyphs slid to their places.
  Widget _cell(TextStyle style, double width, List<Widget> children) =>
      ClipRect(child: SizedBox(width: width, height: _height, child: Stack(children: children)));

  /// [a] leaves and [b] enters; [p] 0 shows only [a], 1 only [b]. [direction] 1
  /// moves up (b comes from below), -1 moves down.
  List<Widget> _slide(String? a, String? b, double p, int direction, TextStyle style) => [
    if (p < 1) _glyph(a, style, -direction * p),
    if (p > 0) _glyph(b, style, direction * (1 - p)),
  ];

  /// A glyph [offset] cell heights away from its place (0 = in place).
  Widget _glyph(String? glyph, TextStyle style, double offset) {
    if (glyph == null) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      top: offset * _height,
      height: _height,
      child: Center(child: Text(glyph, style: style, maxLines: 1, softWrap: false)),
    );
  }
}

bool _isDigit(String? c) => c != null && c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

String _plain(int number) => number.toString();
