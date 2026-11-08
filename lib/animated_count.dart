/// Tiny Flutter widgets that count a number up or down to its new value:
/// [AnimatedCount] for integers and [AnimatedDecimal] for decimals and currencies.
///
/// Both render one plain `Text`, so font scaling, line wrapping and
/// screen readers behave like for any other text. [RollingCount] is the
/// odometer variant with rolling digit wheels. See the README for details.
///
/// ```dart
/// AnimatedCount(value: 42, suffix: ' items')
/// ```
library;

export 'src/animated_count.dart';
export 'src/animated_decimal.dart';
export 'src/rolling_count.dart';
