import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/sl_button.dart';
import '../../../shared/widgets/sl_text_field.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).register(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text : null,
        );

    if (success && mounted) {
      try {
        await ref.read(authNotifierProvider.notifier).sendEmailOtp(_emailController.text);
      } catch (_) {}
      if (mounted) {
        context.go('/verify-email', extra: _emailController.text);
      }
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tham gia SecondLife',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Khám phá đồ gia dụng thanh lý đã qua thẩm định, bảo vệ thanh toán Escrow 48h',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // Full Name
                  SlTextField(
                    label: 'Họ và tên',
                    hint: 'Nguyễn Văn A',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Email
                  SlTextField(
                    label: 'Email',
                    hint: 'nguoimua@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                      if (!v.contains('@')) return 'Email không đúng định dạng';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Phone
                  SlTextField(
                    label: 'Số điện thoại',
                    hint: '0912345678',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final regex = RegExp(r'^0[35789][0-9]{8}$');
                        if (!regex.hasMatch(v.trim())) {
                          return 'Số điện thoại gồm 10 chữ số (bắt đầu bằng 03, 05, 07, 08, 09)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password
                  SlTextField(
                    label: 'Mật khẩu',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (v.length < 8) return 'Mật khẩu phải từ 8 ký tự trở lên (gồm chữ hoa, chữ thường, số, ký tự đặc biệt)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  SlButton(
                    text: 'Tạo tài khoản',
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),

                  // Login redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
