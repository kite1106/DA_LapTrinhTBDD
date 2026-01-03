import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/animal_controller.dart';
import '../providers/favorites_provider.dart';
import 'animal_detail_screen.dart';
import 'edit_animal_screen.dart';

class AnimalListScreen extends StatefulWidget {
  final bool adminMode;

  const AnimalListScreen({super.key, this.adminMode = false});

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
  String _rarityFilter = 'all'; // all | rare | common | favorite
  static const Color _primary = Color(0xFF00A86B);

  Future<void> _deleteAnimal(BuildContext context, String animalId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa động vật'),
        content: Text('Xóa "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseFirestore.instance.collection('animals').doc(animalId).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa động vật')));
    }
  }

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
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Danh sách động vật (chim)'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
            if (_rarityFilter == 'favorite' && !favorites.isAnimalFavorite(doc.id)) return false;
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        focusNode: _searchFocus,
                        cursorColor: _primary,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên hoặc loài',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primary, width: 1.4),
                          ),
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 0;
                          });
                          _keepSearchFocus();
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _rarityFilter,
                        decoration: InputDecoration(
                          labelText: 'Mức độ hiếm',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'rare', child: Text('Chỉ hiếm')),
                          DropdownMenuItem(value: 'common', child: Text('Không hiếm')),
                          DropdownMenuItem(value: 'favorite', child: Text('Yêu thích')),
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
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: pageDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = pageDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '') as String;
                    final species = (data['species'] ?? '') as String;
                    final isRare = data['isRare'] == true;
                    final rawDescription = (data['description'] ?? '') as String;
                    final description = rawDescription.isEmpty ||
                            rawDescription == 'No description available'
                        ? 'Chưa có mô tả.'
                        : rawDescription;
                    final imageUrl = (data['imageUrl'] ?? '') as String;
                    final isFav = favorites.isAnimalFavorite(doc.id);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                                borderRadius: BorderRadius.circular(12),
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name.isNotEmpty ? name : '(Không có tên)',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1F1F28),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(999),
                                          onTap: () => favorites.toggleAnimal(doc.id),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Icon(
                                              isFav ? Icons.favorite : Icons.favorite_border,
                                              size: 18,
                                              color: isFav ? Colors.pinkAccent : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        if (isRare)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'QUÝ HIẾM',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        if (widget.adminMode)
                                          PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              if (v == 'edit') {
                                                final GeoPoint? loc = data['location'] as GeoPoint?;
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => EditAnimalScreen(
                                                      animalId: doc.id,
                                                      initialData: data,
                                                      fallbackLat: loc?.latitude,
                                                      fallbackLng: loc?.longitude,
                                                    ),
                                                  ),
                                                );
                                              } else if (v == 'delete' && context.mounted) {
                                                await _deleteAnimal(context, doc.id, name.isNotEmpty ? name : doc.id);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                              PopupMenuDivider(),
                                              PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                            ],
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '',
                                      style: const TextStyle(fontSize: 0),
                                    ),
                                    const SizedBox(height: 6),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Trang ${_currentPage + 1} / $totalPages',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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
