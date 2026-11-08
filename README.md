# animated_count

![Counting up and down on button taps](https://raw.githubusercontent.com/Parteicoder/animated_count/main/doc/demo.gif)

Tiny Flutter widgets that count a number up or down to its new value: `AnimatedCount` for integers, `AnimatedDecimal` for decimals and currencies.

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

### Thousands separators

```dart
AnimatedCount(
  value: 1234567,
  format: (n) => NumberFormat.decimalPattern('en_US').format(n), // package:intl
)
```

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

## Why not a rolling-digits widget?

Rolling digits look nice, but they need custom layout and painting. That makes it hard to
get text scaling, wrapping and accessibility right. A count-up is a few lines of
`TweenAnimationBuilder` and keeps all of that for free.

## License

MIT
