import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  bool _loading = true;
  bool _saving = false;
  XFile? _pickedImage;
  String? _existingAvatarUrl;
  String? _localAvatarPath;

  AppUser? _appUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      setState(() => _loading = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _localAvatarPath = prefs.getString('local_avatar_path_${authUser.uid}');
    final service = FirestoreService();
    final user = await service.getUserById(authUser.uid);
    _appUser = user;
    _nameController.text = user?.displayName.isNotEmpty == true ? user!.displayName : (authUser.displayName ?? '');
    _existingAvatarUrl = user?.avatarUrl ?? authUser.photoURL;
    _birthDate = user?.birthDate;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<String?> _saveLocalAvatar(User authUser) async {
    if (_pickedImage == null) return null;
    final src = File(_pickedImage!.path);
    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${dir.path}${Platform.pathSeparator}avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final dstPath = '${avatarsDir.path}${Platform.pathSeparator}${authUser.uid}.jpg';
    await src.copy(dstPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_avatar_path_${authUser.uid}', dstPath);
    return dstPath;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có thông tin người dùng')));
      }
      return;
    }

    setState(() => _saving = true);

    final service = FirestoreService();
    _appUser ??= AppUser(
      id: authUser.uid,
      email: authUser.email ?? '',
      displayName: authUser.displayName ?? '',
      avatarUrl: authUser.photoURL,
      birthDate: null,
      phone: null,
      address: null,
      favoriteSpecies: const [],
      savedNews: const [],
      isAdmin: false,
      createdAt: authUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isEmailVerified: authUser.emailVerified,
    );

    if (_pickedImage != null) {
      _localAvatarPath = await _saveLocalAvatar(authUser);
    }

    String? avatarUrl = _appUser!.avatarUrl ?? _existingAvatarUrl;

    final updated = _appUser!.copyWith(
      displayName: _nameController.text.trim(),
      avatarUrl: avatarUrl,
      birthDate: _birthDate,
    );

    try {
      final ok = await service.updateUser(updated);
      if (!ok) {
        await service.createUser(updated);
      }
      await authUser.updateDisplayName(updated.displayName);
      _existingAvatarUrl = updated.avatarUrl;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00A86B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pickedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(File(_pickedImage!.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if ((_localAvatarPath ?? '').trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(File((_localAvatarPath ?? '').trim())),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if ((_existingAvatarUrl ?? '').trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage((_existingAvatarUrl ?? '').trim()),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Chọn ảnh từ thư viện'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: 'Tên hiển thị',
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Nhập tên'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'Ngày sinh',
                      child: InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            hintText: 'Chọn ngày sinh',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Text(
                            _birthDate != null
                                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                : 'Chưa chọn',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Lưu',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
