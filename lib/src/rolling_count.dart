import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How the digit wheels of a [RollingCount] move.
enum RollStyle {
  /// Flat odometer wheels that roll through the digits in between. The wheels
  /// start one after another from the right.
  odometer,

  /// Like [odometer], but every digit sits on a cylinder: it tilts away with
  /// perspective and fades towards the edge of the cell.
  drum,

  /// Slot machine: every wheel first spins one extra full turn, all at once, and
  /// they stop one after another from the left. Looks best with a longer
  /// `duration` (around one second).
  slot,
}

/// Which way the wheels of a [RollingCount] turn.
enum RollDirection {
  /// Up when the number grows, down when it shrinks.
  byChange,

  /// Always up, also when the number shrinks.
  up,

  /// Always down, also when the number grows.
  down,
}

/// An integer shown as odometer-style digit wheels that roll to the new number.
///
/// Every digit is its own wheel. When [value] changes, each wheel rolls through
/// the digits in between (up when the number grows, down when it shrinks), the
/// wheels start one after another from the right, and the default [curve]
/// overshoots a little so they settle with a small bounce. [roll] switches to a
/// 3D drum or a slot machine, [direction] forces the way the wheels turn,
/// [stagger] sets the delay between wheels and [upColor] / [downColor] tint the
/// text while it rolls. Digits that appear or
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
    this.roll = RollStyle.odometer,
    this.direction = RollDirection.byChange,
    this.stagger = const Duration(milliseconds: 40),
    this.upColor,
    this.downColor,
    this.format = _plain,
    this.onEnd,
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

  /// How the wheels move: flat [RollStyle.odometer] (default), 3D
  /// [RollStyle.drum] or [RollStyle.slot] machine.
  final RollStyle roll;

  /// Which way the wheels turn. Defaults to [RollDirection.byChange].
  final RollDirection direction;

  /// The delay between two neighbouring wheels. Zero makes all wheels move
  /// together.
  final Duration stagger;

  /// If set, the text briefly shifts to this color while the number rolls up
  /// (for example green), and back to its normal color when it stops.
  final Color? upColor;

  /// Like [upColor], for a number that shrinks (for example red).
  final Color? downColor;

  /// Turns the number into text, e.g. to add thousands separators. Defaults to
  /// `int.toString`.
  final String Function(int number) format;

  /// Called when a roll has finished, after all wheels stopped on [value].
  ///
  /// If [value] changes in the middle of a roll, only the last roll calls it.
  /// It is not called when nothing is animated: on the first appearance (unless
  /// [countFromZero] or [initialValue] is set) or when [value] did not change.
  /// A zero-length roll calls it at the end of the frame, so it may call `setState`.
  final VoidCallback? onEnd;

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
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      // A zero-length roll completes inside initState/didUpdateWidget: wait for the end of the frame.
      if (_totalMs == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onEnd?.call();
        });
      } else {
        widget.onEnd?.call();
      }
    });
    _roll();
  }

  @override
  void didUpdateWidget(RollingCount old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // A change in the middle of a roll continues from roughly what is shown
      // now (the eased progress of the old roll) instead of snapping to its target.
      // ponytail: the estimate ignores the per-wheel stagger, so single wheels can
      // still jump by a digit or two.
      _from = _controller.isAnimating ? _shownNow(old.value) : old.value;
      _roll();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The number roughly on display while the current roll is still running.
  int _shownNow(int target) {
    final t = (_controller.value * _totalMs / widget.duration.inMilliseconds).clamp(0.0, 1.0);
    final p = widget.curve.transform(t).clamp(0.0, 1.0);
    return _from + ((target - _from) * p).round();
  }

  void _roll() {
    if (_from == widget.value) return;
    final columns = [widget.format(_from).length, widget.format(widget.value).length].reduce((a, b) => a > b ? a : b);
    _totalMs = widget.duration.inMilliseconds + widget.stagger.inMilliseconds * (columns - 1);
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
          final running = animate && _totalMs > 0 && _controller.isAnimating;
          final elapsed = running ? _controller.value * _totalMs : double.infinity;
          final flash = widget.value >= _from ? widget.upColor : widget.downColor;
          final shown = flash != null && style.color != null && running
              ? style.copyWith(color: Color.lerp(style.color, flash, math.sin(math.pi * _controller.value)))
              : style;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.prefix.isNotEmpty) Text(widget.prefix, style: shown),
              ..._columns(shown, scaler, elapsed),
              if (widget.suffix.isNotEmpty) Text(widget.suffix, style: shown),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _columns(TextStyle style, TextScaler scaler, double elapsedMs) {
    final from = widget.format(_from);
    final to = widget.format(widget.value);
    final up = switch (widget.direction) {
      RollDirection.byChange => widget.value >= _from,
      RollDirection.up => true,
      RollDirection.down => false,
    };
    final slot = widget.roll == RollStyle.slot;
    final stagger = widget.stagger.inMilliseconds;
    final count = from.length > to.length ? from.length : to.length;
    final result = <Widget>[];
    for (var i = count - 1; i >= 0; i--) {
      final a = i < from.length ? from[from.length - 1 - i] : null;
      final b = i < to.length ? to[to.length - 1 - i] : null;
      // Odometer/drum: wheel i starts i staggers late. Slot: all start together,
      // the wheel j places from the left stops j staggers later.
      final delay = slot ? 0 : stagger * i;
      final span = widget.duration.inMilliseconds + (slot ? stagger * (count - 1 - i) : 0);
      final local = ((elapsedMs - delay) / span).clamp(0.0, 1.0);
      final p = widget.curve.transform(local);
      if (a == b && !_isDigit(a)) {
        result.add(_cell(style, _width(b, style, scaler), [_glyph(b, style, 0)]));
      } else if (_isDigit(a) && _isDigit(b)) {
        final s = int.parse(a!);
        final e = int.parse(b!);
        final steps = (up ? (e - s) % 10 : -((s - e) % 10)) + (slot ? (up ? 10 : -10) : 0);
        final x = s + steps * p;
        final floor = x.floor();
        result.add(
          _cell(style, _digitWidth, [
            for (var k = floor - 1; k <= floor + 2; k++)
              if ((k - x).abs() < 1) _glyph('${k % 10}', style, k - x),
          ]),
        );
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

  /// A glyph [offset] cell heights away from its place (0 = in place). The
  /// drum tilts it around the horizontal axis (50 degrees per cell height).
  Widget _glyph(String? glyph, TextStyle style, double offset) {
    if (glyph == null) return const SizedBox.shrink();
    Widget child = Center(child: Text(glyph, style: style, maxLines: 1, softWrap: false));
    var top = offset * _height;
    if (widget.roll == RollStyle.drum && offset != 0) {
      final angle = offset * _drumAngle;
      top = _height / math.sin(_drumAngle) * math.sin(angle);
      child = Opacity(
        opacity: math.cos(angle).clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.9 / _height)
            ..rotateX(angle),
          child: child,
        ),
      );
    }
    return Positioned(left: 0, right: 0, top: top, height: _height, child: child);
  }
}

/// Angle between two neighbouring digits on the drum.
const _drumAngle = 50 * math.pi / 180;

bool _isDigit(String? c) => c != null && c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

String _plain(int number) => number.toString();
