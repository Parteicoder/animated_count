import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'animated_count.dart';

/// One step of a [TieredCount]: from the number [at] upwards the badge shows
/// [label] on a [color] background.
class CountTier {
  /// Creates a tier. [textColor] is the color of the [label].
  const CountTier({required this.at, required this.label, required this.color, this.textColor = const Color(0xFFFFFFFF)});

  /// The first number that reaches this tier.
  final int at;

  /// The text of the badge, e.g. `'Gold'`.
  final String label;

  /// The background of the badge.
  final Color color;

  /// The color of [label].
  final Color textColor;

  /// The highest tier in [tiers] that [value] has reached, or null below the first one.
  /// [tiers] needs no particular order.
  static CountTier? forValue(int value, List<CountTier> tiers) {
    CountTier? found;
    for (final tier in tiers) {
      if (tier.at <= value && (found == null || tier.at > found.at)) found = tier;
    }
    return found;
  }

  @override
  bool operator ==(Object other) =>
      other is CountTier && other.at == at && other.label == label && other.color == color && other.textColor == textColor;

  @override
  int get hashCode => Object.hash(at, label, color, textColor);

  /// Bronze to diamond at 10, 25, 50, 100, 250, 500 and 1000.
  static const medals = <CountTier>[
    CountTier(at: 10, label: 'Bronze', color: Color(0xFF9C5A1F)),
    CountTier(at: 25, label: 'Silver', color: Color(0xFF9AA3AD), textColor: Color(0xFF2B3138)),
    CountTier(at: 50, label: 'Gold', color: Color(0xFFE0A712), textColor: Color(0xFF4A3300)),
    CountTier(at: 100, label: 'Ruby', color: Color(0xFFE5005A)),
    CountTier(at: 250, label: 'Sapphire', color: Color(0xFF2F6FE0)),
    CountTier(at: 500, label: 'Amethyst', color: Color(0xFF8F4BE0)),
    CountTier(at: 1000, label: 'Diamond', color: Color(0xFF19B6DD), textColor: Color(0xFF04323F)),
  ];
}

/// An [AnimatedCount] with a badge for the tier the number has reached, for
/// example Bronze at 10 and Gold at 50 ([CountTier.medals]).
///
/// The badge changes when the count has finished, not while the number is still
/// on its way, so counting from 40 to 1000 does not show "Diamond" right away.
/// [onTierChange] is called then too, a good place for a celebration. Below the
/// first tier there is no badge. Screen readers get the final text and the
/// tier shown at that moment in one piece (the new tier follows when the count ends).
///
/// ```dart
/// TieredCount(
///   value: posterCount,
///   suffix: ' posters',
///   onTierChange: (from, to) { if (to != null) celebrate(to.label); },
/// )
/// ```
class TieredCount extends StatefulWidget {
  /// Creates a counting number with a tier badge.
  ///
  /// [value], [prefix], [suffix], [style], [textAlign], [countFromZero], [initialValue],
  /// [duration], [curve], [format] and [onEnd] work like on [AnimatedCount].
  const TieredCount({
    required this.value,
    this.tiers = CountTier.medals,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.countFromZero = false,
    this.initialValue,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.format = _plain,
    this.onEnd,
    this.onTierChange,
    super.key,
  });

  /// The number to show.
  final int value;

  /// The steps of the badge, [CountTier.medals] by default. Keep the list the same
  /// while the widget lives; a different list is only used from the next count on.
  final List<CountTier> tiers;

  /// Text before the number.
  final String prefix;

  /// Text after the number.
  final String suffix;

  /// The text style of the number. The badge is a bit smaller.
  final TextStyle? style;

  /// Count up from 0 when the widget first appears.
  final bool countFromZero;

  /// The number the very first count starts from.
  final int? initialValue;

  /// How long one count takes.
  final Duration duration;

  /// The easing of the count.
  final Curve curve;

  /// Turns the number into text, e.g. to add thousands separators. Defaults to `int.toString`.
  final String Function(int number) format;

  /// Called when a count has finished, see [AnimatedCount.onEnd].
  final VoidCallback? onEnd;

  /// Called when the badge changes after a count: [from] is the old tier and [to] the new
  /// one, either may be null (below the first tier). Not called when the tier stays the same.
  final void Function(CountTier? from, CountTier? to)? onTierChange;

  @override
  State<TieredCount> createState() => _TieredCountState();
}

String _plain(int number) => number.toString();

class _TieredCountState extends State<TieredCount> {
  late CountTier? _tier = CountTier.forValue(widget.initialValue ?? (widget.countFromZero ? 0 : widget.value), widget.tiers);

  void _ended() {
    if (!mounted) return;
    final next = CountTier.forValue(widget.value, widget.tiers);
    if (next != _tier) {
      final old = _tier;
      setState(() => _tier = next);
      widget.onTierChange?.call(old, next);
    }
    widget.onEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final count = AnimatedCount(
      value: widget.value,
      prefix: widget.prefix,
      suffix: widget.suffix,
      style: widget.style,
      countFromZero: widget.countFromZero,
      initialValue: widget.initialValue,
      duration: widget.duration,
      curve: widget.curve,
      format: widget.format,
      onEnd: _ended,
    );
    final tier = _tier;
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    return Semantics(
      label: tier == null ? count.text : '${count.text}, ${tier.label}',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          count,
          if (tier != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: tier.color, borderRadius: BorderRadius.circular(999)),
              child: Text(
                tier.label,
                style: TextStyle(color: tier.textColor, fontSize: math.max((base.fontSize ?? 14) * 0.55, 11), fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
