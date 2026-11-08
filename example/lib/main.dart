import 'package:animated_count/animated_count.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Shows a [RollingCount] and an [AnimatedCount] side by side that go to a new number on every tap.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: const _Home(),
  );
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _posters = 12;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('animated_count')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 24,
        children: [
          RollingCount(
            value: _posters,
            suffix: _posters == 1 ? ' poster' : ' posters',
            countFromZero: true,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          AnimatedCount(
            value: _posters,
            suffix: _posters == 1 ? ' poster' : ' posters',
            countFromZero: true,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    ),
    floatingActionButton: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        FloatingActionButton(
          onPressed: () => setState(() => _posters = _posters > 0 ? _posters - 7 : 0),
          child: const Icon(Icons.remove),
        ),
        FloatingActionButton(
          onPressed: () => setState(() => _posters += 130),
          child: const Icon(Icons.add),
        ),
      ],
    ),
  );
}
