import 'package:flutter/widgets.dart';

class DetectionCandidate {
  final Rect rect;
  final int classIndex;
  final String? label;
  final double score;

  DetectionCandidate({
    required this.rect,
    required this.classIndex,
    required this.label,
    required this.score,
  });
}

class DetectionResult {
  final List<DetectionCandidate> detections;
  final Size originalImageSize;

  DetectionResult({
    required this.detections,
    required this.originalImageSize,
  });
}
