# animated_count

A tiny Flutter widget that counts an integer up or down to its new value.

It renders **one plain `Text`**, so font scaling, line wrapping, baseline alignment and
screen readers behave like for any other text. No custom painting, no extra dependencies.

```dart
AnimatedCount(
  value: posterCount,
  suffix: posterCount == 1 ? ' poster' : ' posters',
  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
)
```

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

## Why not a rolling-digits widget?

Rolling digits look nice, but they need custom layout and painting. That makes it hard to
get text scaling, wrapping and accessibility right. A count-up is a few lines of
`TweenAnimationBuilder` and keeps all of that for free.

## License

MIT
