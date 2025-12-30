import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart' as xml;

import '../models/news_model.dart';

class NewsRssService {
  NewsRssService({
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  final FirebaseFirestore _db;
  final http.Client _client;

  /// Fetch Google News RSS with a query, parse, and upsert to Firestore.
  /// Returns number of items written.
  Future<int> fetchAndSave({
    required String query,
    String collection = 'news',
    int maxItems = 5,
  }) async {
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse('https://news.google.com/rss/search?q=$encoded&hl=vi&gl=VN&ceid=VN:vi');

    final resp = await _client.get(url);
    if (resp.statusCode != 200) {
      throw Exception('RSS request failed: ${resp.statusCode}');
    }

    final document = xml.XmlDocument.parse(resp.body);
    final items = document.findAllElements('item');
    final parsedItems = <_ParsedItem>[];

    for (final item in items) {
      final title = _text(item, 'title');
      final link = _text(item, 'link');
      final description = _text(item, 'description');
      final mediaUrl = _mediaUrl(item);
      final pubDate = _text(item, 'pubDate');

      if (title.isEmpty || link.isEmpty) continue;

      final id = _slugFromLink(link);
      final publishDate = _tryParseDate(pubDate) ?? DateTime.now();

      parsedItems.add(
        _ParsedItem(
          id: id,
          title: title,
          link: link,
          description: description,
          mediaUrl: mediaUrl,
          publishDate: publishDate,
        ),
      );
    }

    // Sort newest first and take top N.
    parsedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));

    var count = 0;
    for (final item in parsedItems.take(maxItems)) {
      final cleanDesc = _stripHtml(item.description);

      final fullText = await _fetchFullContent(item.link);
      final news = News(
        id: item.id,
        title: item.title,
        content: fullText.isNotEmpty ? fullText : cleanDesc,
        summary: cleanDesc,
        link: item.link,
        author: 'Google News',
        category: 'bảo tồn',
        imageUrl: _firstNonEmpty([
          item.mediaUrl,
          _extractImage(item.description),
        ]),
        tags: const [],
        publishDate: item.publishDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: true,
        viewCount: 0,
      );

      await _db.collection(collection).doc(item.id).set(news.toFirestore(), SetOptions(merge: true));
      count++;
    }

    return count;
  }

  String _text(xml.XmlElement parent, String name) {
    final found = parent.findElements(name);
    if (found.isEmpty) return '';
    return found.first.text.trim();
  }

  String _slugFromLink(String link) {
    final hash = base64Url.encode(utf8.encode(link)).replaceAll('=', '');
    return 'rss_$hash';
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Very naive image extraction from description HTML (if present).
  String _extractImage(String desc) {
    final regex = RegExp(r'src="([^"]+)"');
    final match = regex.firstMatch(desc);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? '';
    }
    return '';
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  /// Try media:content or enclosure url attributes.
  String _mediaUrl(xml.XmlElement item) {
    final media = item.findElements('media:content');
    if (media.isNotEmpty) {
      final url = media.first.getAttribute('url');
      if (_isValidUrl(url)) return url!;
    }
    final enclosure = item.findElements('enclosure');
    if (enclosure.isNotEmpty) {
      final url = enclosure.first.getAttribute('url');
      if (_isValidUrl(url)) return url!;
    }
    return '';
  }

  String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final trimmed = v?.trim() ?? '';
      if (_isValidUrl(trimmed)) return trimmed;
    }
    return '';
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Future<String> _fetchFullContent(String link) async {
    if (!_isValidUrl(link)) return '';
    try {
      final resp = await _client.get(Uri.parse(link)).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return '';
      final doc = html_parser.parse(resp.body);

      // Prefer article paragraphs, fallback to all paragraphs.
      final article = doc.querySelector('article');
      final nodes = (article ?? doc).querySelectorAll('p');
      if (nodes.isEmpty) return '';

      final buffer = StringBuffer();
      for (final p in nodes) {
        final text = p.text.trim();
        if (text.isEmpty) continue;
        buffer.writeln(text);
      }

      final result = buffer.toString().trim();
      // Avoid extremely long texts; keep first ~4000 chars
      if (result.length > 4000) {
        return result.substring(0, 4000);
      }
      return result;
    } catch (_) {
      return '';
    }
  }
}

class _ParsedItem {
  final String id;
  final String title;
  final String link;
  final String description;
  final String mediaUrl;
  final DateTime publishDate;

  _ParsedItem({
    required this.id,
    required this.title,
    required this.link,
    required this.description,
    required this.mediaUrl,
    required this.publishDate,
  });
}
