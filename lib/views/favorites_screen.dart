import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../providers/favorites_provider.dart';
import 'animal_detail_screen.dart';
import 'news_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final firestore = FirebaseFirestore.instance;
    final primary = const Color(0xFF00A86B);
    final state = ValueNotifier<_FavTab>(_FavTab.animals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<_FavTab>(
        valueListenable: state,
        builder: (context, tab, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _TabChip(
                      label: 'Động vật',
                      selected: tab == _FavTab.animals,
                      onTap: () => state.value = _FavTab.animals,
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: 'Tin tức',
                      selected: tab == _FavTab.news,
                      onTap: () => state.value = _FavTab.news,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (tab == _FavTab.animals)
                      _AnimalFavList(firestore: firestore, favorites: favorites)
                    else
                      _NewsFavList(firestore: firestore, favorites: favorites),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _FavTab { animals, news }

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00A86B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AnimalFavList extends StatelessWidget {
  final FirebaseFirestore firestore;
  final FavoritesProvider favorites;

  const _AnimalFavList({required this.firestore, required this.favorites});

  @override
  Widget build(BuildContext context) {
    if (favorites.animalIds.isEmpty) {
      return const Text('Chưa có động vật yêu thích', style: TextStyle(color: Colors.grey));
    }
    return FutureBuilder<QuerySnapshot>(
      future: firestore.collection('animals').where(FieldPath.documentId, whereIn: favorites.animalIds).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('Không tìm thấy dữ liệu', style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? data['species'] ?? '').toString();
            final imageUrl = (data['imageUrl'] ?? '').toString();
            final isRare = data['isRare'] == true;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty ? const Icon(Icons.pets, color: Colors.grey) : null,
                ),
                title: Text(name.isNotEmpty ? name : 'Không tên'),
                subtitle: Text(isRare ? 'Hiếm' : 'Thường'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => favorites.toggleAnimal(doc.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimalDetailScreen(animalData: data, animalId: doc.id),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _NewsFavList extends StatelessWidget {
  final FirebaseFirestore firestore;
  final FavoritesProvider favorites;

  const _NewsFavList({required this.firestore, required this.favorites});

  @override
  Widget build(BuildContext context) {
    if (favorites.newsIds.isEmpty) {
      return const Text('Chưa có tin tức yêu thích', style: TextStyle(color: Colors.grey));
    }
    return FutureBuilder<QuerySnapshot>(
      future: firestore.collection('news').where(FieldPath.documentId, whereIn: favorites.newsIds).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('Không tìm thấy dữ liệu', style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final news = News.fromFirestore(data, doc.id);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: news.imageUrl.isNotEmpty ? NetworkImage(news.imageUrl) : null,
                  child: news.imageUrl.isEmpty ? const Icon(Icons.article, color: Colors.grey) : null,
                ),
                title: Text(
                  news.cleanTitle.isNotEmpty ? news.cleanTitle : news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(news.getFormattedDate()),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => favorites.toggleNews(doc.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(news: news),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
