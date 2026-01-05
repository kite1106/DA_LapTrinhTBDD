import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  static const Color _primary = Color(0xFF00A86B);
  bool _loading = true;
  String? _error;
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _count(Query query) async {
    try {
      final agg = await query.count().get();
      return agg.count ?? 0;
    } catch (_) {
      final snap = await query.get();
      return snap.size;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final db = FirebaseFirestore.instance;

    try {
      final results = await Future.wait<int>([
        _count(db.collection('users')),
        _count(db.collection('users').where('isAdmin', isEqualTo: true)),
        _count(db.collection('animals').where('isRare', isEqualTo: true)),
        _count(db.collection('animals').where('isRare', isEqualTo: false)),
        _count(db.collection('news')),
      ]);

      final totalUsers = results[0];
      final totalAdmins = results[1];
      final totalRareAnimals = results[2];
      final totalCommonAnimals = results[3];
      final totalNews = results[4];

      setState(() {
        _counts = {
          'users_total': totalUsers,
          'users_admin': totalAdmins,
          'animals_rare': totalRareAnimals,
          'animals_common': totalCommonAnimals,
          'news_total': totalNews,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Không thể tải thống kê'),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00A86B), Color(0xFF4CD6A7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.white, size: 26),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tổng quan hệ thống',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...items.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF1F1F28)),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 900
                                ? 4
                                : (width >= 520 ? 3 : 2);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.55,
                              ),
                              itemCount: entry.value.length,
                              itemBuilder: (_, i) => entry.value[i],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ];
                    }),
                  ],
                ),
    );
  }

  Map<String, List<Widget>> _buildItems() {
    final c = _counts;
    final users = [
      _StatCard(
        title: 'Tổng người dùng',
        value: c['users_total'] ?? 0,
        icon: Icons.people_alt,
        accent: const Color(0xFF2563EB),
      ),
      _StatCard(
        title: 'Admin',
        value: c['users_admin'] ?? 0,
        icon: Icons.admin_panel_settings,
        accent: const Color(0xFF7C3AED),
      ),
    ];

    final animals = [
      _StatCard(
        title: 'Không quý hiếm',
        value: c['animals_common'] ?? 0,
        icon: Icons.pets_outlined,
        accent: const Color(0xFF64748B),
      ),
      _StatCard(
        title: 'Quý hiếm',
        value: c['animals_rare'] ?? 0,
        icon: Icons.local_fire_department,
        accent: const Color(0xFFEF4444),
      ),
    ];

    final news = [
      _StatCard(
        title: 'Tin tức',
        value: c['news_total'] ?? 0,
        icon: Icons.article,
        accent: const Color(0xFF0EA5E9),
      ),
    ];

    return {
      'Người dùng': users,
      'Động vật': animals,
      'Tin tức': news,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4B5A52), fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Text(
            '',
            style: const TextStyle(fontSize: 0),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1F1F28)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (value <= 0 ? 0.0 : 1.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
