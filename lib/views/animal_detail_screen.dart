import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> animalData;

  const AnimalDetailScreen({super.key, required this.animalData});

  @override
  Widget build(BuildContext context) {
    final name = (animalData['name'] ?? '') as String;
    final species = (animalData['species'] ?? '') as String;
    final rawDescription = (animalData['description'] ?? '') as String;
    final description = rawDescription.isEmpty || rawDescription == 'No description available'
        ? 'Không có mô tả chi tiết.'
        : rawDescription;
    final imageUrl = (animalData['imageUrl'] ?? '') as String;
    final observer = (animalData['observer'] ?? '') as String;
    final observedOn = (animalData['observedOn'] ?? '') as String;
    final location = animalData['location'] as GeoPoint?;

    String locationText = 'Không rõ vị trí';
    if (location != null) {
      locationText = 'Lat: ${location.latitude.toStringAsFixed(4)}, '
          'Lng: ${location.longitude.toStringAsFixed(4)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Chi tiết động vật (chim)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
