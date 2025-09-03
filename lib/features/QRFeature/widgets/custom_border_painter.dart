import 'package:flutter/material.dart';

class CornerBorderPainter extends CustomPainter {
  final Rect scanWindow;

  CornerBorderPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerLength = 30;
    const double strokeWidth = 6;
    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // top-left corner
    canvas.drawLine(
      scanWindow.topLeft,
      scanWindow.topLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      scanWindow.topLeft,
      scanWindow.topLeft + Offset(0, cornerLength),
      paint,
    );

    // top-right corner
    canvas.drawLine(
      scanWindow.topRight,
      scanWindow.topRight + Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      scanWindow.topRight,
      scanWindow.topRight + Offset(0, cornerLength),
      paint,
    );

    // bottom-left corner
    canvas.drawLine(
      scanWindow.bottomLeft,
      scanWindow.bottomLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      scanWindow.bottomLeft,
      scanWindow.bottomLeft + Offset(0, -cornerLength),
      paint,
    );

    // bottom-right corner
    canvas.drawLine(
      scanWindow.bottomRight,
      scanWindow.bottomRight + Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      scanWindow.bottomRight,
      scanWindow.bottomRight + Offset(0, -cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
