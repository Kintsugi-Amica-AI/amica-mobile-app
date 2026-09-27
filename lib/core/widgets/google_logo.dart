import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Google's four-colour "G", drawn in code (no image asset needed) for the
/// "Continue with Google" button, as Google's sign-in branding asks.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final center = Offset(size.width / 2, size.height / 2);
    final r = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    double rad(double deg) => deg * math.pi / 180;

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Angles run clockwise from 3 o'clock; the G's mouth opens at the
    // upper right.
    canvas.drawArc(rect, rad(-145), rad(110), false, arc(_red));
    canvas.drawArc(rect, rad(145), rad(71), false, arc(_yellow));
    canvas.drawArc(rect, rad(35), rad(111), false, arc(_green));
    canvas.drawArc(rect, rad(-1), rad(37), false, arc(_blue));
    // The crossbar.
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx - stroke * 0.05,
        center.dy - stroke / 2,
        center.dx + r + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
