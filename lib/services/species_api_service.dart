import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Service dùng để lấy danh sách loài từ iNaturalist và (tuỳ chọn) lưu vào Firestore.
///
/// Đây là service bổ sung, song song với WildlifeApiService hiện có.
class SpeciesApiService {
  static const String _baseUrl = 'https://api.inaturalist.org/v1';

  final FirebaseFirestore _db = FirebaseFirestore.instance;


// ham lay 1 trang loai chim
  Future<List<Map<String, dynamic>>> fetchSpeciesByQuery(
    String query, {
    int perPage = 30,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/taxa?q=$query&rank=species&per_page=$perPage',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi gọi iNaturalist: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? [];

    // Chuẩn hoá về dạng Map để dễ lưu vào Firestore/species
    return results.map<Map<String, dynamic>>((item) {
      final taxon = item as Map<String, dynamic>;
      final String scientificName = (taxon['name'] ?? '') as String;
      final String commonName =
          (taxon['preferred_common_name'] ?? taxon['english_common_name'] ?? '')
              as String;
      final String category = (taxon['iconic_taxon_name'] ?? '') as String; // Mammalia, Aves...

      // Ảnh minh hoạ (nếu có)
      String imageUrl = '';
      if (taxon['default_photo'] is Map) {
        final photo = taxon['default_photo'] as Map;
        imageUrl = (photo['medium_url'] ?? photo['url'] ?? '') as String;
      }

      return {
        'commonName': commonName,
        'scientificName': scientificName,
        'category': category,
        'conservationStatus': '', // iNaturalist không cung cấp trực tiếp CR/EN/VU ở đây
        'description': '',
        'distribution': '',
        'population': '',
        'threats': '',
        'conservationActions': '',
        'habitat': '',
        'imageUrl': imageUrl,
        'locations': <String>[],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'isFavorite': false,
      };
    }).toList();
  }

  /// Lấy loài từ iNaturalist theo [query] và lưu vào collection `species` trên Firestore.
  ///
  /// Dùng cho admin khi muốn seed dữ liệu nhanh.
  Future<int> fetchAndSaveSpeciesToFirestore(String query, {int perPage = 30}) async {
    final speciesList = await fetchSpeciesByQuery(query, perPage: perPage);

    int savedCount = 0;
    for (final sp in speciesList) {
      final scientificName = (sp['scientificName'] as String?)?.trim() ?? '';
      if (scientificName.isEmpty) {
        continue;
      }

      final docId = scientificName.toLowerCase().replaceAll(' ', '_');

      await _db.collection('species').doc(docId).set({
        ...sp,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      savedCount++;
    }

    return savedCount;
  }

  /// ================== CHỈ LẤY CÁC LOÀI CHIM (AVES) ==================

  /// Lấy danh sách loài thuộc nhóm Chim (Aves) từ iNaturalist.
  ///
  /// Sử dụng iconic_taxa=Aves và rank=species.
  Future<List<Map<String, dynamic>>> fetchBirdSpecies({
    int perPage = 30,
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/taxa?iconic_taxa=Aves&rank=species&per_page=$perPage&page=$page',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi gọi iNaturalist (Aves): ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? [];

    return results.map<Map<String, dynamic>>((item) {
      final taxon = item as Map<String, dynamic>;
      final String scientificName = (taxon['name'] ?? '') as String;
      final String commonName =
          (taxon['preferred_common_name'] ?? taxon['english_common_name'] ?? '')
              as String;

      String imageUrl = '';
      if (taxon['default_photo'] is Map) {
        final photo = taxon['default_photo'] as Map;
        imageUrl = (photo['medium_url'] ?? photo['url'] ?? '') as String;
      }

      return {
        'commonName': commonName,
        'scientificName': scientificName,
        'category': 'Bird',
        'conservationStatus': '',
        'description': '',
        'distribution': '',
        'population': '',
        'threats': '',
        'conservationActions': '',
        'habitat': '',
        'imageUrl': imageUrl,
        'locations': <String>[],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'isFavorite': false,
      };
    }).toList();
  }

  /// Lấy một trang các loài Chim (Aves) và lưu vào collection `species`.
  /// Trả về số lượng document đã lưu.
  Future<int> fetchAndSaveBirdSpeciesToFirestore({
    int perPage = 30,
    int page = 1,
  }) async {
    final speciesList = await fetchBirdSpecies(perPage: perPage, page: page);

    int savedCount = 0;
    for (final sp in speciesList) {
      final scientificName = (sp['scientificName'] as String?)?.trim() ?? '';
      if (scientificName.isEmpty) {
        continue;
      }

      final docId = scientificName.toLowerCase().replaceAll(' ', '_');

      await _db.collection('species').doc(docId).set({
        ...sp,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      savedCount++;
    }

    return savedCount;
  }

  /// Lấy nhiều trang loài Chim (Aves) và lưu vào Firestore.
  /// [perPage]: số loài mỗi trang, [maxPages]: số trang tối đa.
  /// Trả về tổng số document đã lưu.
  Future<int> importManyBirdSpecies({
    int perPage = 30,
    int maxPages = 5,
  }) async {
    int totalSaved = 0;

    for (int page = 1; page <= maxPages; page++) {
      final saved = await fetchAndSaveBirdSpeciesToFirestore(
        perPage: perPage,
        page: page,
      );

      if (saved == 0) {
        // Không còn dữ liệu ở các trang sau
        break;
      }

      totalSaved += saved;

      // Nghỉ một chút để tránh bị giới hạn tần suất gọi API
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return totalSaved;
  }
}