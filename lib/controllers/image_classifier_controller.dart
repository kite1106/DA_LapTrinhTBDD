import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../models/detection_result.dart';
import '../services/image_classifier_service.dart';

class ImageClassifierController {
  final ImageClassifierService _service;
  final ImagePicker _picker;

  XFile? _image;
  DetectionResult? _detection;
  bool _isLoading = false;
  String? _error;

  ImageClassifierController({
    ImageClassifierService? service,
    ImagePicker? picker,
  })  : _service = service ?? ImageClassifierService(modelAssetPath: 'assets/best_float32.tflite'),
        _picker = picker ?? ImagePicker();

  XFile? get image => _image;
  DetectionResult? get detection => _detection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    try {
      await _service.load();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    _error = null;
    _detection = null;

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 95);
      if (file == null) return;
      _image = file;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> classify({
    List<String>? labels,
    int topK = 3,
  }) async {
    final image = _image;
    if (image == null) {
      _error = 'Chưa chọn ảnh';
      return;
    }

    _isLoading = true;
    _error = null;
    _detection = null;

    try {
      final bytes = await image.readAsBytes();
      final usedLabels = labels ?? ImageClassifierService.defaultBirdLabels;
      _detection = await _service.detectImageBytes(
        Uint8List.fromList(bytes),
        labels: usedLabels,
        scoreThreshold: 0.7,
        iouThreshold: 0.35,
        maxDetections: 1,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  void clear() {
    _image = null;
    _detection = null;
    _error = null;
    _isLoading = false;
  }

  void dispose() {
    _service.dispose();
  }
}
