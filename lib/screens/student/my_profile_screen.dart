import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Миний профайл')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFEEEDFE),
              child: Text('👤', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              auth.profile?['full_name'] ?? 'Нэр байхгүй',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: const Text('📧', style: TextStyle(fontSize: 20)),
              title: Text(auth.user?.email ?? '—'),
            ),
            ListTile(
              leading: const Text('🎓', style: TextStyle(fontSize: 20)),
              title: Text(auth.profile?['student_code'] ?? '—'),
            ),
            ListTile(
              leading: const Text('🏫', style: TextStyle(fontSize: 20)),
              title: Text(auth.profile?['school'] ?? '—'),
            ),
            ListTile(
              leading: const Text('📚', style: TextStyle(fontSize: 20)),
              title: Text(auth.profile?['department'] ?? '—'),
            ),
            ListTile(
              leading: const Text('📞', style: TextStyle(fontSize: 20)),
              title: Text(auth.profile?['phone'] ?? '—'),
            ),
            const Spacer(),
            // ── Гарах товч ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD85A30),
                  side: const BorderSide(color: Color(0xFFD85A30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🚪', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'Системээс гарах',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}