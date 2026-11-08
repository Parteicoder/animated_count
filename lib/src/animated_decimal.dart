import 'package:flutter/widgets.dart';

import 'counting_text.dart';

/// A decimal number (prices, averages, percentages) that counts up or down
/// whenever [value] changes.
///
/// Works like `AnimatedCount`, but for a [double]. The number of decimals comes
/// from [fractionDigits]; for anything else, such as a currency, pass [format].
/// The package has no dependencies, so use `package:intl` (or your own code) in
/// [format] for locale aware output:
///
/// ```dart
/// AnimatedDecimal(
///   value: total,
///   format: (v) => NumberFormat.currency(locale: 'en_US', symbol: r'$').format(v),
/// )
/// ```
///
/// It renders a single plain [Text]. Screen readers get the final text, never
/// the in-between numbers. If the system disables animations, the number jumps
/// to its target.
class AnimatedDecimal extends StatelessWidget {
  /// Creates a counting decimal number.
  ///
  /// [value] is the number to show, shown with [fractionDigits] decimals unless
  /// [format] says otherwise. [initialValue] or [countFromZero] animate the very
  /// first appearance. [duration] and [curve] shape every count.
  const AnimatedDecimal({
    required this.value,
    this.fractionDigits = 2,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.textAlign,
    this.countFromZero = false,
    this.initialValue,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.format,
    super.key,
  });

  /// The number to show.
  final double value;

  /// Decimals of the default formatting (`toStringAsFixed`). Ignored when
  /// [format] is set.
  final int fractionDigits;

  /// Text before the number, e.g. `'Total: '`.
  final String prefix;

  /// Text after the number, e.g. `' EUR'`.
  final String suffix;

  /// The text style of the whole text. Falls back to the ambient
  /// [DefaultTextStyle] when null.
  final TextStyle? style;

  /// How the text is aligned horizontally. Null means the default of [Text].
  final TextAlign? textAlign;

  /// Count up from 0 when the widget first appears. Ignored when
  /// [initialValue] is set.
  final bool countFromZero;

  /// The number the very first count starts from, usually the number this
  /// widget showed last time (kept by you). If it equals [value], nothing is
  /// animated.
  final double? initialValue;

  /// How long one count takes. Ignored (jumps instantly) if the system
  /// disables animations.
  final Duration duration;

  /// The easing of the count. Defaults to [Curves.easeOutCubic].
  final Curve curve;

  /// Turns the (intermediate) number into text, e.g. as a currency. Defaults to
  /// `toStringAsFixed(fractionDigits)`.
  final String Function(double number)? format;

  String _format(double number) => (format ?? (n) => n.toStringAsFixed(fractionDigits))(number);

  /// The full text in its final state, e.g. what a screen reader announces.
  String get text => '$prefix${_format(value)}$suffix';

  @override
  Widget build(BuildContext context) => countingText(
    context,
    from: initialValue ?? (countFromZero ? 0 : value),
    to: value,
    duration: duration,
    curve: curve,
    text: (current) => '$prefix${_format(current)}$suffix',
    label: text,
    style: style,
    textAlign: textAlign,
  );
}
