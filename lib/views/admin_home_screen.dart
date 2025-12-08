import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/auth_controller.dart';
import '../services/seed_data_service.dart';
import '../services/wildlife_api_service.dart';
import 'add_animal_screen.dart';
import 'species_list_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();
    final user = authController.currentUser;
    final seedData = SeedData();
    final apiService = WildlifeApiService();

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
                      icon: Icons.list_alt,
                      title: 'Danh mục loài',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SpeciesListScreen(isAdmin: true),
                          ),
                        );
                      },
                    ),
                    _AdminActionCard(
                      icon: Icons.dataset,
                      title: 'Thêm dữ liệu mẫu',
                      color: Colors.orange,
                      onTap: () async {
                        await seedData.addAllSampleData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm tất cả dữ liệu mẫu thành công!'),
                            backgroundColor: Colors.green,
                          ),
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
                      icon: Icons.cloud_download,
                      title: 'Lấy dữ liệu từ API',
                      color: Colors.purple,
                      onTap: () async {
                        await apiService.fetchAndSaveVietnamEndangeredAnimals();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã lấy và lưu 90+ động vật vào Firebase!'),
                            backgroundColor: Colors.blue,
                          ),
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
