import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'profile_edit_screen.dart';

class _ProfileViewData {
  final AppUser? appUser;
  final String? localAvatarPath;

  const _ProfileViewData({required this.appUser, required this.localAvatarPath});
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<_ProfileViewData> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _ProfileViewData(appUser: null, localAvatarPath: null);
    final service = FirestoreService();
    final appUser = await service.getUserById(user.uid);
    final prefs = await SharedPreferences.getInstance();
    final localAvatarPath = prefs.getString('local_avatar_path_${user.uid}');
    return _ProfileViewData(appUser: appUser, localAvatarPath: localAvatarPath);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00A86B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: FutureBuilder<_ProfileViewData>(
        future: _loadData(),
        builder: (context, snapshot) {
          final authUser = FirebaseAuth.instance.currentUser;
          final appUser = snapshot.data?.appUser;
          final localAvatarPath = snapshot.data?.localAvatarPath;
          final displayName = appUser?.displayName ?? authUser?.displayName ?? '';
          final email = appUser?.email ?? authUser?.email ?? '';
          final verified = appUser?.isEmailVerified ?? authUser?.emailVerified ?? false;
          final provider =
              (authUser?.providerData.isNotEmpty ?? false) ? authUser!.providerData.first.providerId : '';
          final created = authUser?.metadata.creationTime;
          final avatarUrl = appUser?.avatarUrl;
          final birthDate = appUser?.birthDate;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _HeaderCard(
                name: displayName.isNotEmpty ? displayName : 'Người dùng',
                email: email,
                verified: verified,
                provider: provider,
                avatarUrl: avatarUrl,
                localAvatarPath: localAvatarPath,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Email',
                value: email.isNotEmpty ? email : 'Chưa cập nhật',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Tên hiển thị',
                value: displayName.isNotEmpty ? displayName : 'Chưa cập nhật',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Ngày sinh',
                value: birthDate != null
                    ? '${birthDate.day}/${birthDate.month}/${birthDate.year}'
                    : 'Chưa cập nhật',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Trạng thái',
                value: verified ? 'Đã xác thực' : 'Chưa xác thực',
                valueColor: verified ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Nhà cung cấp',
                value: provider.isNotEmpty ? provider : 'Email/Password',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Ngày tạo tài khoản',
                value: created != null ? '${created.day}/${created.month}/${created.year}' : 'Chưa có dữ liệu',
              ),
              const SizedBox(height: 20),
              // Removed ghi chú card per request
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final bool verified;
  final String provider;
  final String? avatarUrl;
  final String? localAvatarPath;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.verified,
    required this.provider,
    this.avatarUrl,
    this.localAvatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white, width: 2),
              image: (localAvatarPath != null && localAvatarPath!.isNotEmpty)
                  ? DecorationImage(image: FileImage(File(localAvatarPath!)), fit: BoxFit.cover)
                  : (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                      : null,
            ),
            child: ((localAvatarPath == null || localAvatarPath!.isEmpty) && (avatarUrl == null || avatarUrl!.isEmpty))
                ? const Icon(Icons.person, color: Colors.white, size: 36)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      verified ? Icons.verified : Icons.error_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      verified ? 'Đã xác thực' : 'Chưa xác thực',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (provider.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          provider,
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF444454)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1F1F28),
            ),
          ),
        ],
      ),
    );
  }
}
