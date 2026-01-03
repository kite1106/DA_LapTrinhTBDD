import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/news_controller.dart';
import '../models/news_model.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _authorController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();

  final NewsController _newsController = NewsController();

  String _category = 'bảo tồn';
  bool _isPublished = true;
  DateTime _publishDate = DateTime.now();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    _authorController.text = email;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    _authorController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickPublishDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _publishDate = picked);
    }
  }

  List<String> _parseTags(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const <String>[];
    return trimmed
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _addNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final content = _contentController.text.trim();
      final summary = _summaryController.text.trim().isNotEmpty
          ? _summaryController.text.trim()
          : (content.length > 180 ? '${content.substring(0, 180)}...' : content);

      final news = News(
        id: '',
        title: _titleController.text.trim(),
        content: content,
        summary: summary,
        link: _linkController.text.trim(),
        author: _authorController.text.trim().isNotEmpty ? _authorController.text.trim() : 'Admin',
        category: _category,
        imageUrl: _imageUrlController.text.trim(),
        tags: _parseTags(_tagsController.text),
        publishDate: _publishDate,
        createdAt: now,
        updatedAt: now,
        isPublished: _isPublished,
        viewCount: 0,
      );

      final id = await _newsController.addNews(news);
      if (id.isEmpty) {
        throw Exception('Không tạo được bài báo');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm bài báo thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00A86B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm bài báo'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _SectionCard(
                  title: 'Thông tin bài báo',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'bảo tồn', child: Text('bảo tồn')),
                          DropdownMenuItem(value: 'nghiên cứu', child: Text('nghiên cứu')),
                          DropdownMenuItem(value: 'sự kiện', child: Text('sự kiện')),
                          DropdownMenuItem(value: 'cứu hộ', child: Text('cứu hộ')),
                          DropdownMenuItem(value: 'vi phạm', child: Text('vi phạm')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _summaryController,
                        decoration: const InputDecoration(
                          labelText: 'Tóm tắt (có thể bỏ trống)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Vui lòng nhập nội dung';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Nguồn & hiển thị',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          labelText: 'Link bài gốc (có thể bỏ trống)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL ảnh (có thể bỏ trống)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.image),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          labelText: 'Tác giả/Nguồn',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (phân cách bằng dấu phẩy)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickPublishDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày đăng',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${_publishDate.day}/${_publishDate.month}/${_publishDate.year}'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        value: _isPublished,
                        onChanged: (v) => setState(() => _isPublished = v),
                        title: const Text('Xuất bản'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addNews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Thêm bài báo', style: TextStyle(fontWeight: FontWeight.w800)),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
