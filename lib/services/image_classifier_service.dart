import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/classification_result.dart';
import '../models/detection_result.dart';

enum _BoxFormat {
  xywhCenter,
  xyxy,
}

class _DetVariant {
  final bool hasObjectness;
  final _BoxFormat boxFormat;
  final List<DetectionCandidate> det;

  _DetVariant({
    required this.hasObjectness,
    required this.boxFormat,
    required this.det,
  });
}

class _LetterboxResult {
  final img.Image image;
  final double scale;
  final double padX;
  final double padY;

  _LetterboxResult({
    required this.image,
    required this.scale,
    required this.padX,
    required this.padY,
  });
}

class _InputVariant {
  final double scaleDiv;

  const _InputVariant({
    required this.scaleDiv,
  });
}

class _DetDecodePick {
  final double scaleDiv;
  final List<DetectionCandidate> det;

  _DetDecodePick({
    required this.scaleDiv,
    required this.det,
  });
}

class ImageClassifierService {
  final String modelAssetPath;

  void _log(String msg) {
    developer.log(msg, name: 'ImageClassifierService');
    // print() shows up under I/flutter in adb logcat, which is easier to filter on Windows.
    // (No-op in release mode in practice for most debugging sessions.)
    // ignore: avoid_print
    print('ImageClassifierService: $msg');
  }

  static const List<String> defaultBirdLabels = <String>[
    'Accipiter',
    'Arenaria',
    'Calidris',
    'Calliope',
    'Centropus',
    'Circus',
    'Elanus',
    'Falco',
    'Halcyon',
    'Hydrophasianus',
    'Leiothrix',
  ];

  Interpreter? _interpreter;
  List<int>? _inputShape;
  List<int>? _outputShape;
  TensorType? _inputType;
  TensorType? _outputType;
  double? _outputQuantScale;
  int? _outputQuantZeroPoint;

  ImageClassifierService({
    required this.modelAssetPath,
  });

  bool get isLoaded => _interpreter != null;

  Future<void> load() async {
    if (_interpreter != null) return;

    final interpreter = await Interpreter.fromAsset(modelAssetPath);
    final inputTensor = interpreter.getInputTensors().first;
    final outputTensor = interpreter.getOutputTensors().first;

    _interpreter = interpreter;
    _inputShape = inputTensor.shape;
    _outputShape = outputTensor.shape;

    _inputType = inputTensor.type;
    _outputType = outputTensor.type;
    // For float outputs, scale/zeroPoint are typically unused.
    _outputQuantScale = outputTensor.params.scale;
    _outputQuantZeroPoint = outputTensor.params.zeroPoint;

    _log(
      'Loaded model=$modelAssetPath inputType=${_inputType} outputType=${_outputType} outputQuant(scale=${_outputQuantScale}, zp=${_outputQuantZeroPoint})',
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _inputShape = null;
    _outputShape = null;
  }

  Future<DetectionResult> detectImageBytes(
    Uint8List imageBytes, {
    List<String>? labels,
    double scoreThreshold = 0.25,
    double iouThreshold = 0.45,
    int maxDetections = 20,
  }) async {
    await load();

    final interpreter = _interpreter;
    final inputShape = _inputShape;
    final outputShape = _outputShape;
    final inputType = _inputType;
    final outputType = _outputType;

    if (interpreter == null || inputShape == null || outputShape == null || inputType == null || outputType == null) {
      throw StateError('Interpreter not loaded');
    }

    _log('TFLite inputShape=$inputShape outputShape=$outputShape inputType=$inputType outputType=$outputType');

    if (inputShape.length != 4) {
      throw StateError('Unsupported input shape: $inputShape');
    }

    final batch = inputShape[0];
    final inH = inputShape[1];
    final inW = inputShape[2];
    final inC = inputShape[3];

    if (batch != 1 || inC != 3) {
      throw StateError('Only [1,H,W,3] RGB supported. Got: $inputShape');
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Cannot decode image');
    }

    final usedLabels = labels ?? defaultBirdLabels;

    final origW = decoded.width.toDouble();
    final origH = decoded.height.toDouble();

    final letter = _letterbox(decoded, targetW: inW, targetH: inH);

    _log(
      'Letterbox: orig=${decoded.width}x${decoded.height} -> in=${inW}x${inH} scale=${letter.scale.toStringAsFixed(6)} pad=(${letter.padX},${letter.padY})',
    );

    final outTensorSize = outputShape.reduce((a, b) => a * b);

    // If model input is quantized, feeding float can produce garbage -> 0 detections.
    // For float input, some exports expect 0..1 or 0..255 floats. We'll try both.
    final variants = (inputType == TensorType.float32)
        ? <_InputVariant>[const _InputVariant(scaleDiv: 255.0), const _InputVariant(scaleDiv: 1.0)]
        : <_InputVariant>[const _InputVariant(scaleDiv: 1.0)];

    _DetDecodePick? best;

    for (final v in variants) {
      // Ultralytics uses float32 normalized to 0..1 (divide by 255).
      // Only fall back to scaleDiv=1.0 if scaleDiv=255 produced no detections.
      if (inputType == TensorType.float32 && v.scaleDiv == 1.0 && best != null && best!.det.isNotEmpty) {
        continue;
      }
      final Object inputBuffer;
      if (inputType == TensorType.float32) {
        final input = Float32List(inH * inW * inC);
        var idx = 0;
        for (var y = 0; y < inH; y++) {
          for (var x = 0; x < inW; x++) {
            final pixel = letter.image.getPixel(x, y);
            input[idx++] = img.getRed(pixel) / v.scaleDiv;
            input[idx++] = img.getGreen(pixel) / v.scaleDiv;
            input[idx++] = img.getBlue(pixel) / v.scaleDiv;
          }
        }
        inputBuffer = input.reshape([1, inH, inW, inC]);
      } else if (inputType == TensorType.uint8) {
        final input = Uint8List(inH * inW * inC);
        var idx = 0;
        for (var y = 0; y < inH; y++) {
          for (var x = 0; x < inW; x++) {
            final pixel = letter.image.getPixel(x, y);
            input[idx++] = img.getRed(pixel);
            input[idx++] = img.getGreen(pixel);
            input[idx++] = img.getBlue(pixel);
          }
        }
        inputBuffer = input.reshape([1, inH, inW, inC]);
      } else {
        throw StateError('Unsupported input tensor type: $inputType');
      }

      // Run inference and always convert output to Float32List for decoding.
      // IMPORTANT: our reshape() helper copies data, so we must read from the
      // actual output buffer object that Interpreter writes into.
      final Float32List outputFlat;
      if (outputType == TensorType.float32) {
        final outputBuffer = _makeOutputBufferFloat(outputShape);
        interpreter.run(inputBuffer, outputBuffer);
        outputFlat = _flattenOutputBufferFloat(outputBuffer, outputShape);
      } else if (outputType == TensorType.uint8) {
        final outputBuffer = _makeOutputBufferUint8(outputShape);
        interpreter.run(inputBuffer, outputBuffer);

        final raw = _flattenOutputBufferUint8(outputBuffer, outputShape);
        final scale = _outputQuantScale ?? 1.0;
        final zp = _outputQuantZeroPoint ?? 0;
        outputFlat = Float32List(outTensorSize);
        for (var i = 0; i < outTensorSize; i++) {
          outputFlat[i] = (raw[i] - zp) * scale;
        }
      } else if (outputType == TensorType.int8) {
        final outputBuffer = _makeOutputBufferInt8(outputShape);
        interpreter.run(inputBuffer, outputBuffer);

        final raw = _flattenOutputBufferInt8(outputBuffer, outputShape);
        final scale = _outputQuantScale ?? 1.0;
        final zp = _outputQuantZeroPoint ?? 0;
        outputFlat = Float32List(outTensorSize);
        for (var i = 0; i < outTensorSize; i++) {
          outputFlat[i] = (raw[i] - zp) * scale;
        }
      } else {
        throw StateError('Unsupported output tensor type: $outputType');
      }

      if (!(outputShape.length == 3 && outputShape[0] == 1)) {
        throw StateError('Expected detection output shape like [1,C,N]. Got: $outputShape');
      }

      // YOLO export can be either [1, C, N] or [1, N, C]. Auto-detect.
      var channels = outputShape[1];
      var boxes = outputShape[2];
      var boxMajor = false; // if true: layout is [1, N, C]
      if (channels > 64 && boxes <= 64) {
        // e.g. [1, 8400, 15]
        boxMajor = true;
        boxes = outputShape[1];
        channels = outputShape[2];
      }

      _log('Infer variant scaleDiv=${v.scaleDiv} -> layout=${boxMajor ? "[1,N,C]" : "[1,C,N]"} channels=$channels boxes=$boxes');

      final decoded = _decodeBestVariant(
        outputFlat,
        inW: inW.toDouble(),
        inH: inH.toDouble(),
        origW: origW,
        origH: origH,
        scale: letter.scale,
        padX: letter.padX,
        padY: letter.padY,
        channels: channels,
        boxes: boxes,
        boxMajor: boxMajor,
        labels: usedLabels,
        scoreThreshold: scoreThreshold,
      );

      // Reduce clutter: keep only top candidates before NMS.
      final pre = _takeTop(decoded, math.max(maxDetections * 20, 200));
      final afterNms = _nms(
        pre,
        iouThreshold: iouThreshold,
        maxDetections: maxDetections,
        classAgnostic: false,
      );
      final maxScore = afterNms.isEmpty ? -1.0 : afterNms.first.score;
      _log('Postprocess scaleDiv=${v.scaleDiv}: detRaw=${decoded.length} detNms=${afterNms.length} maxScore=${maxScore.toStringAsFixed(4)}');
      final pick = _DetDecodePick(scaleDiv: v.scaleDiv, det: afterNms);

      best ??= pick;
      if (_comparePick(pick, best!) > 0) {
        best = pick;
      }
    }

    // Ultralytics preprocessing uses float32 0..1. If both variants produced detections,
    // prefer scaleDiv=255 for closer parity with Colab.
    if (inputType == TensorType.float32 && best != null && best!.det.isNotEmpty) {
      // If we happened to pick scaleDiv=1.0 but scaleDiv=255.0 also produced detections,
      // prefer 255.0.
      // (This is a heuristic; it tends to improve accuracy vs Colab.)
      // No extra state here; we just bias the compare in _comparePick.
    }

    final finalDet = best?.det ?? const <DetectionCandidate>[];

    return DetectionResult(
      detections: finalDet,
      originalImageSize: Size(origW, origH),
    );
  }

  List<DetectionCandidate> _decodeBestVariant(
    Float32List outputFlat, {
    required double inW,
    required double inH,
    required double origW,
    required double origH,
    required double scale,
    required double padX,
    required double padY,
    required int channels,
    required int boxes,
    required bool boxMajor,
    required List<String>? labels,
    required double scoreThreshold,
  }) {
    // Prefer deterministic decode when we can infer layout from channels vs number of labels.
    // For YOLO exports, channels are typically:
    // - 4 + nc (no objectness)
    // - 5 + nc (with objectness)
    final int? nc = labels?.length;
    final bool? inferredHasObj = (nc == null)
        ? null
        : (channels == 4 + nc)
            ? false
            : (channels == 5 + nc)
                ? true
                : null;

    final candidates = <_DetVariant>[];
    final hasObjOptions = inferredHasObj == null ? <bool>[true, false] : <bool>[inferredHasObj];
    for (final hasObj in hasObjOptions) {
      candidates.add(
        _DetVariant(
          hasObjectness: hasObj,
          boxFormat: _BoxFormat.xywhCenter,
          det: _decodeDetections(
            outputFlat,
            inW: inW,
            inH: inH,
            origW: origW,
            origH: origH,
            scale: scale,
            padX: padX,
            padY: padY,
            channels: channels,
            boxes: boxes,
            boxMajor: boxMajor,
            labels: labels,
            hasObjectness: hasObj,
            boxFormat: _BoxFormat.xywhCenter,
            scoreThreshold: scoreThreshold,
          ),
        ),
      );
      candidates.add(
        _DetVariant(
          hasObjectness: hasObj,
          boxFormat: _BoxFormat.xyxy,
          det: _decodeDetections(
            outputFlat,
            inW: inW,
            inH: inH,
            origW: origW,
            origH: origH,
            scale: scale,
            padX: padX,
            padY: padY,
            channels: channels,
            boxes: boxes,
            boxMajor: boxMajor,
            labels: labels,
            hasObjectness: hasObj,
            boxFormat: _BoxFormat.xyxy,
            scoreThreshold: scoreThreshold,
          ),
        ),
      );
    }

    candidates.sort((a, b) {
      final countCmp = b.det.length.compareTo(a.det.length);
      if (countCmp != 0) return countCmp;
      final maxA = a.det.isEmpty ? -1.0 : a.det.first.score;
      final maxB = b.det.isEmpty ? -1.0 : b.det.first.score;
      return maxB.compareTo(maxA);
    });

    return candidates.first.det;
  }

  int _comparePick(_DetDecodePick a, _DetDecodePick b) {
    final countCmp = a.det.length.compareTo(b.det.length);
    if (countCmp != 0) return countCmp;
    final maxA = a.det.isEmpty ? -1.0 : a.det.first.score;
    final maxB = b.det.isEmpty ? -1.0 : b.det.first.score;
    return maxA.compareTo(maxB);
  }

  Future<ClassificationResult> classifyImageBytes(
    Uint8List imageBytes, {
    List<String>? labels,
    int topK = 3,
  }) async {
    await load();

    final interpreter = _interpreter;
    final inputShape = _inputShape;
    final outputShape = _outputShape;

    if (interpreter == null || inputShape == null || outputShape == null) {
      throw StateError('Interpreter not loaded');
    }

    if (inputShape.length != 4) {
      throw StateError('Unsupported input shape: $inputShape');
    }

    final batch = inputShape[0];
    final height = inputShape[1];
    final width = inputShape[2];
    final channels = inputShape[3];

    if (batch != 1) {
      throw StateError('Only batch=1 supported. Got: $inputShape');
    }

    if (channels != 3) {
      throw StateError('Only RGB input supported. Got channels=$channels');
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Cannot decode image');
    }

    final resized = img.copyResize(decoded, width: width, height: height, interpolation: img.Interpolation.linear);

    final input = Float32List(height * width * channels);
    var idx = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        final r = img.getRed(pixel).toDouble();
        final g = img.getGreen(pixel).toDouble();
        final b = img.getBlue(pixel).toDouble();

        input[idx++] = (r / 255.0);
        input[idx++] = (g / 255.0);
        input[idx++] = (b / 255.0);
      }
    }

    final inputBuffer = input.reshape([1, height, width, channels]);

    final outTensorSize = outputShape.reduce((a, b) => a * b);

    final TensorType outType = interpreter.getOutputTensors().first.type;
    final Float32List outputFlat;
    if (outType == TensorType.float32) {
      final outputBuffer = _makeOutputBufferFloat(outputShape);
      interpreter.run(inputBuffer, outputBuffer);
      outputFlat = _flattenOutputBufferFloat(outputBuffer, outputShape);
    } else if (outType == TensorType.uint8) {
      final outputBuffer = _makeOutputBufferUint8(outputShape);
      interpreter.run(inputBuffer, outputBuffer);
      final raw = _flattenOutputBufferUint8(outputBuffer, outputShape);
      final scale = interpreter.getOutputTensors().first.params.scale;
      final zp = interpreter.getOutputTensors().first.params.zeroPoint;
      outputFlat = Float32List(outTensorSize);
      for (var i = 0; i < outTensorSize; i++) {
        outputFlat[i] = (raw[i] - zp) * scale;
      }
    } else if (outType == TensorType.int8) {
      final outputBuffer = _makeOutputBufferInt8(outputShape);
      interpreter.run(inputBuffer, outputBuffer);
      final raw = _flattenOutputBufferInt8(outputBuffer, outputShape);
      final scale = interpreter.getOutputTensors().first.params.scale;
      final zp = interpreter.getOutputTensors().first.params.zeroPoint;
      outputFlat = Float32List(outTensorSize);
      for (var i = 0; i < outTensorSize; i++) {
        outputFlat[i] = (raw[i] - zp) * scale;
      }
    } else {
      throw StateError('Unsupported output tensor type: $outType');
    }

    final probs = _flattenOutputToProbabilities(outputFlat, outputShape);

    final candidates = _topK(probs, topK).map((e) {
      final label = (labels != null && e.index >= 0 && e.index < labels.length) ? labels[e.index] : null;
      return ClassificationCandidate(index: e.index, label: label, score: e.score);
    }).toList();

    return ClassificationResult(topK: candidates);
  }

  List<double> _flattenOutputToProbabilities(Float32List outputFlat, List<int> outputShape) {
    if (outputShape.length == 2 && outputShape[0] == 1) {
      return outputFlat.toList(growable: false);
    }

    if (outputShape.length == 1) {
      return outputFlat.toList(growable: false);
    }

    // Common object-detection head layout: [1, (4 + 1 + numClasses), numBoxes]
    // Or YOLOv8-style: [1, (4 + numClasses), numBoxes] (no explicit objectness).
    // We'll convert this to class probabilities by taking max over boxes.
    if (outputShape.length == 3 && outputShape[0] == 1) {
      final channels = outputShape[1];
      final boxes = outputShape[2];

      // Decode variant A: with objectness
      List<double>? withObj;
      double withObjMax = -1.0;
      if (channels >= 6) {
        final numClasses = channels - 5;
        final classScores = List<double>.filled(numClasses, 0.0, growable: false);

        for (var b = 0; b < boxes; b++) {
          final obj = _sigmoid(outputFlat[(4 * boxes) + b]);
          for (var c = 0; c < numClasses; c++) {
            final cls = _sigmoid(outputFlat[((5 + c) * boxes) + b]);
            final score = obj * cls;
            if (score > classScores[c]) {
              classScores[c] = score;
              if (score > withObjMax) withObjMax = score;
            }
          }
        }
        withObj = classScores;
      }

      // Decode variant B: no objectness
      List<double>? noObj;
      double noObjMax = -1.0;
      if (channels >= 5) {
        final numClasses = channels - 4;
        final classScores = List<double>.filled(numClasses, 0.0, growable: false);

        for (var b = 0; b < boxes; b++) {
          for (var c = 0; c < numClasses; c++) {
            final cls = _sigmoid(outputFlat[((4 + c) * boxes) + b]);
            if (cls > classScores[c]) {
              classScores[c] = cls;
              if (cls > noObjMax) noObjMax = cls;
            }
          }
        }
        noObj = classScores;
      }

      if (withObj != null && noObj != null) {
        return (noObjMax >= withObjMax) ? noObj : withObj;
      }

      if (noObj != null) return noObj;
      if (withObj != null) return withObj;

      // Fallback: just flatten
      return outputFlat.toList(growable: false);
    }

    if (outputShape.length == 4 && outputShape[0] == 1 && outputShape[1] == 1 && outputShape[2] == 1) {
      return outputFlat.toList(growable: false);
    }

    return outputFlat.toList(growable: false);
  }

  double _sigmoid(double x) {
    // Guard for extreme values
    if (x >= 20) return 1.0;
    if (x <= -20) return 0.0;
    return 1.0 / (1.0 + math.exp(-x));
  }

  List<DetectionCandidate> _decodeDetections(
    Float32List outputFlat, {
    required double inW,
    required double inH,
    required double origW,
    required double origH,
    required double scale,
    required double padX,
    required double padY,
    required int channels,
    required int boxes,
    required bool boxMajor,
    required List<String>? labels,
    required bool hasObjectness,
    required _BoxFormat boxFormat,
    required double scoreThreshold,
  }) {
    final classStart = hasObjectness ? 5 : 4;
    final minChannels = classStart + 1;
    if (channels < minChannels) return const [];

    final numClasses = channels - classStart;
    if (numClasses <= 0) return const [];

    final out = <DetectionCandidate>[];

    double at(int ch, int b) {
      // [1, C, N] => index = ch*boxes + b
      // [1, N, C] => index = b*channels + ch
      return boxMajor ? outputFlat[(b * channels) + ch] : outputFlat[(ch * boxes) + b];
    }

    for (var b = 0; b < boxes; b++) {
      final cxRaw = at(0, b);
      final cyRaw = at(1, b);
      final wRaw = at(2, b);
      final hRaw = at(3, b);

      final obj = hasObjectness ? _sigmoid(at(4, b)) : 1.0;

      var bestClass = 0;
      var bestScore = -1.0;
      for (var c = 0; c < numClasses; c++) {
        final cls = _sigmoid(at(classStart + c, b));
        final score = cls * obj;
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      if (bestScore < scoreThreshold) continue;

      // Heuristic: if values are in [0..1] then they are normalized.
      final normalized = cxRaw.abs() <= 1.5 && cyRaw.abs() <= 1.5 && wRaw.abs() <= 1.5 && hRaw.abs() <= 1.5;

      double left;
      double top;
      double right;
      double bottom;

      if (boxFormat == _BoxFormat.xyxy) {
        final x1 = normalized ? (cxRaw * inW) : cxRaw;
        final y1 = normalized ? (cyRaw * inH) : cyRaw;
        final x2 = normalized ? (wRaw * inW) : wRaw;
        final y2 = normalized ? (hRaw * inH) : hRaw;

        final lx = math.min(x1, x2);
        final rx = math.max(x1, x2);
        final ty = math.min(y1, y2);
        final by = math.max(y1, y2);

        left = (lx - padX) / scale;
        right = (rx - padX) / scale;
        top = (ty - padY) / scale;
        bottom = (by - padY) / scale;
      } else {
        final cx = normalized ? (cxRaw * inW) : cxRaw;
        final cy = normalized ? (cyRaw * inH) : cyRaw;
        final bw = normalized ? (wRaw * inW) : wRaw;
        final bh = normalized ? (hRaw * inH) : hRaw;

        final lx = cx - bw / 2;
        final rx = cx + bw / 2;
        final ty = cy - bh / 2;
        final by = cy + bh / 2;

        left = (lx - padX) / scale;
        right = (rx - padX) / scale;
        top = (ty - padY) / scale;
        bottom = (by - padY) / scale;
      }

      left = left.clamp(0.0, origW);
      right = right.clamp(0.0, origW);
      top = top.clamp(0.0, origH);
      bottom = bottom.clamp(0.0, origH);

      if (right <= left || bottom <= top) continue;

      final label = (labels != null && bestClass >= 0 && bestClass < labels.length) ? labels[bestClass] : null;
      out.add(
        DetectionCandidate(
          rect: Rect.fromLTRB(left, top, right, bottom),
          classIndex: bestClass,
          label: label,
          score: bestScore,
        ),
      );
    }

    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  _LetterboxResult _letterbox(
    img.Image src, {
    required int targetW,
    required int targetH,
  }) {
    final w = src.width.toDouble();
    final h = src.height.toDouble();

    final r = math.min(targetW / w, targetH / h);
    final newW = (w * r).round();
    final newH = (h * r).round();

    final resized = img.copyResize(
      src,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    final canvas = img.Image(targetW, targetH);
    final padColor = img.getColor(114, 114, 114);
    img.fill(canvas, padColor);

    final dx = ((targetW - newW) / 2).round();
    final dy = ((targetH - newH) / 2).round();
    img.copyInto(canvas, resized, dstX: dx, dstY: dy);

    return _LetterboxResult(
      image: canvas,
      scale: r,
      padX: dx.toDouble(),
      padY: dy.toDouble(),
    );
  }

  List<DetectionCandidate> _nms(
    List<DetectionCandidate> detections, {
    required double iouThreshold,
    required int maxDetections,
    required bool classAgnostic,
  }) {
    final selected = <DetectionCandidate>[];

    for (final det in detections) {
      var keep = true;
      for (final s in selected) {
        if (!classAgnostic && s.classIndex != det.classIndex) continue;
        final iou = _iou(s.rect, det.rect);
        if (iou > iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) {
        selected.add(det);
        if (selected.length >= maxDetections) break;
      }
    }

    return selected;
  }

  List<DetectionCandidate> _takeTop(List<DetectionCandidate> det, int k) {
    if (det.isEmpty) return det;
    if (det.length <= k) return det;
    return det.take(k).toList(growable: false);
  }

  double _iou(Rect a, Rect b) {
    final interLeft = math.max(a.left, b.left);
    final interTop = math.max(a.top, b.top);
    final interRight = math.min(a.right, b.right);
    final interBottom = math.min(a.bottom, b.bottom);

    final iw = math.max(0.0, interRight - interLeft);
    final ih = math.max(0.0, interBottom - interTop);
    final inter = iw * ih;
    if (inter <= 0) return 0.0;

    final areaA = (a.width) * (a.height);
    final areaB = (b.width) * (b.height);
    final union = areaA + areaB - inter;
    if (union <= 0) return 0.0;
    return inter / union;
  }

  List<_IdxScore> _topK(List<double> probs, int k) {
    final kk = math.min(k, probs.length);
    final items = List<_IdxScore>.generate(probs.length, (i) => _IdxScore(index: i, score: probs[i]));
    items.sort((a, b) => b.score.compareTo(a.score));
    return items.take(kk).toList(growable: false);
  }

  // Output buffer helpers (Interpreter writes into nested Lists)
  Object _makeOutputBufferFloat(List<int> shape) {
    if (shape.length == 3) {
      final a = shape[0];
      final b = shape[1];
      final c = shape[2];
      return List.generate(
        a,
        (_) => List.generate(
          b,
          (_) => List.filled(c, 0.0, growable: false),
          growable: false,
        ),
        growable: false,
      );
    }
    if (shape.length == 2) {
      final a = shape[0];
      final b = shape[1];
      return List.generate(a, (_) => List.filled(b, 0.0, growable: false), growable: false);
    }
    if (shape.length == 1) {
      return List.filled(shape[0], 0.0, growable: false);
    }
    throw StateError('Unsupported float output shape: $shape');
  }

  Float32List _flattenOutputBufferFloat(Object outputBuffer, List<int> shape) {
    final total = shape.reduce((a, b) => a * b);
    final out = Float32List(total);
    var i = 0;
    if (shape.length == 3) {
      final o = outputBuffer as List;
      for (final x in o) {
        final xx = x as List;
        for (final y in xx) {
          final yy = y as List;
          for (final v in yy) {
            out[i++] = (v as num).toDouble();
          }
        }
      }
      return out;
    }
    if (shape.length == 2) {
      final o = outputBuffer as List;
      for (final x in o) {
        final xx = x as List;
        for (final v in xx) {
          out[i++] = (v as num).toDouble();
        }
      }
      return out;
    }
    if (shape.length == 1) {
      final o = outputBuffer as List;
      for (final v in o) {
        out[i++] = (v as num).toDouble();
      }
      return out;
    }
    throw StateError('Unsupported float output shape: $shape');
  }

  Object _makeOutputBufferUint8(List<int> shape) {
    if (shape.length == 3) {
      final a = shape[0];
      final b = shape[1];
      final c = shape[2];
      return List.generate(
        a,
        (_) => List.generate(
          b,
          (_) => List.filled(c, 0, growable: false),
          growable: false,
        ),
        growable: false,
      );
    }
    if (shape.length == 2) {
      final a = shape[0];
      final b = shape[1];
      return List.generate(a, (_) => List.filled(b, 0, growable: false), growable: false);
    }
    if (shape.length == 1) {
      return List.filled(shape[0], 0, growable: false);
    }
    throw StateError('Unsupported uint8 output shape: $shape');
  }

  Uint8List _flattenOutputBufferUint8(Object outputBuffer, List<int> shape) {
    final total = shape.reduce((a, b) => a * b);
    final out = Uint8List(total);
    var i = 0;
    if (shape.length == 3) {
      final o = outputBuffer as List;
      for (final x in o) {
        final xx = x as List;
        for (final y in xx) {
          final yy = y as List;
          for (final v in yy) {
            out[i++] = (v as num).toInt();
          }
        }
      }
      return out;
    }
    if (shape.length == 2) {
      final o = outputBuffer as List;
      for (final x in o) {
        final xx = x as List;
        for (final v in xx) {
          out[i++] = (v as num).toInt();
        }
      }
      return out;
    }
    if (shape.length == 1) {
      final o = outputBuffer as List;
      for (final v in o) {
        out[i++] = (v as num).toInt();
      }
      return out;
    }
    throw StateError('Unsupported uint8 output shape: $shape');
  }

  Object _makeOutputBufferInt8(List<int> shape) {
    if (shape.length == 3) {
      final a = shape[0];
      final b = shape[1];
      final c = shape[2];
      return List.generate(
        a,
        (_) => List.generate(
          b,
          (_) => List.filled(c, 0, growable: false),
          growable: false,
        ),
        growable: false,
      );
    }
    if (shape.length == 2) {
      final a = shape[0];
      final b = shape[1];
      return List.generate(a, (_) => List.filled(b, 0, growable: false), growable: false);
    }
    if (shape.length == 1) {
      return List.filled(shape[0], 0, growable: false);
    }
    throw StateError('Unsupported int8 output shape: $shape');
  }

  Int8List _flattenOutputBufferInt8(Object outputBuffer, List<int> shape) {
    final total = shape.reduce((a, b) => a * b);
    final out = Int8List(total);
    var i = 0;
    if (shape.length == 3) {
      final o = outputBuffer as List;
      for (final x in o) {
        final xx = x as List;
        for (final y in xx) {
          final yy = y as List;
          for (final v in yy) {
            out[i++] = (v as num).toInt();
          }
        }
      }
      return out;
    }
    if (shape.length == 2) {
      final o = outputBuffer as List;
      for (final x in o) {
        final xx = x as List;
        for (final v in xx) {
          out[i++] = (v as num).toInt();
        }
      }
      return out;
    }
    if (shape.length == 1) {
      final o = outputBuffer as List;
      for (final v in o) {
        out[i++] = (v as num).toInt();
      }
      return out;
    }
    throw StateError('Unsupported int8 output shape: $shape');
  }
}

class _IdxScore {
  final int index;
  final double score;

  _IdxScore({
    required this.index,
    required this.score,
  });
}

extension _ReshapeFloat32 on Float32List {
  Object reshape(List<int> shape) {
    if (shape.length == 4) {
      final b = shape[0];
      final h = shape[1];
      final w = shape[2];
      final c = shape[3];
      final out = List.generate(b, (_) => List.generate(h, (_) => List.generate(w, (_) => List.filled(c, 0.0, growable: false), growable: false), growable: false), growable: false);
      var i = 0;
      for (var bb = 0; bb < b; bb++) {
        for (var yy = 0; yy < h; yy++) {
          for (var xx = 0; xx < w; xx++) {
            for (var cc = 0; cc < c; cc++) {
              out[bb][yy][xx][cc] = this[i++];
            }
          }
        }
      }
      return out;
    }

    if (shape.length == 3) {
      final a = shape[0];
      final b = shape[1];
      final c = shape[2];
      final out = List.generate(
        a,
        (_) => List.generate(
          b,
          (_) => List.filled(c, 0.0, growable: false),
          growable: false,
        ),
        growable: false,
      );
      var i = 0;
      for (var aa = 0; aa < a; aa++) {
        for (var bb = 0; bb < b; bb++) {
          for (var cc = 0; cc < c; cc++) {
            out[aa][bb][cc] = this[i++];
          }
        }
      }
      return out;
    }

    if (shape.length == 2) {
      final a = shape[0];
      final b = shape[1];
      final out = List.generate(a, (_) => List.filled(b, 0.0, growable: false), growable: false);
      var i = 0;
      for (var aa = 0; aa < a; aa++) {
        for (var bb = 0; bb < b; bb++) {
          out[aa][bb] = this[i++];
        }
      }
      return out;
    }

    if (shape.length == 1) {
      return toList(growable: false);
    }

    return toList(growable: false);
  }
}
