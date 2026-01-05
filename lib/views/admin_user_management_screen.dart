import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  static const Color _primary = Color(0xFF00A86B);
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchUser(AppUser u, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return u.email.toLowerCase().contains(s) || u.displayName.toLowerCase().contains(s) || u.id.toLowerCase().contains(s);
  }

  Future<void> _toggleAdmin(AppUser u) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(u.id).update({
      'isAdmin': !u.isAdmin,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteUser(BuildContext context, AppUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Xóa user document của "${u.email.isNotEmpty ? u.email : u.id}" trên Firestore?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(u.id).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa user document')));
    }
  }

  Future<void> _openEditor({AppUser? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserEditorSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
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
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo email / tên / uid',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.4),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải user: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final users = docs
                    .map((d) => AppUser.fromFirestore(d.data() as Map<String, dynamic>, d.id))
                    .where((u) => _matchUser(u, _search.text))
                    .toList();

                if (users.isEmpty) {
                  return const Center(child: Text('Không có người dùng phù hợp.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final initials = (u.displayName.trim().isNotEmpty ? u.displayName.trim() : u.email.trim())
                        .trim()
                        .split(RegExp(r'\\s+'))
                        .where((p) => p.isNotEmpty)
                        .take(2)
                        .map((e) => e.characters.first.toUpperCase())
                        .join();

                    return Container(
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: _primary.withOpacity(0.14),
                          foregroundColor: _primary,
                          child: Text(initials.isNotEmpty ? initials : 'U'),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.displayName.isNotEmpty ? u.displayName : 'Người dùng',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (u.isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.25)),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              u.email.isNotEmpty ? u.email : '(Chưa có email)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UID: ${u.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black38, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await _openEditor(existing: u);
                            } else if (v == 'toggle_admin') {
                              await _toggleAdmin(u);
                            } else if (v == 'delete' && context.mounted) {
                              await _deleteUser(context, u);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(
                              value: 'toggle_admin',
                              child: Text(u.isAdmin ? 'Hạ quyền Admin' : 'Nâng quyền Admin'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserEditorSheet extends StatefulWidget {
  final AppUser? existing;

  const _UserEditorSheet({this.existing});

  @override
  State<_UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends State<_UserEditorSheet> {
  static const Color _primary = Color(0xFF00A86B);
  final _formKey = GlobalKey<FormState>();
  final _uid = TextEditingController();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _isAdmin = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    if (u != null) {
      _uid.text = u.id;
      _email.text = u.email;
      _name.text = u.displayName;
      _phone.text = u.phone ?? '';
      _address.text = u.address ?? '';
      _isAdmin = u.isAdmin;
    }
  }

  @override
  void dispose() {
    _uid.dispose();
    _email.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final service = FirestoreService();
      final now = DateTime.now();

      final user = AppUser(
        id: _uid.text.trim(),
        email: _email.text.trim(),
        displayName: _name.text.trim(),
        avatarUrl: widget.existing?.avatarUrl,
        birthDate: widget.existing?.birthDate,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        favoriteSpecies: widget.existing?.favoriteSpecies ?? const [],
        savedNews: widget.existing?.savedNews ?? const [],
        isAdmin: _isAdmin,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
        isEmailVerified: widget.existing?.isEmailVerified ?? false,
      );

      if (widget.existing == null) {
        await service.createUser(user);
      } else {
        await service.updateUser(user);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'Thêm người dùng' : 'Sửa người dùng',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _uid,
                readOnly: widget.existing != null,
                decoration: const InputDecoration(labelText: 'UID (Document ID)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập UID' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập email' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'SĐT (tuỳ chọn)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Địa chỉ (tuỳ chọn)'),
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                value: _isAdmin,
                onChanged: (v) => setState(() => _isAdmin = v),
                title: const Text('Quyền Admin'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu'),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lưu ý: Màn này chỉ CRUD document trong Firestore. Tạo/xoá tài khoản FirebaseAuth cần Cloud Functions (Admin SDK).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
