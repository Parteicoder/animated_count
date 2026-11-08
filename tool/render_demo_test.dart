// Renders the frames of doc/demo.gif. Run: flutter test tool/render_demo_test.dart
// then: python tool/make_gif.py   (needs Pillow). Uses Segoe UI from Windows.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:animated_count/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _frameMs = 50;
late void Function(int value, int pressed) _set;

class _Scene extends StatefulWidget {
  const _Scene();
  @override
  State<_Scene> createState() => _SceneState();
}

class _SceneState extends State<_Scene> {
  int value = 12;
  int pressed = 0; // 1 = minus, 2 = plus

  @override
  void initState() {
    super.initState();
    _set = (v, p) => setState(() {
      value = v;
      pressed = p;
    });
  }

  Widget _button(String label, bool down) => Container(
    width: 56,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: down ? const Color(0xFF00695C) : const Color(0xFF009688),
    ),
    child: Text(label, style: const TextStyle(fontSize: 30, color: Colors.white)),
  );

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF4FBFA),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedCount(
          value: value,
          suffix: value == 1 ? ' poster' : ' posters',
          countFromZero: true,
          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w600, color: Color(0xFF004D40)),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [_button('−', pressed == 1), _button('+', pressed == 2)],
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('render demo frames', (tester) async {
    final font = FontLoader('Segoe')
      ..addFont(Future.value(ByteData.sublistView(File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytesSync())));
    await font.load();
    final key = GlobalKey();
    tester.view.physicalSize = const Size(720, 400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Segoe'),
        home: RepaintBoundary(
          key: key,
          child: DefaultTextStyle(style: const TextStyle(fontFamily: 'Segoe'), child: const _Scene()),
        ),
      ),
    );
    final out = Directory('build/demo_frames')..createSync(recursive: true);
    var n = 0;
    Future<void> frames(int ms) async {
      for (var t = 0; t < ms; t += _frameMs) {
        await tester.pump(const Duration(milliseconds: _frameMs));
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${out.path}/f${(n++).toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }

    // (target, button pressed, hold ms after the 600 ms count)
    await frames(900); // 0 -> 12
    for (final (v, p) in [(142, 2), (272, 2), (265, 1)]) {
      _set(v, p);
      await frames(150);
      _set(v, 0);
      await frames(1350);
    }
  });
}
