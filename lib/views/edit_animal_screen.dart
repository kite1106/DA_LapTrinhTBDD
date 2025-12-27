import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/animal_service.dart';

class EditAnimalScreen extends StatefulWidget {
  final String animalId;
  final Map<String, dynamic> initialData;
  final double? fallbackLat;
  final double? fallbackLng;

  const EditAnimalScreen({
    super.key,
    required this.animalId,
    required this.initialData,
    this.fallbackLat,
    this.fallbackLng,
  });

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  bool _isRare = false;
  bool _submitting = false;

  final AnimalService _animalService = AnimalService();

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController = TextEditingController(text: (data['name'] ?? '').toString());
    _speciesController = TextEditingController(text: (data['species'] ?? '').toString());
    _descriptionController = TextEditingController(text: (data['description'] ?? '').toString());
    _imageUrlController = TextEditingController(text: (data['imageUrl'] ?? '').toString());
    _isRare = data['isRare'] == true;

    final GeoPoint? loc = data['location'] as GeoPoint?;
    final double? lat = loc?.latitude ?? widget.fallbackLat;
    final double? lng = loc?.longitude ?? widget.fallbackLng;
    _latController = TextEditingController(text: lat != null ? lat.toStringAsFixed(6) : '');
    _lngController = TextEditingController(text: lng != null ? lng.toStringAsFixed(6) : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());

      await _animalService.updateAnimal(
        id: widget.animalId,
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        isRare: _isRare,
        latitude: lat ?? 0,
        longitude: lng ?? 0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thay đổi')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa động vật'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(labelText: 'Loài/Species'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập loài' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isRare,
                onChanged: (v) => setState(() => _isRare = v),
                title: const Text('Hiếm (isRare)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_submitting ? 'Đang lưu...' : 'Lưu thay đổi'),
                  onPressed: _submitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
