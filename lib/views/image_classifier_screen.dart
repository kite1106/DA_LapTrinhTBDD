import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/image_classifier_controller.dart';
import '../utils/detection_painter.dart';
import '../data/bird_repository.dart';
import '../models/bird_info.dart';

class ImageClassifierScreen extends StatefulWidget {
  const ImageClassifierScreen({super.key});

  @override
  State<ImageClassifierScreen> createState() => _ImageClassifierScreenState();
}

class _ImageClassifierScreenState extends State<ImageClassifierScreen> {
  final ImageClassifierController _controller = ImageClassifierController();

  bool _modelReady = false;

  Future<BirdInfo?> _loadBirdInfo(String label) async {
    final fallback = birdRepository[label];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('animals')
          .where('species', isEqualTo: label)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return fallback;

      final data = snap.docs.first.data();

      final String commonName = (data['name'] ?? data['commonName'] ?? label).toString();
      final String scientificName = (data['scientificName'] ?? fallback?.scientificName ?? '').toString();

      final rawDescription = (data['description'] ?? '').toString();
      final description = (rawDescription.isEmpty || rawDescription == 'No description available')
          ? (fallback?.description.isNotEmpty == true ? fallback!.description : 'Chưa có mô tả.')
          : rawDescription;

      final observer = (data['observer'] ?? fallback?.observer ?? 'Không rõ').toString();

      DateTime observedAt = fallback?.observedAt ?? DateTime.now();
      final dynamic observedRaw = data['observedAt'] ?? data['observedOn'] ?? data['createdAt'];
      if (observedRaw is Timestamp) {
        observedAt = observedRaw.toDate();
      } else if (observedRaw is String) {
        final parsed = DateTime.tryParse(observedRaw);
        if (parsed != null) observedAt = parsed;
      }

      double? lat = fallback?.latitude;
      double? lng = fallback?.longitude;
      final dynamic loc = data['location'] ?? data['geoPoint'];
      if (loc is GeoPoint) {
        lat = loc.latitude;
        lng = loc.longitude;
      } else if (data['latitude'] != null && data['longitude'] != null) {
        lat = (data['latitude'] as num).toDouble();
        lng = (data['longitude'] as num).toDouble();
      } else if (data['lat'] != null && data['lng'] != null) {
        lat = (data['lat'] as num).toDouble();
        lng = (data['lng'] as num).toDouble();
      }

      if (lat == null || lng == null) {
        lat = fallback?.latitude ?? 0;
        lng = fallback?.longitude ?? 0;
      }

      final imageUrl = (data['imageUrl'] ?? data['image'] ?? data['photoUrl'] ?? fallback?.imageUrl ?? '').toString();

      return BirdInfo(
        commonName: commonName,
        scientificName: scientificName,
        description: description,
        observer: observer,
        observedAt: observedAt,
        latitude: lat,
        longitude: lng,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.init();
      if (!mounted) return;
      setState(() {
        _modelReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modelReady = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      await _controller.pickImage(source);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
      setState(() {});
    }
  }

  Future<void> _classify() async {
    try {
      setState(() {});
      await _controller.classify(topK: 5);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi nhận diện: $e')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _controller.image;
    final detection = _controller.detection;
    final topDetection = (detection != null && detection.detections.isNotEmpty) ? detection.detections.first : null;
    final label = topDetection?.label ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận diện ảnh'),
        backgroundColor: const Color(0xFF00A86B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_modelReady)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _controller.error == null
                      ? 'Model chưa sẵn sàng.'
                      : 'Model lỗi: ${_controller.error}',
                ),
              ),
            if (!_modelReady) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _controller.isLoading ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _controller.isLoading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (!_modelReady || _controller.isLoading || image == null) ? null : _classify,
              icon: _controller.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_controller.isLoading ? 'Đang nhận diện...' : 'Nhận diện'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image == null
                    ? const Center(child: Text('Chưa chọn ảnh'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final displaySize = Size(constraints.maxWidth, constraints.maxHeight);
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(image.path),
                                fit: BoxFit.contain,
                              ),
                              if (detection != null)
                                CustomPaint(
                                  painter: DetectionPainter(
                                    result: detection,
                                    displaySize: displaySize,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.error != null)
              Text(
                'Lỗi: ${_controller.error}',
                style: const TextStyle(color: Colors.red),
              ),
            if (detection != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Detections: ${detection.detections.length}'),
              ),
            if (topDetection != null) ...[
              const SizedBox(height: 8),
              FutureBuilder<BirdInfo?>(
                future: label.isEmpty ? Future.value(null) : _loadBirdInfo(label),
                builder: (context, snap) {
                  final info = snap.data;

                  if (snap.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Đang tải mô tả từ Firebase...'),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _SpeciesDetailCard(
                        label: label.isNotEmpty ? label : 'Không rõ',
                        score: topDetection.score,
                        info: info,
                      ),
                      const SizedBox(height: 12),
                      if (info != null && (info.latitude != 0 || info.longitude != 0))
                        SizedBox(
                          height: 220,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(info.latitude, info.longitude),
                              initialZoom: 12,
                              interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.rotate),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.flutter_firebase_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(info.latitude, info.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text('Chưa có tọa độ cho loài này.'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeciesDetailCard extends StatelessWidget {
  final String label;
  final double score;
  final BirdInfo? info;

  const _SpeciesDetailCard({
    required this.label,
    required this.score,
    this.info,
  });

  @override
  Widget build(BuildContext context) {
    final commonName = info?.commonName ?? label;
    final scientificName = info?.scientificName ?? '';
    final description = info?.description?.isNotEmpty == true ? info!.description : 'Chưa có mô tả.';
    final observer = info?.observer ?? 'Không rõ';
    final observedAt = info?.observedAt;
    final lat = info?.latitude;
    final lng = info?.longitude;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(commonName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (scientificName.isNotEmpty)
            Text(scientificName, style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text('Độ tin cậy: ${(score * 100).toStringAsFixed(2)}%'),
          const SizedBox(height: 8),
          Text('Mô tả:', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(description),
          const SizedBox(height: 8),
          Text('Thông tin quan sát:', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Người quan sát: $observer'),
          if (observedAt != null)
            Text("Thời gian: ${observedAt.toIso8601String().split('T').first}"),
          if (lat != null && lng != null) Text('Lat: $lat, Lng: $lng'),
        ],
      ),
    );
  }
}
