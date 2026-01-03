import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

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
    throw UnsupportedError(
      'News RSS import has been removed. You already manage news data on Firebase Firestore. query=$query collection=$collection maxItems=$maxItems',
    );
  }
}
