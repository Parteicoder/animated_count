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

void main() {
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
}
