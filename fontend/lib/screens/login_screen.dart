import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';
import 'totp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Lưu email/password và context trước để tránh mất khi async
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final authProvider = context.read<AuthProvider>();

      print('🚀 Bắt đầu đăng nhập với email: $email');

      // First attempt: login with email/password
      final loginResult = await authProvider.loginWithTotpSupport(
        email: email,
        password: password,
      );

      print('📦 Nhận được loginResult từ AuthProvider');
      print('🔍 Mounted status: $mounted');

      print('');
      print('╔════════════════════════════════════╗');
      print('║   LOGIN RESULT FROM PROVIDER      ║');
      print('╠════════════════════════════════════╣');
      print('║ requiresTwoFactor: ${loginResult['requiresTwoFactor']}');
      print('║ success: ${loginResult['success']}');
      print('║ loginResult type: ${loginResult.runtimeType}');
      print('║ Keys: ${loginResult.keys.toList()}');
      print('╚════════════════════════════════════╝');
      print('');

      // Check if 2FA is required
      if (loginResult['requiresTwoFactor'] == true) {
        print('✅ Điều kiện 2FA = true, đang chuyển sang màn hình nhập TOTP...');
        print('🔄 Mounted status trước navigate: $mounted');

        // Đợi một frame để widget hoàn thành rebuild
        await Future.delayed(Duration.zero);
        print('🔄 Mounted status sau delay: $mounted');

        // Dùng navigator đã lưu trước await thay vì context.of()
        print('🚀 Navigate dùng navigator đã lưu trước...');
        final totpCode = await navigator.push<String>(
          MaterialPageRoute(
            builder: (_) =>
                TotpVerificationScreen(email: email, password: password),
          ),
        );

        print(
          '🔙 Quay về từ TOTP screen, nhận được code: ${totpCode ?? "null"}',
        );

        // User provided TOTP code - không check mounted vì đã lưu navigator/scaffoldMessenger
        if (totpCode != null && totpCode.isNotEmpty) {
          print('📱 User nhập mã TOTP: $totpCode');
          print('🔐 Đang verify TOTP...');

          final totpSuccess = await authProvider.loginWithTotp(
            email: email,
            password: password,
            totpCode: totpCode,
          );

          print('Kết quả verify TOTP: $totpSuccess');

          if (totpSuccess) {
            print('✅ Đăng nhập thành công! Chuyển sang màn hình chính...');
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          } else {
            print('❌ TOTP sai: ${authProvider.error}');
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(authProvider.error ?? 'Mã xác thực không đúng'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print('❌ User hủy hoặc không nhập mã TOTP');
        }
      } else if (loginResult['success'] == true) {
        print('✅ Không cần 2FA, đăng nhập thành công luôn!');
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        print('❌ Đăng nhập thất bại! Error: ${authProvider.error}');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Đăng nhập thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('');
      print('╔════════════════════════════════════╗');
      print('║   ❌ LỖI TRONG _handleLogin       ║');
      print('╚════════════════════════════════════╝');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Không dùng watch để tránh widget rebuild và unmount trong async flow
    // Chỉ select isLoading để show loading indicator
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo/Title
                Icon(
                  Icons.lock_person,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Đăng nhập',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chào mừng bạn quay trở lại!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Demo credentials
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Tài khoản demo:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Admin: admin@be1.com / Admin@123',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
