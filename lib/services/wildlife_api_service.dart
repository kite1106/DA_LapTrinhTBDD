import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WildlifeApiService {
  static const String _baseUrl = 'https://api.inaturalist.org/v1';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Lấy danh sách động vật theo loài
  Future<List<Map<String, dynamic>>> getAnimalsBySpecies(String species, {int perPage = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/observations?taxon_name=$species&per_page=$perPage&order=desc&order_by=created_at'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((item) {
          // Safe parse location
          GeoPoint location = const GeoPoint(10.8231, 106.6297);
          if (item['location'] != null && item['location'] is Map) {
            try {
              final locationData = item['location'] as Map;
              final lat = locationData['latitude'];
              final lng = locationData['longitude'];
              
              double latDouble = 10.8231;
              double lngDouble = 106.6297;
              
              // Handle different types safely
              if (lat != null) {
                if (lat is num) {
                  latDouble = lat.toDouble();
                } else if (lat is String) {
                  latDouble = double.tryParse(lat) ?? 10.8231;
                }
              }
              if (lng != null) {
                if (lng is num) {
                  lngDouble = lng.toDouble();
                } else if (lng is String) {
                  lngDouble = double.tryParse(lng) ?? 106.6297;
                }
              }
              
              location = GeoPoint(latDouble, lngDouble);
            } catch (e) {
              print('Error parsing location: $e');
              // Use default location
            }
          }
          
          return {
            'name': item['taxon']['name'] ?? 'Unknown',
            'species': item['taxon']['name'] ?? 'Unknown',
            'description': item['description'] ?? 'No description available',
            'imageUrl': item['photos']?.isNotEmpty == true 
                ? item['photos'][0]['url']?.replaceFirst('square', 'original') 
                : 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7',
            'isRare': _checkIfRare(item['taxon']['name']),
            'location': location,
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
