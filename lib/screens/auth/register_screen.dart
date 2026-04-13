// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _fullNameCtrl    = TextEditingController();
  final _studentCodeCtrl = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _departmentCtrl  = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmCtrl     = TextEditingController();

  String _selectedSchool = AppConstants.schools.first;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _studentCodeCtrl, _emailCtrl,
      _phoneCtrl, _departmentCtrl, _passwordCtrl, _confirmCtrl
    ]) { c.dispose(); }
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
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Нэр оруулна уу' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _studentCodeCtrl,
                    label: 'Оюутны код',
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
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis)))
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
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textMuted),
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
                  AppButton(
                      label: 'Бүртгүүлэх',
                      loading: _loading,
                      onPressed: _submit),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Бүртгэлтэй юу?',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
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
