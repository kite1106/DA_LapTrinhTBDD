import 'package:flutter/material.dart';

import '../models/detection_result.dart';

class DetectionPainter extends CustomPainter {
  final DetectionResult result;
  final Size displaySize;

  DetectionPainter({
    required this.result,
    required this.displaySize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = displaySize.width / result.originalImageSize.width;
    final sy = displaySize.height / result.originalImageSize.height;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.lightBlueAccent;

    for (final det in result.detections) {
      final rect = Rect.fromLTRB(
        det.rect.left * sx,
        det.rect.top * sy,
        det.rect.right * sx,
        det.rect.bottom * sy,
      );

      canvas.drawRect(rect, paint);

      final label = det.label ?? 'Class #${det.classIndex}';
      final text = '$label ${(det.score).toStringAsFixed(2)}';

      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: displaySize.width);

      final bg = Paint()..color = Colors.lightBlueAccent.withOpacity(0.9);
      final pad = 4.0;
      final bgRect = Rect.fromLTWH(
        rect.left,
        (rect.top - tp.height - pad * 2).clamp(0.0, displaySize.height),
        tp.width + pad * 2,
        tp.height + pad * 2,
      );
      canvas.drawRect(bgRect, bg);
      tp.paint(canvas, Offset(bgRect.left + pad, bgRect.top + pad));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.result != result || oldDelegate.displaySize != displaySize;
  }
}
