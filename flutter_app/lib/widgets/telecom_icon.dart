import 'package:flutter/material.dart';

class TelecomIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const TelecomIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TelecomPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _TelecomPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _TelecomPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer arc: d="M4.93 4.93a10 10 0 0 1 14.14 0"
    final outerRect = Rect.fromCircle(
      center: Offset(12.0 * scale, 12.0 * scale),
      radius: 10.0 * scale,
    );
    canvas.drawArc(
      outerRect,
      -3.14159 * 0.75, // from top-left
      3.14159 * 0.5,   // 90 deg sweep
      false,
      strokePaint,
    );

    // Inner arc: d="M7.76 7.76a6 6 0 0 1 8.48 0"
    final innerRect = Rect.fromCircle(
      center: Offset(12.0 * scale, 12.0 * scale),
      radius: 6.0 * scale,
    );
    canvas.drawArc(
      innerRect,
      -3.14159 * 0.75,
      3.14159 * 0.5,
      false,
      strokePaint,
    );

    // Center beacon: cx="12" cy="12" r="2"
    canvas.drawCircle(
      Offset(12.0 * scale, 12.0 * scale),
      2.0 * scale,
      fillPaint,
    );

    // Mast: d="M12 14v8"
    canvas.drawLine(
      Offset(12.0 * scale, 14.0 * scale),
      Offset(12.0 * scale, 21.0 * scale),
      strokePaint,
    );

    // Base: d="M9 22h6"
    canvas.drawLine(
      Offset(9.0 * scale, 21.0 * scale),
      Offset(15.0 * scale, 21.0 * scale),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TelecomPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
