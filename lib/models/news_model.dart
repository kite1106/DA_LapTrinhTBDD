import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String author;
  final String category;
  final String imageUrl;
  final List<String> tags;
  final DateTime publishDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final int viewCount;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.author,
    required this.category,
    required this.imageUrl,
    required this.tags,
    required this.publishDate,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = true,
    this.viewCount = 0,
  });

  factory News.fromFirestore(Map<String, dynamic> data, String documentId) {
    return News(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      summary: data['summary'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      publishDate: (data['publishDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] ?? true,
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'author': author,
      'category': category,
      'imageUrl': imageUrl,
      'tags': tags,
      'publishDate': publishDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublished': isPublished,
      'viewCount': viewCount,
    };
  }

  String getCategoryColor() {
    switch (category.toLowerCase()) {
      case 'vi phạm':
        return '#FF0000';
      case 'cứu hộ':
        return '#008000';
      case 'sự kiện':
        return '#0000FF';
      case 'nghiên cứu':
        return '#800080';
      case 'bảo tồn':
        return '#FF8C00';
      default:
        return '#808080';
    }
  }

  String getFormattedDate() {
    return '${publishDate.day}/${publishDate.month}/${publishDate.year}';
  }
}
