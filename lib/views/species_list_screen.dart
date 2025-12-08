import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/species_model.dart';
import '../services/firestore_service.dart';
import 'species_detail_screen.dart';

class SpeciesListScreen extends StatefulWidget {
  final bool isAdmin;

  const SpeciesListScreen({super.key, this.isAdmin = false});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'Tất cả';
  bool _isLoading = false;
  List<Species> _allSpecies = [];
  List<Species> _filteredSpecies = [];

  final List<String> _statusOptions = <String>[
    'Tất cả',
    'CR',
    'EN',
    'VU',
    'NT',
    'LC',
  ];

  @override
  void initState() {
    super.initState();
    _loadSpecies();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _deleteSpecies(Species species) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa loài'),
        content: Text('Bạn có chắc muốn xóa "${species.commonName}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _firestoreService.deleteSpecies(species.id);
    await _loadSpecies();
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã xóa loài thành công' : 'Xóa loài thất bại'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _editSpecies(Species species) async {
    final nameController = TextEditingController(text: species.commonName);
    final scientificController = TextEditingController(text: species.scientificName);
    String statusValue = species.conservationStatus;
    final categoryController = TextEditingController(text: species.category);

    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<Species>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa loài'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên thường gọi',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên thường gọi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: scientificController,
                    decoration: const InputDecoration(
                      labelText: 'Tên khoa học',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên khoa học';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _statusOptions.contains(statusValue)
                        ? statusValue
                        : 'CR',
                    decoration: const InputDecoration(
                      labelText: 'Mức độ nguy cấp',
                    ),
                    items: _statusOptions
                        .where((s) => s != 'Tất cả')
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        statusValue = value;
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Nhóm loài',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final updatedSpecies = species.copyWith(
                  commonName: nameController.text.trim(),
                  scientificName: scientificController.text.trim(),
                  conservationStatus: statusValue.trim(),
                  category: categoryController.text.trim(),
                );
                Navigator.of(context).pop(updatedSpecies);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (updated == null) return;

    setState(() => _isLoading = true);
    final success = await _firestoreService.updateSpecies(updated);
    await _loadSpecies();
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã cập nhật loài thành công' : 'Cập nhật loài thất bại'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies() async {
    setState(() => _isLoading = true);
    final speciesList = await _firestoreService.getAllSpecies();
    setState(() {
      _allSpecies = speciesList;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSpecies = _allSpecies.where((s) {
        final matchesStatus = _selectedStatus == 'Tất cả' ||
            s.conservationStatus.toUpperCase() == _selectedStatus.toUpperCase();
        final matchesQuery = query.isEmpty ||
            s.commonName.toLowerCase().contains(query) ||
            s.scientificName.toLowerCase().contains(query);
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CR':
        return Colors.red;
      case 'EN':
        return Colors.deepOrange;
      case 'VU':
        return Colors.orange;
      case 'NT':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục loài'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên thường/tên khoa học',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: _statusOptions
                          .map((e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedStatus = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredSpecies.isEmpty
                        ? const Center(child: Text('Không có loài nào phù hợp.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 3 / 4,
                            ),
                            itemCount: _filteredSpecies.length,
                            itemBuilder: (context, index) {
                              final species = _filteredSpecies[index];
                              final statusColor =
                                  _statusColor(species.conservationStatus);
                              return InkWell(
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
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              species.conservationStatus,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (widget.isAdmin)
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 18,
                                              ),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editSpecies(species);
                                                } else if (value == 'delete') {
                                                  _deleteSpecies(species);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Chỉnh sửa'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        species.commonName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        species.scientificName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        species.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
