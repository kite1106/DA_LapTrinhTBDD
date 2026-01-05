import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_model.dart';
import 'news_detail_screen.dart';
import 'edit_news_screen.dart';

class NewsScreen extends StatelessWidget {
  final bool adminMode;

  const NewsScreen({super.key, this.adminMode = false});

  Stream<List<News>> _newsStream() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('news');
    if (!adminMode) {
      q = q.where('isPublished', isEqualTo: true);
    }
    return q.orderBy('publishDate', descending: true).snapshots().map(
          (snap) => snap.docs.map((doc) => News.fromFirestore(doc.data(), doc.id)).toList(),
        );
  }

  Future<void> _togglePublish(BuildContext context, News n) async {
    await FirebaseFirestore.instance.collection('news').doc(n.id).update({
      'isPublished': !n.isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF00A86B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin tức bảo tồn'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: StreamBuilder<List<News>>(
        stream: _newsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải tin: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có tin tức.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final news = items[index];
              final title = news.cleanTitle;
              final summary = news.cleanSummary;
              final source = news.sourceDomain.isNotEmpty ? news.sourceDomain : news.author;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(news: news, adminMode: adminMode),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NewsThumbnail(imageUrl: news.imageUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty ? title : news.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (adminMode) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: (news.isPublished ? const Color(0xFFE7F5EF) : const Color(0xFFFFF7ED)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      news.isPublished ? 'PUBLISHED' : 'DRAFT',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: news.isPublished ? primary : const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => EditNewsScreen(news: news)),
                                        );
                                      } else if (v == 'toggle_publish') {
                                        await _togglePublish(context, news);
                                      } else if (v == 'delete') {
                                        await _delete(context, news);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                      PopupMenuItem(
                                        value: 'toggle_publish',
                                        child: Text(news.isPublished ? 'Chuyển về bản nháp' : 'Xuất bản'),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              summary.isNotEmpty ? summary : 'Không có tóm tắt.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A4A55), height: 1.35),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  news.getFormattedDate(),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                const SizedBox(width: 10),
                                if (source.isNotEmpty) ...[
                                  Container(
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: const Color(0xFFE7F5EF),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      source,
                                      style: TextStyle(fontSize: 11.5, color: primary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (news.link.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: primary),
                                  onPressed: () => _openLink(context, news.link),
                                  icon: Icon(Icons.open_in_new, size: 18, color: primary),
                                  label: const Text(
                                    'Mở bài gốc',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _openLink(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không mở được bài gốc')));
      }
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không mở được bài gốc')));
    }
  }
}

class _NewsThumbnail extends StatelessWidget {
  final String imageUrl;

  const _NewsThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        image: imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
      ),
      child: imageUrl.isEmpty
          ? Icon(Icons.image_not_supported, color: Colors.grey.shade500)
          : null,
    );
  }
}
