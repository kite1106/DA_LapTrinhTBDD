import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_model.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

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
    final domain = _sourceDomain(news.link);
    final bodyText = news.content.isNotEmpty ? news.content : news.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tin tức'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngày: ${news.getFormattedDate()} • ${news.author.isNotEmpty ? news.author : "Nguồn tổng hợp"}${domain.isNotEmpty ? " • $domain" : ""}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  if (news.link.isNotEmpty)
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
                      icon: const Icon(Icons.link),
                      label: const Text('Mở bài gốc'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (news.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    news.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              if (news.imageUrl.isNotEmpty) const SizedBox(height: 16),
              SelectableText(
                bodyText.isNotEmpty ? bodyText : 'Không có nội dung.',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
