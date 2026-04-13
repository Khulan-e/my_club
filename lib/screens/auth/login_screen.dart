// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _navigateByRole(BuildContext context) {
    final auth = context.read<AuthProvider>();
    String route;
    switch (auth.userRole) {
      case UserRole.superAdmin:
        route = '/super-admin';
        break;
      case UserRole.clubAdmin:
        route = '/admin';
        break;
      case UserRole.student:
      default:
        route = '/home';
        break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await context.read<AuthProvider>().login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    // Profile ачаалагдтал хүлээх
    await context.read<AuthProvider>().refreshProfile();

    if (!mounted) return;
    _navigateByRole(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text('ClubHub',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('ХУИС — Оюутны клубуудын платформ',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 36),
                    Text('Нэвтрэх',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Оюутны и-мэйл болон нууц үгээ оруулна уу',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
                    if (_error != null) ErrorBanner(message: _error!),
                    AppTextField(
                      controller: _emailCtrl,
                      label: 'И-мэйл хаяг',
                      hint: 'student@huis.edu.mn',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'И-мэйл оруулна уу';
                        if (!v.contains('@')) return 'Зөв и-мэйл оруулна уу';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passCtrl,
                      label: 'Нууц үг',
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.textMuted),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Нууц үг оруулна уу';
                        if (v.length < 6) return 'Нууц үг хэтэрхий богино';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/forgot-password'),
                        child: const Text('Нууц үг мартсан?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                        label: 'Нэвтрэх',
                        loading: _loading,
                        onPressed: _submit),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Бүртгэл байхгүй?',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 14)),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text('Бүртгүүлэх'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}