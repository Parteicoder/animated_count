import 'package:animated_count/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool disableAnimations = false, double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations, textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

String _dots(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

String _euro(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} EUR';

void main() {
  rollingTests();
  testWidgets('shows the initial value immediately', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 12, suffix: ' items')));
    expect(find.text('12 items'), findsOneWidget);
  });

  testWidgets('counts down without leaving stale digits behind', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 12)));
    await tester.pumpWidget(_app(const AnimatedCount(value: 1)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('12'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('counts up and ends exactly on the new value', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 1)));
    await tester.pumpWidget(_app(const AnimatedCount(value: 1000)));
    await tester.pumpAndSettle();
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('countFromZero starts at 0 and ends at the target', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 30, countFromZero: true)));
    expect(find.text('0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('initialValue starts the first count from the remembered number', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 30, initialValue: 20)));
    expect(find.text('20'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('20'), findsNothing);
    expect(find.text('30'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('initialValue also counts down from a higher remembered number', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 5, initialValue: 50)));
    expect(find.text('50'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('initialValue equal to value does not animate', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 42, initialValue: 42)));
    expect(find.text('42'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('initialValue wins over countFromZero', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 30, initialValue: 25, countFromZero: true)));
    expect(find.text('25'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('format is applied to the shown number', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 1234567, format: _dots)));
    expect(find.text('1.234.567'), findsOneWidget);
  });

  testWidgets('jumps straight to the target when system animations are off', (tester) async {
    await tester.pumpWidget(_app(const AnimatedCount(value: 5, countFromZero: true), disableAnimations: true));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('screen readers get the final value in one piece', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const AnimatedCount(value: 2, suffix: ' items', countFromZero: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('2 items'), findsOneWidget);
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('wraps instead of overflowing at 200 % text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 200,
          child: AnimatedCount(value: 1234, prefix: 'Total: ', suffix: ' posters hung', style: TextStyle(fontSize: 34)),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('AnimatedDecimal', () {
    testWidgets('shows the value immediately with two decimals by default', (tester) async {
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 12.5)));
      expect(find.text('12.50'), findsOneWidget);
    });

    testWidgets('fractionDigits controls the default formatting', (tester) async {
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 3.14159, fractionDigits: 3)));
      expect(find.text('3.142'), findsOneWidget);
    });

    testWidgets('counts to a new value and ends exactly on it', (tester) async {
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 1.5)));
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 99.99)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1.50'), findsNothing);
      expect(find.text('99.99'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('99.99'), findsOneWidget);
    });

    testWidgets('a currency format is applied to every shown number', (tester) async {
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 1234.5, format: _euro, prefix: 'Total: ')));
      expect(find.text('Total: 1234,50 EUR'), findsOneWidget);
    });

    testWidgets('initialValue and countFromZero start the first count', (tester) async {
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 10, initialValue: 7.5)));
      expect(find.text('7.50'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const SizedBox())); // a fresh first appearance
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 10, countFromZero: true)));
      expect(find.text('0.00'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('10.00'), findsOneWidget);
    });

    testWidgets('screen readers get the formatted final value', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 5, format: _euro, countFromZero: true)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('5,00 EUR'), findsOneWidget);
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  });

  group('duration and curve', () {
    testWidgets('a custom duration is respected', (tester) async {
      await tester.pumpWidget(_app(const AnimatedCount(value: 0, duration: Duration(seconds: 2), curve: Curves.linear)));
      await tester.pumpWidget(_app(const AnimatedCount(value: 100, duration: Duration(seconds: 2), curve: Curves.linear)));
      await tester.pump(); // start the animation
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('50'), findsOneWidget); // halfway after half the time, linear
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('a custom curve shapes the count', (tester) async {
      // easeIn is slower than linear at the start: at half the time it is below 50.
      await tester.pumpWidget(_app(const AnimatedCount(value: 0, duration: Duration(seconds: 2), curve: Curves.easeIn)));
      await tester.pumpWidget(_app(const AnimatedCount(value: 100, duration: Duration(seconds: 2), curve: Curves.easeIn)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final shown = int.parse((tester.widget<Text>(find.byType(Text))).data!);
      expect(shown, lessThan(50));
      await tester.pumpAndSettle();
    });

    testWidgets('AnimatedDecimal takes duration and curve too', (tester) async {
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 0, duration: Duration(seconds: 2), curve: Curves.linear)));
      await tester.pumpWidget(_app(const AnimatedDecimal(value: 10, duration: Duration(seconds: 2), curve: Curves.linear)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('5.00'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}

void rollingTests() {
  group('RollingCount', () {
    testWidgets('shows the initial value and its label immediately', (tester) async {
      await tester.pumpWidget(_app(const RollingCount(value: 12, suffix: ' items')));
      expect(find.bySemanticsLabel('12 items'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('rolls up, ends exactly on the new value and leaves no extra wheel digits', (tester) async {
      await tester.pumpWidget(_app(const RollingCount(value: 12)));
      await tester.pumpWidget(_app(const RollingCount(value: 142)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('3'), findsWidgets); // rolling through the digits in between
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('142'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(3));
    });

    testWidgets('rolls down and drops the vanished digits (142 to 7)', (tester) async {
      await tester.pumpWidget(_app(const RollingCount(value: 142)));
      await tester.pumpWidget(_app(const RollingCount(value: 7)));
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('keeps thousands separators as plain text', (tester) async {
      await tester.pumpWidget(_app(RollingCount(value: 999, format: _dots)));
      await tester.pumpWidget(_app(RollingCount(value: 1000, format: _dots)));
      await tester.pumpAndSettle();
      expect(find.text('.'), findsOneWidget);
      expect(find.bySemanticsLabel('1.000'), findsOneWidget);
    });

    testWidgets('countFromZero starts at 0, initialValue wins', (tester) async {
      await tester.pumpWidget(_app(const RollingCount(value: 30, countFromZero: true)));
      expect(find.text('0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      await tester.pumpWidget(_app(const RollingCount(value: 5, countFromZero: true, initialValue: 5, key: ValueKey('b'))));
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });


    for (final roll in RollStyle.values) {
      testWidgets('${roll.name} ends exactly on the new value', (tester) async {
        await tester.pumpWidget(_app(RollingCount(value: 12, roll: roll)));
        await tester.pumpWidget(_app(RollingCount(value: 1042, roll: roll)));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(Text), findsWidgets);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('1042'), findsOneWidget);
        expect(find.byType(Text), findsNWidgets(4));
        await tester.pumpWidget(_app(RollingCount(value: 7, roll: roll)));
        await tester.pumpAndSettle();
        expect(find.byType(Text), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      });
    }

    testWidgets('direction forces the way the wheel turns', (tester) async {
      Future<void> run(RollDirection d) async {
        await tester.pumpWidget(_app(RollingCount(value: 1, direction: d, curve: Curves.linear)));
        await tester.pumpWidget(_app(RollingCount(value: 2, direction: d, curve: Curves.linear)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }

      await run(RollDirection.down); // 1 -> 2 down = 9 steps through 0, 9 ... 3
      expect(find.text('6'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      await tester.pumpWidget(_app(const SizedBox()));
      await run(RollDirection.up); // 1 -> 2 up = 1 step
      expect(find.text('6'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('upColor and downColor tint the text while rolling and restore it', (tester) async {
      const base = Color(0xFF000000);
      Color? color() => tester.widget<Text>(find.byType(Text).first).style?.color;
      await tester.pumpWidget(_app(const RollingCount(value: 5, style: TextStyle(color: base), upColor: Color(0xFF00FF00), downColor: Color(0xFFFF0000))));
      await tester.pumpWidget(_app(const RollingCount(value: 6, style: TextStyle(color: base), upColor: Color(0xFF00FF00), downColor: Color(0xFFFF0000))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(color(), isNot(base));
      expect(color()!.g, greaterThan(color()!.r)); // green, not red
      await tester.pumpAndSettle();
      expect(color(), base);
    });

    testWidgets('a change in the middle of a roll continues from the shown number', (tester) async {
      Widget count(int v) => _app(RollingCount(value: v, curve: Curves.linear));
      await tester.pumpWidget(count(10));
      await tester.pumpWidget(count(90));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // about 50 shown
      await tester.pumpWidget(count(95));
      await tester.pump();
      expect(find.text('9'), findsNothing); // no snap to the old target 90
      expect(find.text('5'), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('95'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('jumps instantly when animations are disabled', (tester) async {
      await tester.pumpWidget(_app(const RollingCount(value: 1), disableAnimations: true));
      await tester.pumpWidget(_app(const RollingCount(value: 9), disableAnimations: true));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
