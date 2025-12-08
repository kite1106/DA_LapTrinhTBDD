import 'package:flutter/material.dart';
import '../controllers/animal_controller.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  bool _isRare = false;
  bool _isLoading = false;
  
  final AnimalController _animalController = AnimalController();

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

  Future<void> _addAnimal() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());

      if (lat == null || lng == null) {
        throw Exception('Vĩ độ / kinh độ không hợp lệ');
      }

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw Exception('Vĩ độ phải từ -90 đến 90, kinh độ từ -180 đến 180');
      }

      await _animalController.addAnimal(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        isRare: _isRare,
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm động vật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Động Vật'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên động vật',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập tên';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _speciesController,
                  decoration: const InputDecoration(
                    labelText: 'Loài',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập loài';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập mô tả';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL hình ảnh',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập URL hình ảnh';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Vĩ độ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập vĩ độ';
                          }
                          final v = double.tryParse(value.trim());
                          if (v == null) {
                            return 'Vĩ độ phải là số';
                          }
                          if (v < -90 || v > 90) {
                            return 'Vĩ độ phải từ -90 đến 90';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(
                          labelText: 'Kinh độ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập kinh độ';
                          }
                          final v = double.tryParse(value.trim());
                          if (v == null) {
                            return 'Kinh độ phải là số';
                          }
                          if (v < -180 || v > 180) {
                            return 'Kinh độ phải từ -180 đến 180';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Động vật quý hiếm'),
                  value: _isRare,
                  onChanged: (value) => setState(() => _isRare = value ?? false),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addAnimal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Thêm Động Vật'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}