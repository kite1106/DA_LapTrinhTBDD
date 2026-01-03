import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import 'edit_news_screen.dart';

class AdminNewsManagementScreen extends StatefulWidget {
  const AdminNewsManagementScreen({super.key});

  @override
  State<AdminNewsManagementScreen> createState() => _AdminNewsManagementScreenState();
}

class _AdminNewsManagementScreenState extends State<AdminNewsManagementScreen> {
  static const Color _primary = Color(0xFF00A86B);
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _match(News n, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return n.id.toLowerCase().contains(s) || n.title.toLowerCase().contains(s) || n.author.toLowerCase().contains(s);
  }

  Future<void> _togglePublish(BuildContext context, News n) async {
    await FirebaseFirestore.instance.collection('news').doc(n.id).update({
      'isPublished': !n.isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!n.isPublished ? 'Đã xuất bản' : 'Đã chuyển về bản nháp')),
      );
    }
  }

  Future<void> _delete(BuildContext context, News n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bài báo'),
        content: Text('Xóa "${n.cleanTitle.isNotEmpty ? n.cleanTitle : n.title}"?'),
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
    await FirebaseFirestore.instance.collection('news').doc(n.id).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bài báo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Quản lý bài báo'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
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
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tiêu đề / tác giả / id',
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
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('news').orderBy('publishDate', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải bài báo: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final items = docs
                    .map((d) => News.fromFirestore(d.data() as Map<String, dynamic>, d.id))
                    .where((n) => _match(n, _search.text))
                    .toList();

                if (items.isEmpty) {
                  return const Center(child: Text('Không có bài báo phù hợp.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final title = n.cleanTitle.isNotEmpty ? n.cleanTitle : n.title;

                    return Container(
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: (n.isPublished ? _primary : const Color(0xFFF59E0B)).withOpacity(0.14),
                          foregroundColor: n.isPublished ? _primary : const Color(0xFFF59E0B),
                          child: Icon(n.isPublished ? Icons.public : Icons.edit_note),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title.isNotEmpty ? title : 'Bài báo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (n.isPublished ? _primary : const Color(0xFFF59E0B)).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: (n.isPublished ? _primary : const Color(0xFFF59E0B)).withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                n.isPublished ? 'PUBLISHED' : 'DRAFT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: n.isPublished ? _primary : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              n.author.isNotEmpty ? n.author : '(Chưa có tác giả)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${n.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black38, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              final ok = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => EditNewsScreen(news: n)),
                              );
                              if (ok == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật')));
                              }
                            } else if (v == 'toggle_publish' && context.mounted) {
                              await _togglePublish(context, n);
                            } else if (v == 'delete' && context.mounted) {
                              await _delete(context, n);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(
                              value: 'toggle_publish',
                              child: Text(n.isPublished ? 'Chuyển về bản nháp' : 'Xuất bản'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
