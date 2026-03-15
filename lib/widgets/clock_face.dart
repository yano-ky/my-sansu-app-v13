import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 時計の文字盤ウィジェット
class ClockFace extends StatelessWidget {
  final int hour, minute;
  const ClockFace({super.key, required this.hour, required this.minute});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(200, 200),
      painter: _ClockPainter(hour: hour, minute: minute));
}

class _ClockPainter extends CustomPainter {
  final int hour, minute;
  const _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // 背景
    canvas.drawCircle(c, r, Paint()..color = Colors.yellow.shade50);
    canvas.drawCircle(c, r,
        Paint()
          ..color = Colors.orange.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);

    // 目盛り
    for (int i = 0; i < 60; i++) {
      final a   = i * 6 * math.pi / 180;
      final len = i % 5 == 0 ? 10.0 : 5.0;
      final w   = i % 5 == 0 ? 2.5  : 1.0;
      canvas.drawLine(
        Offset(c.dx + (r - len) * math.cos(a), c.dy + (r - len) * math.sin(a)),
        Offset(c.dx + r         * math.cos(a), c.dy + r         * math.sin(a)),
        Paint()..color = Colors.orange.shade400..strokeWidth = w,
      );
    }

    // 数字
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      final a = (i * 30 - 90) * math.pi / 180;
      final p = Offset(c.dx + (r - 22) * math.cos(a),
                       c.dy + (r - 22) * math.sin(a));
      tp.text = TextSpan(
          text: '$i',
          style: TextStyle(
              fontSize: 15,
              color: Colors.brown.shade700,
              fontWeight: FontWeight.bold));
      tp.layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // 短針（時）
    _hand(canvas, c,
        ((hour % 12) + minute / 60.0) * 30 * math.pi / 180 - math.pi / 2,
        r * 0.48, 7, Colors.brown.shade700);
    // 長針（分）
    _hand(canvas, c,
        minute * 6 * math.pi / 180 - math.pi / 2,
        r * 0.70, 4, Colors.brown.shade500);
    // 中心
    canvas.drawCircle(c, 7, Paint()..color = Colors.orange.shade400);
    canvas.drawCircle(c, 3, Paint()..color = Colors.white);
  }

  void _hand(Canvas canvas, Offset c, double a, double len, double w, Color col) {
    canvas.drawLine(c,
        Offset(c.dx + len * math.cos(a), c.dy + len * math.sin(a)),
        Paint()..color = col..strokeWidth = w..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_ClockPainter o) => o.hour != hour || o.minute != minute;
}
