import 'package:animated_count/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('tierFor', () {
    test('returns the highest tier reached, null below the first', () {
      expect(tierFor(0, CountTier.medals), isNull);
      expect(tierFor(9, CountTier.medals), isNull);
      expect(tierFor(10, CountTier.medals)?.label, 'Bronze');
      expect(tierFor(49, CountTier.medals)?.label, 'Silver');
      expect(tierFor(50, CountTier.medals)?.label, 'Gold');
      expect(tierFor(999, CountTier.medals)?.label, 'Amethyst');
      expect(tierFor(1000, CountTier.medals)?.label, 'Diamond');
      expect(tierFor(5000, CountTier.medals)?.label, 'Diamond');
    });

    test('does not need sorted tiers', () {
      const tiers = [
        CountTier(at: 100, label: 'B', color: Color(0xFF000000)),
        CountTier(at: 5, label: 'A', color: Color(0xFF000000)),
      ];
      expect(tierFor(7, tiers)?.label, 'A');
      expect(tierFor(100, tiers)?.label, 'B');
    });
  });

  group('TieredCount', () {
    testWidgets('shows the badge of the start value right away', (tester) async {
      await tester.pumpWidget(_app(const TieredCount(value: 60)));
      expect(find.text('60'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('has no badge below the first tier', (tester) async {
      await tester.pumpWidget(_app(const TieredCount(value: 3)));
      expect(find.text('3'), findsOneWidget);
      for (final tier in CountTier.medals) {
        expect(find.text(tier.label), findsNothing);
      }
    });

    testWidgets('changes the badge only after the count has finished', (tester) async {
      await tester.pumpWidget(_app(const TieredCount(value: 40)));
      expect(find.text('Silver'), findsOneWidget);
      await tester.pumpWidget(_app(const TieredCount(value: 1000)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Silver'), findsOneWidget); // not Diamond while still counting
      expect(find.text('Diamond'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Diamond'), findsOneWidget);
      expect(find.text('Silver'), findsNothing);
    });

    testWidgets('onTierChange reports old and new tier once, onEnd still runs', (tester) async {
      final changes = <String>[];
      var ends = 0;
      Widget build(int v) => _app(
        TieredCount(
          value: v,
          onEnd: () => ends++,
          onTierChange: (from, to) => changes.add('${from?.label}>${to?.label}'),
        ),
      );
      await tester.pumpWidget(build(8));
      await tester.pumpWidget(build(30)); // none to Silver
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(35)); // same tier
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(5)); // Silver to none
      await tester.pumpAndSettle();
      expect(changes, ['null>Silver', 'Silver>null']);
      expect(ends, 3);
    });

    testWidgets('countFromZero starts without a badge and ends with the right one', (tester) async {
      await tester.pumpWidget(_app(const TieredCount(value: 100, countFromZero: true)));
      expect(find.text('Ruby'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Ruby'), findsOneWidget);
    });

    testWidgets('screen readers get number and tier in one piece', (tester) async {
      await tester.pumpWidget(_app(const TieredCount(value: 50, suffix: ' posters')));
      expect(find.bySemanticsLabel('50 posters, Gold'), findsOneWidget);
    });

    testWidgets('custom tiers replace the medals', (tester) async {
      const tiers = [CountTier(at: 5, label: 'Rookie', color: Color(0xFF123456))];
      await tester.pumpWidget(_app(const TieredCount(value: 7, tiers: tiers)));
      expect(find.text('Rookie'), findsOneWidget);
      expect(find.text('Bronze'), findsNothing);
    });
  });
}
