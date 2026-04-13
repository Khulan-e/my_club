// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

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
            const Icon(Icons.lock_reset_rounded,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Нууц үг сэргээх',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Бүртгэлтэй и-мэйл хаягаа оруулна уу. Нууц үг сэргээх холбоос илгээнэ.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
            AppButton(
                label: 'Холбоос илгээх',
                loading: _loading,
                onPressed: _submit),
          ],
        ),
      );

  Widget _sentView() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(32)),
            child: const Icon(Icons.mark_email_read_outlined,
                size: 32, color: AppColors.teal),
          ),
          const SizedBox(height: 20),
          Text('Имэйл илгээгдлээ!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${_emailCtrl.text} хаяг руу нууц үг сэргээх холбоос илгээлээ.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          AppButton(
            label: 'Нэвтрэх хуудас руу буцах',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      );
}
