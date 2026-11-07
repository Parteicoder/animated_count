import 'package:flutter/widgets.dart';

/// An integer that counts up or down whenever [value] changes.
///
/// The first frame shows [value] immediately. Only a later change is animated,
/// or, with [countFromZero], the very first appearance (count-up from 0).
///
/// It renders a single plain [Text] (`prefix + number + suffix`), so font
/// scaling, line wrapping and baseline alignment behave as for any other text.
/// Screen readers always get the final value, never the in-between numbers.
/// If the system disables animations, the number jumps to its target.
///
/// ```dart
/// AnimatedCount(
///   value: posterCount,
///   suffix: posterCount == 1 ? ' poster' : ' posters',
///   style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
/// )
/// ```
class AnimatedCount extends StatelessWidget {
  /// Creates a counting number.
  ///
  /// [value] is the number to show. [prefix] and [suffix] are text around it that
  /// belongs to the same [Text]. Set [countFromZero] to also animate the first
  /// appearance. [format] turns every shown number into text, for example to add
  /// thousands separators.
  const AnimatedCount({
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.textAlign,
    this.countFromZero = false,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.format = _plain,
    super.key,
  });

  /// The number to show.
  final int value;

  /// Text before the number, e.g. `'Total: '`.
  final String prefix;

  /// Text after the number, e.g. `' items'`.
  final String suffix;

  /// The text style of the whole text. Falls back to the ambient
  /// [DefaultTextStyle] when null.
  final TextStyle? style;

  /// How the text is aligned horizontally. Null means the default of [Text].
  final TextAlign? textAlign;

  /// Count up from 0 when the widget first appears.
  ///
  /// When false, the first frame shows [value] right away and only later
  /// changes are animated.
  final bool countFromZero;

  /// How long one count takes. Ignored (jumps instantly) if the system
  /// disables animations.
  final Duration duration;

  /// The easing of the count. Defaults to [Curves.easeOutCubic].
  final Curve curve;

  /// Turns the (intermediate) number into text, e.g. to add thousands separators.
  /// Defaults to `int.toString`.
  final String Function(int number) format;

  /// The full text in its final state, e.g. what a screen reader announces.
  String get text => '$prefix${format(value)}$suffix';

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: countFromZero ? 0 : value.toDouble(), end: value.toDouble()),
        duration: animate ? duration : Duration.zero,
        curve: curve,
        builder: (context, current, _) =>
            Text('$prefix${format(current.round())}$suffix', style: style, textAlign: textAlign),
      ),
    );
  }
}

String _plain(int number) => number.toString();
