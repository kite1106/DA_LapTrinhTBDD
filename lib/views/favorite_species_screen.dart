import 'package:flutter/material.dart';

import '../models/species_model.dart';
import '../services/firestore_service.dart';
import 'species_detail_screen.dart';

class FavoriteSpeciesScreen extends StatefulWidget {
  const FavoriteSpeciesScreen({super.key});

  @override
  State<FavoriteSpeciesScreen> createState() => _FavoriteSpeciesScreenState();
}

class _FavoriteSpeciesScreenState extends State<FavoriteSpeciesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<Species> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // TODO: Lấy userId hiện tại và gọi getFavoriteSpecies
    setState(() => _isLoading = true);
    // Tạm thời để danh sách rỗng để không lỗi UI
    setState(() {
      _favorites = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loài yêu thích'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade50,
              Colors.red.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
                ? const Center(
                    child: Text('Bạn chưa có loài yêu thích nào.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final species = _favorites[index];
                      return Card(
                        child: ListTile(
                          title: Text(species.commonName),
                          subtitle: Text(species.scientificName),
                          trailing: Text(species.conservationStatus),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpeciesDetailScreen(
                                  species: species,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
