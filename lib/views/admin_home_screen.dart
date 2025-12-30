import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';
import '../data/bird_repository.dart';
import '../services/animal_service.dart';
import '../services/news_rss_service.dart';
import '../services/wildlife_api_service.dart';
import '../views/add_animal_screen.dart';
import '../views/animal_list_screen.dart';
import '../views/image_classifier_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();
    final authService = AuthService();
    final user = authService.currentUser;
    final AnimalService animalService = AnimalService();
    final WildlifeApiService apiService = WildlifeApiService();
    final NewsRssService newsRssService = NewsRssService();
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Admin'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.signOut();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade50,
              Colors.indigo.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.indigo.shade200,
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào Admin!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Admin',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Hành động nhanh',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 4 / 3,
                  ),
                  children: [
                    _AdminActionCard(
                      icon: Icons.view_list,
                      title: 'Danh sách động vật (chim)',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AnimalListScreen()),
                        );
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.pets,
                      title: 'Thêm động vật',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddAnimalScreen()),
                        );
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.camera,
                      title: 'Nhận diện ảnh',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ImageClassifierScreen()),
                        );
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.analytics,
                      title: 'Thống kê (placeholder)',
                      color: Colors.indigo,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chức năng thống kê sẽ được bổ sung.'),
                          ),
                        );
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.cloud_download,
                      title: 'Lấy dữ liệu chim (API)',
                      color: Colors.purple,
                      onTap: () async {
                        final total = await apiService.fetchAndSaveBirdAnimals(
                          perPage: 40,
                          maxPages: 2,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã lưu khoảng $total cá thể chim vào Firebase (animals)'),
                              backgroundColor: Colors.purple,
                            ),
                          );
                        }
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.rss_feed,
                      title: 'Lấy tin Google News',
                      color: Colors.orange,
                      onTap: () async {
                        try {
                          final total = await newsRssService.fetchAndSave(
                            query: 'bảo tồn động vật',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã lưu $total bài tin vào news'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi lấy RSS: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.cloud_upload,
                      title: 'Đẩy 11 chim tĩnh',
                      color: Colors.green,
                      onTap: () async {
                        int saved = 0;
                        for (final entry in birdRepository.entries) {
                          final info = entry.value;
                          await firestore.collection('animals').add({
                            'name': info.commonName,
                            'species': entry.key,
                            'description': info.description,
                            'imageUrl': info.imageUrl ?? '',
                            'isRare': false,
                            'location': GeoPoint(info.latitude, info.longitude),
                            'observedOn': info.observedAt.toIso8601String(),
                            'observer': info.observer,
                            'source': 'Static bird_repository',
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          saved++;
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã đẩy $saved loài từ bird_repository vào animals'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
