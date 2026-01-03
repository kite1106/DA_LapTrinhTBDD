import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'animal_detail_screen.dart';

class RareAnimalsMapScreen extends StatefulWidget {
  const RareAnimalsMapScreen({super.key});

  @override
  State<RareAnimalsMapScreen> createState() => _RareAnimalsMapScreenState();
}

class _RareAnimalsMapScreenState extends State<RareAnimalsMapScreen> {
  final MapController _mapController = MapController();
  double _zoom = 2;

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('animals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          final points = <_RarePoint>[];
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final LatLng? latLng = _extractLatLng(data['location']);
            if (latLng == null) continue;

            points.add(
              _RarePoint(
                id: doc.id,
                data: data,
                point: latLng,
              ),
            );
          }

          if (points.isEmpty) {
            return const Center(
              child: Text('Chưa có dữ liệu có tọa độ để hiển thị trên bản đồ.'),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Hiển thị toàn thế giới, không giới hạn
                  initialCenter: const LatLng(0, 0),
                  initialZoom: 2,
                  interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.rotate),
                  onPositionChanged: (pos, _) {
                    final z = pos.zoom;
                    if (z == null) return;
                    if ((z - _zoom).abs() < 0.001) return;
                    setState(() {
                      _zoom = z;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    // Dùng OSM host đơn, zoom toàn cầu
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    maxZoom: 19,
                    minZoom: 2,
                    backgroundColor: Colors.transparent,
                    userAgentPackageName: 'com.example.flutter_firebase_app',
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(points),
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: FloatingActionButton.small(
                      heroTag: 'back_map',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers(List<_RarePoint> points) {
    return points.map((p) {
      final name = (p.data['name'] ?? p.data['species'] ?? '').toString();
      final isRare = p.data['isRare'] == true;
      final color = isRare ? Colors.red : Colors.blue;
      return Marker(
        point: p.point,
        width: 22,
        height: 22,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnimalDetailScreen(
                  animalId: p.id,
                  animalData: p.data,
                ),
              ),
            );
          },
          child: Tooltip(
            message: name.isNotEmpty ? name : 'Loài',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
  LatLng? _extractLatLng(dynamic raw) {
    if (raw == null) return null;

    if (raw is GeoPoint) {
      return LatLng(raw.latitude, raw.longitude);
    }

    if (raw is Map) {
      final lat = raw['latitude'];
      final lng = raw['longitude'];
      final double? latD = (lat is num) ? lat.toDouble() : (lat is String ? double.tryParse(lat) : null);
      final double? lngD = (lng is num) ? lng.toDouble() : (lng is String ? double.tryParse(lng) : null);
      if (latD != null && lngD != null) return LatLng(latD, lngD);
    }

    if (raw is String) {
      // 1) "lat,lng"
      if (raw.contains(',')) {
        final parts = raw.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) return LatLng(lat, lng);
        }
      }

      // 2) "25.812978333° N, 100.1432945° E"
      final cleaned = raw
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('°', '')
          .replaceAll('N', ' N')
          .replaceAll('S', ' S')
          .replaceAll('E', ' E')
          .replaceAll('W', ' W');

      final re = RegExp(r'([0-9.+-]+)\s*([NS])[^0-9.+-]*([0-9.+-]+)\s*([EW])', caseSensitive: false);
      final m = re.firstMatch(cleaned);
      if (m != null) {
        final lat = double.tryParse(m.group(1) ?? '');
        final ns = (m.group(2) ?? '').toUpperCase();
        final lng = double.tryParse(m.group(3) ?? '');
        final ew = (m.group(4) ?? '').toUpperCase();
        if (lat != null && lng != null) {
          final latSigned = (ns == 'S') ? -lat : lat;
          final lngSigned = (ew == 'W') ? -lng : lng;
          return LatLng(latSigned, lngSigned);
        }
      }
    }

    return null;
  }

  LatLng _averageCenter(List<_RarePoint> points) {
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final p in points) {
      latSum += p.point.latitude;
      lngSum += p.point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}

class _RarePoint {
  final String id;
  final Map<String, dynamic> data;
  final LatLng point;

  const _RarePoint({
    required this.id,
    required this.data,
    required this.point,
  });
}

class _Cluster {
  final LatLng center;
  final List<_RarePoint> items;

  const _Cluster({
    required this.center,
    required this.items,
  });
}
