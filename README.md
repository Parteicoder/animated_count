# animated_count

![Counting up and down on button taps](https://raw.githubusercontent.com/Parteicoder/animated_count/main/doc/demo.gif)

Tiny Flutter widgets that count a number up or down to its new value: `AnimatedCount` for integers, `AnimatedDecimal` for decimals and currencies, and `RollingCount` for odometer-style rolling digits (shown above, three looks).

It renders **one plain `Text`**, so font scaling, line wrapping, baseline alignment and
screen readers behave like for any other text. No custom painting, no extra dependencies.

```dart
AnimatedCount(
  value: posterCount,
  suffix: posterCount == 1 ? ' poster' : ' posters',
  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
)
```

## Features

- **int, double and currency**: `AnimatedCount` for integers, `AnimatedDecimal` for decimals, and a `format` callback for thousands separators, percentages or any currency.
- **Your own curve and duration**: `curve` (default `Curves.easeOutCubic`) and `duration` (default 600 ms) on both widgets.
- Remember the last shown number with `initialValue`, so a re-opened screen counts only when something changed.

A runnable demo lives in [`example/`](example).

## Behavior

- The first frame shows `value` immediately. Only later changes animate (up **and** down).
- `countFromZero: true` additionally counts up from 0 when the widget first appears.
- Screen readers always read the final text (`prefix + number + suffix`), never the in-between numbers.
- If the system disables animations, the number jumps straight to the target.
- The animation ends exactly on `value`, with no stale digits when the number gets shorter.

## Options

| Parameter | Default | Purpose |
|---|---|---|
| `value` | required | The number to show. |
| `prefix` / `suffix` | `''` | Text before / after the number, part of the same `Text`. |
| `style`, `textAlign` | `null` | Passed to the `Text`. |
| `countFromZero` | `false` | Count up from 0 on first appearance. |
| `initialValue` | `null` | Start the first count from this number (wins over `countFromZero`). |
| `duration` | 600 ms | Length of the animation. |
| `curve` | `Curves.easeOutCubic` | Easing. |
| `format` | `int.toString` | Formats every shown number, e.g. to add thousands separators. |
| `onEnd` | `null` | Called when a count has finished (see below). |

### Thousands separators

```dart
AnimatedCount(
  value: 1234567,
  format: (n) => NumberFormat.decimalPattern('en_US').format(n), // package:intl
)
```

## Do something when it is done

`onEnd` is called once the number has reached its new value, for example to show a message
or play a sound. All three widgets have it.

```dart
AnimatedCount(
  value: posterCount,
  onEnd: () => print('counted to $posterCount'),
)
```

If `value` changes while a count is running, only the last count calls `onEnd`. It is not
called when nothing is animated: on the first appearance (unless `countFromZero` or
`initialValue` is set), or when `value` did not change. With system animations off the number
jumps and `onEnd` follows at the end of the frame (`RollingCount`: after its normal duration), so
it may call `setState`.

## Decimals and currencies

```dart
AnimatedDecimal(
  value: total,                       // a double
  duration: const Duration(seconds: 1),
  curve: Curves.easeInOut,
  format: (v) => NumberFormat.currency(locale: 'en_US', symbol: r'$').format(v), // package:intl
)
```

Without `format`, the number is shown with `fractionDigits` decimals (default 2).
`prefix`, `suffix`, `style`, `textAlign`, `countFromZero` and `initialValue` work like on
`AnimatedCount`.

## Remember the last number

By default the first frame shows `value` right away. If you want the number to count
only when it actually changed since the last visit, keep the last shown number yourself
and pass it as `initialValue`:

```dart
final last = prefs.getInt('posterCount'); // null on the very first visit
prefs.setInt('posterCount', posterCount); // remember it for next time

AnimatedCount(
  value: posterCount,
  initialValue: last, // null: no animation (or 0 with countFromZero)
)
```

If `initialValue` equals `value`, nothing is animated. It is only used on the first
appearance; later changes of `value` count from the number currently shown.

## Rolling digits

`RollingCount` shows every digit as its own wheel, like an odometer. Wheels roll through the
digits in between (up when the number grows, down when it shrinks), start one after another
from the right and settle with a small bounce. New digits slide in, vanished ones slide out.

```dart
RollingCount(
  value: posterCount,
  suffix: posterCount == 1 ? ' poster' : ' posters',
  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
)
```

Three looks, set with `roll`:

| `RollStyle` | Look |
|---|---|
| `odometer` (default) | Flat wheels rolling through the digits in between, started one after another from the right. |
| `drum` | The same, but digits sit on a cylinder: they tilt away with perspective and fade towards the edge. |
| `slot` | Slot machine: every wheel spins one extra turn, all at once, then they stop one after another from the left. Use about 1 s `duration`. |

More knobs: `direction` (`byChange` by default, or always `up` / `down`), `stagger` (delay between
wheels, 40 ms), and `upColor` / `downColor` to tint the text while it rolls, for example green for
more and red for fewer.

```dart
RollingCount(
  value: score,
  roll: RollStyle.slot,
  duration: const Duration(seconds: 1),
  upColor: Colors.green,
  downColor: Colors.red,
)
```

It takes the same parameters as `AnimatedCount` (`prefix`, `suffix`, `style`, `format`,
`duration`, `curve`, `countFromZero`, `initialValue`, `onEnd`); the defaults are 700 ms and
`Curves.easeOutBack`. Separators from `format` stay plain text, screen readers read the final
text, and the number jumps if the system disables animations.

## Tiers and badges

`TieredCount` is an `AnimatedCount` with a badge for the tier the number has reached: Bronze at
10, Silver at 25, Gold at 50, Ruby at 100, Sapphire at 250, Amethyst at 500 and Diamond at 1000
(`CountTier.medals`). Below the first tier there is no badge.

```dart
TieredCount(
  value: posterCount,
  suffix: ' posters',
  onTierChange: (from, to) {
    if (to != null) showCongrats(to.label); // your own celebration
  },
)
```

The badge changes when the count has finished, not while the number is on its way, so counting
from 40 to 1000 does not show "Diamond" right away. `onTierChange` is called at that moment, and
only when the tier really changes. Screen readers read the number and the tier in one piece
(`50 posters, Gold`); during a count the tier is still the old one.

Your own steps replace the medals:

```dart
TieredCount(
  value: km,
  tiers: const [
    CountTier(at: 100, label: 'Walker', color: Color(0xFF2E7D32)),
    CountTier(at: 1000, label: 'Hiker', color: Color(0xFF1565C0)),
  ],
)
```

`CountTier.forValue(value, tiers)` gives the tier for a number if you want it without the widget. It takes
the same parameters as `AnimatedCount` (except `textAlign`), plus `tiers` and `onTierChange`.

## Testing

`RollingCount` puts every digit in its own `Text`, so `find.text('142 posters')` finds nothing.
Find it by its final text instead:

```dart
Finder count(String text) =>
    find.byWidgetPredicate((w) => w is RollingCount && w.text == text);

expect(count('142 posters'), findsOneWidget);
```

or use `find.bySemanticsLabel('142 posters')` (needs `tester.ensureSemantics()`).

## Which one?

Rolling digits need a custom layout (one fixed-width cell per digit), so `RollingCount` is not a
single `Text`: it does not wrap and ignores `textAlign`. Prefer `AnimatedCount` or
`AnimatedDecimal` when the number sits inside running text, or when you need decimals.

## License

MIT
