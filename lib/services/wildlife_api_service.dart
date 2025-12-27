import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WildlifeApiService {
  static const String _baseUrl = 'https://api.inaturalist.org/v1';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  GeoPoint? _parseLocation(dynamic raw) {
    try {
      // Case 1: Map with latitude/longitude keys
      if (raw is Map) {
        final lat = raw['latitude'];
        final lng = raw['longitude'];
        double? latDouble;
        double? lngDouble;
        if (lat is num) latDouble = lat.toDouble();
        if (lat is String) latDouble = double.tryParse(lat);
        if (lng is num) lngDouble = lng.toDouble();
        if (lng is String) lngDouble = double.tryParse(lng);
        if (latDouble != null && lngDouble != null) {
          return GeoPoint(latDouble, lngDouble);
        }
      }

      // Case 2: String "lat,lon"
      if (raw is String && raw.contains(',')) {
        final parts = raw.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) return GeoPoint(lat, lng);
        }
      }

      // Case 3: geojson.coordinates [lng, lat]
      if (raw is Map && raw['coordinates'] is List) {
        final coords = raw['coordinates'] as List;
        if (coords.length >= 2) {
          final lng = coords[0];
          final lat = coords[1];
          double? latDouble;
          double? lngDouble;
          if (lat is num) latDouble = lat.toDouble();
          if (lng is num) lngDouble = lng.toDouble();
          if (latDouble != null && lngDouble != null) return GeoPoint(latDouble, lngDouble);
        }
      }
    } catch (e) {
      print('Error parsing location: $e');
    }
    return null;
  }

  // Lấy danh sách động vật theo loài
  Future<List<Map<String, dynamic>>> getAnimalsBySpecies(String species, {int perPage = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/observations?taxon_name=$species&per_page=$perPage&order=desc&order_by=created_at&geo=true'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((item) {
          // Safe parse location; không gán default để tránh sai tọa độ
          GeoPoint? location = _parseLocation(item['location']) ?? _parseLocation(item['geojson']);
          
          return {
            'name': item['taxon']['name'] ?? 'Unknown',
            'species': item['taxon']['name'] ?? 'Unknown',
            'description': item['description'] ?? 'No description available',
            'imageUrl': item['photos']?.isNotEmpty == true 
                ? item['photos'][0]['url']?.replaceFirst('square', 'original') 
                : 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7',
            'isRare': _checkIfRare(item['taxon']['name']),
            if (location != null) 'location': location,
            'observedOn': item['observed_on'] ?? DateTime.now().toIso8601String(),
            'observer': item['user']['login'] ?? 'Unknown',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching animals: $e');
      return [];
    }
  }
  
  // Lấy danh sách quan sát các loài Chim (Aves)
  Future<List<Map<String, dynamic>>> getBirdObservations({int perPage = 50, int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/observations?iconic_taxa=Aves&per_page=$perPage&page=$page&order=desc&order_by=created_at&geo=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((item) {
          // Safe parse location (tương tự getAnimalsBySpecies); không default
          GeoPoint? location = _parseLocation(item['location']) ?? _parseLocation(item['geojson']);

          return {
            'name': item['taxon']?['name'] ?? 'Unknown',
            'species': item['taxon']?['name'] ?? 'Unknown',
            'description': item['description'] ?? 'No description available',
            'imageUrl': item['photos']?.isNotEmpty == true
                ? item['photos'][0]['url']?.replaceFirst('square', 'original')
                : 'https://images.unsplash.com/photo-1470115636492-6d2b56f9146e',
            'isRare': false,
            if (location != null) 'location': location,
            'observedOn': item['observed_on'] ?? DateTime.now().toIso8601String(),
            'observer': item['user']?['login'] ?? 'Unknown',
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching bird observations: $e');
      return [];
    }
  }
  
  // Lấy 90+ động vật quý hiếm Việt Nam và lưu vào Firebase
  Future<void> fetchAndSaveVietnamEndangeredAnimals() async {
    final endangeredSpecies = [
      'Panthera tigris', // Hổ
      'Elephas maximus', // Voi
      'Rhinoceros sondaicus', // Tê giác
      'Bos gaurus', // Bò rừng
      'Muntiacus vuquangensis', // Nai Vu Quang
      'Pygathrix nigripes', // Khỉ đen chân đen
      'Nomascus concolor', // Vượn đen má trắng
      'Catopuma temminckii', // Mèo gấm
      'Cuon alpinus', // Chó sói
      'Arctictis binturong', // Bồ cây
      'Hylobates lar', // Vượn trắng tay
      'Trachypithecus francoisi', // Voọc chà vá chân đen
      'Nycticebus bengalensis', // Cu li lớn
      'Manis javanica', // Tê tê Java
      'Pseudoryx nghetinhensis', // Sao la
      'Cervus eldii', // Nai cà tông
      'Axis porcinus', // Nai lưng đỏ
      'Hylobates gabrieli', // Vượn má đen Bắc Việt Nam
      'Rhinolophus affinis', // Dơi lá nhỏ
      'Lutra lutra', // Rái cá thường
    ];
    
    int totalAnimals = 0;
    
    try {
      for (final species in endangeredSpecies) {
        print('Đang lấy dữ liệu cho: $species');
        final animals = await getAnimalsBySpecies(species, perPage: 5);
        
        // Lưu vào Firebase
        for (final animal in animals) {
          await _db.collection('animals').add({
            ...animal,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'source': 'iNaturalist API',
          });
          totalAnimals++;
        }
        
        // Delay để tránh rate limit
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      print('Đã lấy và lưu $totalAnimals động vật vào Firebase!');
    } catch (e) {
      print('Lỗi khi lấy và lưu động vật: $e');
    }
  }

  // Lấy các quan sát Chim (Aves) và lưu vào collection 'animals'
  Future<int> fetchAndSaveBirdAnimals({int perPage = 40, int maxPages = 2}) async {
    int totalSaved = 0;

    try {
      for (int page = 1; page <= maxPages; page++) {
        print('Đang lấy dữ liệu chim cho trang: $page');
        final animals = await getBirdObservations(perPage: perPage, page: page);

        if (animals.isEmpty) {
          break;
        }

        for (final animal in animals) {
          await _db.collection('animals').add({
            ...animal,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'source': 'iNaturalist API - Birds',
          });
          totalSaved++;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('Đã lấy và lưu $totalSaved cá thể chim vào Firebase (animals)!');
    } catch (e) {
      print('Lỗi khi lấy và lưu chim: $e');
    }

    return totalSaved;
  }
  
  bool _checkIfRare(String? speciesName) {
    if (speciesName == null) return false;
    
    final rareSpecies = [
      'panthera', 'rhinoceros', 'elephas', 'bos gaurus', 
      'muntiacus vuquangensis', 'pygathrix', 'nomascus',
      'catopuma', 'cuon', 'arctictis', 'hylobates',
      'trachypithecus', 'nycticebus', 'manis', 'pseudoryx'
    ];
    
    return rareSpecies.any((rare) => 
        speciesName.toLowerCase().contains(rare));
  }
}
