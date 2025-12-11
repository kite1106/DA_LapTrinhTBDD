import '../models/species_model.dart';
import '../services/firestore_service.dart';

class SpeciesController {
  final FirestoreService _firestoreService = FirestoreService();

  List<Species> _species = [];
  bool _isLoading = false;
  String? _error;

  List<Species> get species => _species;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSpecies() async {
    _isLoading = true;
    _error = null;
    try {
      _species = await _firestoreService.getAllSpecies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  Future<String> addSpecies(Species species) async {
    try {
      return await _firestoreService.addSpecies(species);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<bool> updateSpecies(Species species) async {
    try {
      return await _firestoreService.updateSpecies(species);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteSpecies(Species species) async {
    try {
      return await _firestoreService.deleteSpecies(species.id);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void clearError() {
    _error = null;
  }
}
