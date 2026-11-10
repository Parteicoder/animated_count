import 'package:flutter/widgets.dart';

/// Shared by [AnimatedCount] and [AnimatedDecimal]: one plain [Text] whose number
/// runs from [from] to [to], with the final text as the screen reader label.
Widget countingText(
  BuildContext context, {
  required double from,
  required double to,
  required Duration duration,
  required Curve curve,
  required String Function(double number) text,
  required String label,
  TextStyle? style,
  TextAlign? textAlign,
  VoidCallback? onEnd,
}) {
  final animate = !MediaQuery.disableAnimationsOf(context);
  return Semantics(
    label: label,
    excludeSemantics: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from, end: to),
      duration: animate ? duration : Duration.zero,
      curve: curve,
      onEnd: onEnd,
      builder: (context, current, _) => Text(text(current), style: style, textAlign: textAlign),
    ),
  );
}
