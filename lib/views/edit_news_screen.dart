import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../services/news_service.dart';

class EditNewsScreen extends StatefulWidget {
  final News news;

  const EditNewsScreen({super.key, required this.news});

  @override
  State<EditNewsScreen> createState() => _EditNewsScreenState();
}

class _EditNewsScreenState extends State<EditNewsScreen> {
  static const Color _primary = Color(0xFF00A86B);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final TextEditingController _linkController;
  late final TextEditingController _authorController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _tagsController;

  late String _category;
  late bool _isPublished;
  late DateTime _publishDate;

  bool _isLoading = false;
  final NewsService _newsService = NewsService();

  @override
  void initState() {
    super.initState();
    final n = widget.news;

    _titleController = TextEditingController(text: n.title);
    _summaryController = TextEditingController(text: n.summary);
    _contentController = TextEditingController(text: n.content);
    _linkController = TextEditingController(text: n.link);
    _authorController = TextEditingController(text: n.author.isNotEmpty ? n.author : (FirebaseAuth.instance.currentUser?.email ?? ''));
    _imageUrlController = TextEditingController(text: n.imageUrl);
    _tagsController = TextEditingController(text: n.tags.join(', '));

    _category = n.category.isNotEmpty ? n.category : 'bảo tồn';
    _isPublished = n.isPublished;
    _publishDate = n.publishDate;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final content = _contentController.text.trim();
      final summary = _summaryController.text.trim().isNotEmpty
          ? _summaryController.text.trim()
          : (content.length > 180 ? '${content.substring(0, 180)}...' : content);

      final updated = News(
        id: widget.news.id,
        title: _titleController.text.trim(),
        content: content,
        summary: summary,
        link: _linkController.text.trim(),
        author: _authorController.text.trim().isNotEmpty ? _authorController.text.trim() : 'Admin',
        category: _category,
        imageUrl: _imageUrlController.text.trim(),
        tags: _parseTags(_tagsController.text),
        publishDate: _publishDate,
        createdAt: widget.news.createdAt,
        updatedAt: now,
        isPublished: _isPublished,
        viewCount: widget.news.viewCount,
      );

      final ok = await _newsService.updateNews(updated);
      if (!ok) {
        throw Exception('Không lưu được bài báo');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật bài báo'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Tóm tắt'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Nội dung'),
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập nội dung' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'Link (tuỳ chọn)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Tác giả'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'bảo tồn', child: Text('Bảo tồn')),
                  DropdownMenuItem(value: 'nghiên cứu', child: Text('Nghiên cứu')),
                  DropdownMenuItem(value: 'cứu hộ', child: Text('Cứu hộ')),
                  DropdownMenuItem(value: 'sự kiện', child: Text('Sự kiện')),
                  DropdownMenuItem(value: 'vi phạm', child: Text('Vi phạm')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'bảo tồn'),
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (cách nhau bởi dấu phẩy)'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                title: const Text('Xuất bản'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày xuất bản'),
                subtitle: Text('${_publishDate.day}/${_publishDate.month}/${_publishDate.year}'),
                trailing: TextButton(
                  onPressed: _pickPublishDate,
                  child: const Text('Chọn'),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Đang lưu...' : 'Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
