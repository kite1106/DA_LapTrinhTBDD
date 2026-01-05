import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/animal_service.dart';

class AnimalModel {
  final String id;
  final String name;
  final String species;
  final String description;
  final String imageUrl;
  final bool isRare;
  final GeoPoint location;

  AnimalModel({
    required this.id,
    required this.name,
    required this.species,
    required this.description,
    required this.imageUrl,
    required this.isRare,
    required this.location,
  });
}

class AnimalController {
  final AnimalService _animalService = AnimalService();

  List<AnimalModel> _animals = [];
  bool _isLoading = false;
  String? _error;

  List<AnimalModel> get animals => _animals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<QuerySnapshot> getAnimalsStream() {
    return _animalService.getAnimals();
  }

  Future<void> loadAnimals() async {
    _isLoading = true;
    _error = null;

    try {
      final stream = _animalService.getAnimals();
      final snapshot = await stream.first;
      _animals = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AnimalModel(
          id: doc.id,
          name: data['name'] ?? '',
          species: data['species'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          isRare: data['isRare'] ?? false,
          location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
        );
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addAnimal({
    required String name,
    required String species,
    required String description,
    required String imageUrl,
    required bool isRare,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _animalService.addAnimal(
        name: name,
        species: species,
        description: description,
        imageUrl: imageUrl,
        isRare: isRare,
        latitude: latitude,
        longitude: longitude,
      );
      await loadAnimals();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
  }
}
