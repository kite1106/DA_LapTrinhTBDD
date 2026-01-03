import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_model.dart';
import '../providers/favorites_provider.dart';
import 'edit_news_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;
  final bool adminMode;

  const NewsDetailScreen({super.key, required this.news, this.adminMode = false});

  String _sourceDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isNewsFavorite(news.id);
    final domain = news.sourceDomain.isNotEmpty ? news.sourceDomain : _sourceDomain(news.link);
    final bodyText = news.cleanContent.isNotEmpty ? news.cleanContent : 'Không có nội dung.';
    final primary = const Color(0xFF00A86B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tin tức'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: isFav ? 'Bỏ yêu thích' : 'Yêu thích',
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.pinkAccent : Colors.white,
            ),
            onPressed: () => favorites.toggleNews(news.id),
          ),
          if (adminMode)
            IconButton(
              tooltip: 'Sửa',
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditNewsScreen(news: news)),
                );
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  news.imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderCover(),
                ),
              )
            else
              _placeholderCover(),
            const SizedBox(height: 16),
            Text(
              news.cleanTitle.isNotEmpty ? news.cleanTitle : news.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  news.getFormattedDate(),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 10),
                if (news.author.isNotEmpty)
                  Text(
                    '• ${news.author}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                if (domain.isNotEmpty)
                  Text(
                    ' • $domain',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
              ],
            ),
            if (news.link.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(news.link);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Không mở được bài gốc')));
                    }
                  }
                },
                icon: Icon(Icons.link, color: primary),
                label: Text('Mở bài gốc', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: primary),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                bodyText,
                style: const TextStyle(fontSize: 15.5, height: 1.6, color: Color(0xFF2E2E38)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F3EE), Color(0xFFDDE9F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade500, size: 36),
    );
  }
}
