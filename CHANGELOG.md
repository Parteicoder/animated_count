## 0.4.0

- Add `onEnd` to `AnimatedCount`, `AnimatedDecimal` and `RollingCount`: a callback that runs when a count or roll has finished. If the value changes in the middle, only the last one calls it. It is not called when nothing is animated.

## 0.3.1

- `RollingCount`: a new value in the middle of a roll now continues from roughly the number on display instead of snapping back to the previous target.
- README: how to find a `RollingCount` in widget tests.

## 0.3.0

- Add `RollingCount`: odometer-style digit wheels that roll through the digits in between, with a staggered start and a small bounce. `AnimatedCount` and `AnimatedDecimal` are unchanged.
- `roll` picks the look: `RollStyle.odometer` (default), `drum` (3D cylinder) or `slot` (extra spin, stops from the left). `direction`, `stagger`, `upColor` and `downColor` fine-tune it.
- The README demo GIF shows the rolling digits.

## 0.2.1

- Add a demo GIF to the README and the pub.dev screenshots tab.

## 0.2.0

- Add `AnimatedDecimal` for `double` values (prices, averages, percentages) with `fractionDigits` and a custom `format`, for example a currency.
- `duration` and `curve` work on both widgets (tested).

## 0.1.3

- Add `initialValue`: the first count starts from a number you remembered (for example the last number shown, kept in `shared_preferences`), so a re-opened screen does not count up from 0 again.

## 0.1.2

- Document the whole public API.
- Add an example app.

## 0.1.1

- Releases are now published automatically from GitHub Actions. No code changes.

## 0.1.0

- Initial release: `AnimatedCount` counts an integer up or down to its new value.
