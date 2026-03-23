// lib/screens/auth/auth_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

// ═══════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
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
    } else {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
    }
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
                          child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text('ClubHub',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('ХУИС — Оюутны клубуудын платформ',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 36),
                    Text('Нэвтрэх',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Оюутны и-мэйл болон нууц үгээ оруулна уу',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
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
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: AppColors.textMuted),
                        onPressed: () => setState(() => _obscure = !_obscure),
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
                        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text('Нууц үг мартсан?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(label: 'Нэвтрэх', loading: _loading, onPressed: _submit),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Бүртгэл байхгүй?',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
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

// ═══════════════════════════════════════════════════════════
// REGISTER SCREEN
// ═══════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _fullNameCtrl   = TextEditingController();
  final _studentCodeCtrl = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();

  String _selectedSchool = AppConstants.schools.first;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_fullNameCtrl, _studentCodeCtrl, _emailCtrl,
        _phoneCtrl, _departmentCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await context.read<AuthProvider>().register(
      email:       _emailCtrl.text.trim(),
      password:    _passwordCtrl.text,
      fullName:    _fullNameCtrl.text.trim(),
      studentCode: _studentCodeCtrl.text.trim(),
      school:      _selectedSchool,
      department:  _departmentCtrl.text.trim(),
      phone:       _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Бүртгүүлэх')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ErrorBanner(message: _error!),
                  const SectionHeader(title: 'Хувийн мэдээлэл'),
                  AppTextField(
                    controller: _fullNameCtrl,
                    label: 'Овог нэр',
                    hint: 'Болд Энхбаяр',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Нэр оруулна уу' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _studentCodeCtrl,
                    label: 'Оюутны код',
                    hint: 'TS2021045',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => v!.isEmpty ? 'Оюутны код оруулна уу' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneCtrl,
                    label: 'Утасны дугаар',
                    hint: '9900-0000',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (v) => v!.isEmpty ? 'Утас оруулна уу' : null,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Сургалтын мэдээлэл'),
                  DropdownButtonFormField<String>(
                    value: _selectedSchool,
                    decoration: const InputDecoration(
                      labelText: 'Сургууль',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                    items: AppConstants.schools
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSchool = v!),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _departmentCtrl,
                    label: 'Тэнхим / анги',
                    hint: 'Хэл шинжлэлийн тэнхим',
                    prefixIcon: Icons.class_outlined,
                    validator: (v) => v!.isEmpty ? 'Тэнхим оруулна уу' : null,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Нэвтрэх мэдээлэл'),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Сургуулийн и-мэйл',
                    hint: 'student@huis.edu.mn',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v!.isEmpty) return 'И-мэйл оруулна уу';
                      if (!v.contains('@')) return 'Зөв и-мэйл оруулна уу';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordCtrl,
                    label: 'Нууц үг',
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Нууц үг оруулна уу';
                      if (v.length < 8) return 'Дор хаяж 8 тэмдэгт байх ёстой';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _confirmCtrl,
                    label: 'Нууц үг давтах',
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v!.isEmpty) return 'Нууц үгийг давтана уу';
                      if (v != _passwordCtrl.text) return 'Нууц үг таарахгүй байна';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Бүртгүүлэх', loading: _loading, onPressed: _submit),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Бүртгэлтэй юу?',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Нэвтрэх'),
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

// ═══════════════════════════════════════════════════════════
// FORGOT PASSWORD SCREEN
// ═══════════════════════════════════════════════════════════
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      // AuthService-ийг supabase_service.dart-аас import хийсэн
      await AuthService().sendPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Нууц үг сэргээх')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent ? _sentView() : _formView(),
          ),
        ),
      ),
    );
  }

  Widget _formView() => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text('Нууц үг сэргээх',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Бүртгэлтэй и-мэйл хаягаа оруулна уу. Нууц үг сэргээх холбоос илгээнэ.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 28),
        if (_error != null) ErrorBanner(message: _error!),
        AppTextField(
          controller: _emailCtrl,
          label: 'И-мэйл хаяг',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: (v) {
            if (v!.isEmpty) return 'И-мэйл оруулна уу';
            if (!v.contains('@')) return 'Зөв и-мэйл оруулна уу';
            return null;
          },
        ),
        const SizedBox(height: 20),
        AppButton(label: 'Холбоос илгээх', loading: _loading, onPressed: _submit),
      ],
    ),
  );

  Widget _sentView() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.mark_email_read_outlined, size: 32, color: AppColors.teal),
      ),
      const SizedBox(height: 20),
      Text('Имэйл илгээгдлээ!',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('${_emailCtrl.text} хаяг руу нууц үг сэргээх холбоос илгээлээ.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
      const SizedBox(height: 24),
      AppButton(
        label: 'Нэвтрэх хуудас руу буцах',
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════
// CHANGE PASSWORD SCREEN
// ═══════════════════════════════════════════════════════════
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      // AuthService-ийг supabase_service.dart-аас import хийсэн
      await AuthService().changePassword(_newCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нууц үг амжилттай солигдлоо'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Нууц үг солих')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ErrorBanner(message: _error!),
                  AppTextField(
                    controller: _newCtrl,
                    label: 'Шинэ нууц үг',
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Шинэ нууц үг оруулна уу';
                      if (v.length < 8) return 'Дор хаяж 8 тэмдэгт';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _confirmCtrl,
                    label: 'Нууц үг давтах',
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v!.isEmpty) return 'Нууц үгийг давтана уу';
                      if (v != _newCtrl.text) return 'Нууц үг таарахгүй байна';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Нууц үг солих', loading: _loading, onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}