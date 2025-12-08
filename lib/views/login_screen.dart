import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  String? _errorMessage;
  final AuthController _authController = AuthController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    setState(() => _errorMessage = null);

    UserCredential? result;

    try {
      if (_isLogin) {
        result = await _authController.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
          _setError('Mật khẩu và xác nhận mật khẩu không khớp');
          setState(() => _isLoading = false);
          return;
        }
        result = await _authController.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Sau khi đăng ký thành công, tạo document user trên Firestore nếu chưa có
        if (result != null) {
          final user = result.user;
          if (user != null) {
            final existing = await _firestoreService.getUserById(user.uid);
            if (existing == null) {
              final now = DateTime.now();
              final appUser = AppUser(
                id: user.uid,
                email: user.email ?? _emailController.text.trim(),
                displayName: user.displayName ?? '',
                avatarUrl: null,
                phone: user.phoneNumber,
                address: null,
                favoriteSpecies: const [],
                savedNews: const [],
                isAdmin: false,
                createdAt: now,
                updatedAt: now,
                isEmailVerified: user.emailVerified,
              );
              await _firestoreService.createUser(appUser);
            }
          }
        }
      }
    } catch (e) {
      result = null;
      _setError(e.toString());
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null) {
      final message = _isLogin ? 'Đăng nhập thành công!' : 'Đăng ký thành công!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _authController.signInWithGoogle();
      
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập Google thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }

    setState(() => _isLoading = false);
  }

  void _setError(String error) {
    String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
    
    if (error.contains('user-not-found')) {
      message = 'Tài khoản không tồn tại.';
    } else if (error.contains('wrong-password')) {
      message = 'Mật khẩu không đúng.';
    } else if (error.contains('invalid-email')) {
      message = 'Email không hợp lệ.';
    } else if (error.contains('email-already-in-use')) {
      message = 'Email đã được sử dụng. Vui lòng dùng email khác.';
    } else if (error.contains('weak-password')) {
      message = 'Mật khẩu phải có ít nhất 6 ký tự.';
    }

    setState(() => _errorMessage = message);
  }

  void _showErrorSnackBar(String error) {
    _setError(error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 80,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isLogin ? 'Đăng nhập' : 'Đăng ký',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        _buildConfirmPasswordField(),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildGoogleButton(),
                      const SizedBox(height: 16),
                      _buildToggleAuthButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.email),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập email';
        if (!value.contains('@')) return 'Email không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Mật khẩu',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.lock),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'Xác nhận mật khẩu',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.lock),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập xác nhận mật khẩu';
        if (value != _passwordController.text.trim()) return 'Mật khẩu và xác nhận mật khẩu không khớp';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
            : Text(
                _isLogin ? 'Đăng nhập' : 'Đăng ký',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Text(
              'Đăng nhập với Google',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleAuthButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          _errorMessage = null;
        });
      },
      child: Text(
        _isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập',
        style: TextStyle(
          color: Colors.blue.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}