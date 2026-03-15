import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 図形表示ウィジェット
class ShapeFigure extends StatelessWidget {
  final String shapeName;
  const ShapeFigure({super.key, required this.shapeName});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(160, 160),
      painter: _ShapePainter(shapeName: shapeName));
}

class _ShapePainter extends CustomPainter {
  final String shapeName;
  const _ShapePainter({required this.shapeName});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.lightBlue.shade200
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 12;

    switch (shapeName) {
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawCircle(Offset(cx, cy), r, line);
      case 'square':
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.8, height: r * 1.8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), line);
      case 'rectangle':
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 2.1, height: r * 1.2);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), line);
      case 'triangle':
        final p = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r * 0.8)
          ..lineTo(cx - r, cy + r * 0.8)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawPath(p, line);
      default:
        final sides = switch (shapeName) {
          'pentagon' => 5,
          'hexagon'  => 6,
          _          => 4,
        };
        final p = Path();
        for (int i = 0; i < sides; i++) {
          final a = (i * 360 / sides - 90) * math.pi / 180;
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        p.close();
        canvas.drawPath(p, fill);
        canvas.drawPath(p, line);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter o) => o.shapeName != shapeName;
}
