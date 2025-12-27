import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/animal_controller.dart';
import 'animal_detail_screen.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  final AnimalController _animalController = AnimalController();
  final int _pageSize = 15;
  int _currentPage = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _rarityFilter = 'all'; // all | rare | common

  void _keepSearchFocus() {
    if (!_searchFocus.hasFocus && _searchFocus.canRequestFocus) {
      _searchFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách động vật (chim)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _animalController.getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có động vật nào được lưu.'));
          }
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '') as String;
            final species = (data['species'] ?? '') as String;
            final isRare = data['isRare'] == true;
            final q = _searchQuery.toLowerCase();
            final matchesText = q.isEmpty || name.toLowerCase().contains(q) || species.toLowerCase().contains(q);
            if (!matchesText) return false;
            if (_rarityFilter == 'rare' && !isRare) return false;
            if (_rarityFilter == 'common' && isRare) return false;
            return true;
          }).toList();

          final total = filteredDocs.length;
          final totalPages = (total / _pageSize).ceil().clamp(1, 9999);

          if (_currentPage >= totalPages) {
            _currentPage = totalPages - 1;
          }
          if (_currentPage < 0) _currentPage = 0;

          final startIndex = _currentPage * _pageSize;
          final endIndex = (startIndex + _pageSize) > total ? total : startIndex + _pageSize;
          final pageDocs = filteredDocs.sublist(startIndex, endIndex);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  focusNode: _searchFocus,
                  cursorColor: Colors.blue,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm theo tên hoặc loài',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                    _keepSearchFocus();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _rarityFilter,
                      decoration: const InputDecoration(
                        labelText: 'Mức độ hiếm',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'rare', child: Text('Chỉ hiếm')),
                        DropdownMenuItem(value: 'common', child: Text('Không hiếm')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _rarityFilter = v;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: pageDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = pageDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '') as String;
                    final species = (data['species'] ?? '') as String;
                    final rawDescription = (data['description'] ?? '') as String;
                    final description = rawDescription.isEmpty ||
                            rawDescription == 'No description available'
                        ? 'Chưa có mô tả.'
                        : rawDescription;
                    final imageUrl = (data['imageUrl'] ?? '') as String;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnimalDetailScreen(
                                animalId: doc.id,
                                animalData: data,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty
                                          ? name
                                          : '(Không có tên)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (species.isNotEmpty)
                                      Text(
                                        species,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                    ),
                    Text('Trang ${_currentPage + 1} / $totalPages'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (_currentPage + 1) < totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                          : null,
                    ),
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
