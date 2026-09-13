import 'package:flutter/material.dart';
import '../../../data/models/tracking_frame.dart';

class PosePainter extends CustomPainter {
  final TrackingFrame? currentFrame;

  PosePainter({required this.currentFrame});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentFrame == null) return;

    final headX = currentFrame!.headX * size.width;
    final headY = currentFrame!.headY * size.height;

    // 1. Draw Player Indicator Arrow
    final arrowPaint = Paint()
      :color = Colors.red
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    const arrowWidth = 24.0;
    const arrowHeight = 24.0;
    const offsetAboveHead = 60.0;

    final tipX = headX;
    final tipY = (headY - offsetAboveHead).clamp(0.0, size.height);

    path.moveTo(tipX, tipY);
    path.lineTo(tipX - arrowWidth / 2, tipY - arrowHeight);
    path.lineTo(tipX + arrowWidth / 2, tipY - arrowHeight);
    path.close();

    canvas.drawPath(path, arrowPaint);
    canvas.drawPath(path, borderPaint);

    // 2. Draw "PLAYER" Text Label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'PLAYER',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(headX, tipY - arrowHeight - 16),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(labelRect, labelBgPaint);

    textPainter.paint(
      canvas,
      Offset(headX - textPainter.width / 2, tipY - arrowHeight - 20),
    );

    // 3. Draw Biomechanical Angle Badges (Elbow & Knee)
    final statsPainter = TextPainter(
      text: TextSpan(
        text: 'Elbow: ${currentFrame!.elbowAngle}°  |  Knee Squat: ${currentFrame!.kneeAngle}°',
        style: const TextStyle(color: Colors.yellowAccent, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    statsPainter.layout();

    final statsBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final statsRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, 28),
        width: statsPainter.width + 24,
        height: statsPainter.height + 12,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(statsRect, statsBgPaint);

    statsPainter.paint(
      canvas,
      Offset(size.width / 2 - statsPainter.width / 2, 22),
    );
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.currentFrame != currentFrame;
  }
}
