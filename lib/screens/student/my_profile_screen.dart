// lib/screens/student/my_profile_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});
  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _deptCtrl;
  bool _editing = false;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    _nameCtrl  = TextEditingController(text: p?['full_name'] ?? '');
    _phoneCtrl = TextEditingController(text: p?['phone'] ?? '');
    _deptCtrl  = TextEditingController(text: p?['department'] ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await AuthService().updateProfile(
      userId:     auth.user!.id,
      fullName:   _nameCtrl.text.trim(),
      phone:      _phoneCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
    );
    await auth.refreshProfile();
    if (mounted) setState(() { _saving = false; _editing = false; });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Миний профайл'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _editing = true)),
          if (_editing)
            TextButton(onPressed: _saving ? null : _save, child: const Text('Хадгалах')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (profile?['full_name'] ?? '?').substring(0, 1),
                        style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(profile?['full_name'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(profile?['email'] ?? '',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _infoCard('Хувийн мэдээлэл', [
                _editing
                    ? AppTextField(controller: _nameCtrl, label: 'Нэр', validator: (v) => v!.isEmpty ? 'Нэр оруулна уу' : null)
                    : _row('Нэр', profile?['full_name'] ?? '-'),
                const SizedBox(height: 10),
                _editing
                    ? AppTextField(controller: _phoneCtrl, label: 'Утас', keyboardType: TextInputType.phone)
                    : _row('Утас', profile?['phone'] ?? '-'),
              ]),
              const SizedBox(height: 12),

              _infoCard('Сургалтын мэдээлэл', [
                _row('Оюутны код', profile?['student_code'] ?? '-'),
                const SizedBox(height: 8),
                _row('Сургууль', profile?['school'] ?? '-'),
                const SizedBox(height: 8),
                _editing
                    ? AppTextField(controller: _deptCtrl, label: 'Тэнхим / анги')
                    : _row('Тэнхим', profile?['department'] ?? '-'),
              ]),
              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                  title: const Text('Нууц үг солих'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/change-password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ],
  );
}