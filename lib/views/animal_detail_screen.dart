import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/bird_repository.dart';
import 'edit_animal_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> animalData;
  final String? animalId;

  const AnimalDetailScreen({super.key, required this.animalData, this.animalId});

  @override
  Widget build(BuildContext context) {
    final name = (animalData['name'] ?? '') as String;
    final species = (animalData['species'] ?? '') as String;

    final birdInfo = birdRepository[species];

    final rawDescription = (animalData['description'] ?? '') as String;
    final description = (rawDescription.isEmpty || rawDescription == 'No description available')
        ? (birdInfo?.description.isNotEmpty == true ? birdInfo!.description : 'Không có mô tả chi tiết.')
        : rawDescription;

    final scientificName = birdInfo?.scientificName ?? '';
    final imageUrl = (animalData['imageUrl'] ?? '') as String;
    final observer = (animalData['observer'] ?? '') as String;
    final observedOn = (animalData['observedOn'] ?? '') as String;
    final location = animalData['location'] as GeoPoint?;

    // Ưu tiên tọa độ lưu trong Firestore; nếu không có, không fallback để tránh hiển thị sai.
    final double? lat = location?.latitude;
    final double? lng = location?.longitude;

    String locationText = 'Không rõ vị trí';
    if (lat != null && lng != null) {
      locationText = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Chi tiết động vật (chim)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (animalId != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAnimalScreen(
                      animalId: animalId!,
                      initialData: animalData,
                      fallbackLat: lat,
                      fallbackLng: lng,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.isNotEmpty ? name : '(Không có tên)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            if (species.isNotEmpty)
              Text(
                species,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            if (scientificName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                scientificName,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Mô tả',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Thông tin quan sát',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            if (observer.isNotEmpty)
              Text('Người quan sát: $observer'),
            if (observedOn.isNotEmpty)
              Text('Thời gian quan sát: $observedOn'),
            const SizedBox(height: 4),
            Text(locationText),

            const SizedBox(height: 12),
            if (lat != null && lng != null)
              SizedBox(
                height: 240,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
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
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
