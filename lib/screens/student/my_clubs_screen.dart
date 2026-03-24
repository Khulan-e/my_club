// lib/screens/student/my_clubs_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});
  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  List<Map<String, dynamic>> _memberships = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('club_memberships')
        .select('*, clubs(name, category, logo_url, avg_rating, member_count)')
        .eq('user_id', uid)
        .eq('status', 'approved')
        .order('joined_at', ascending: false);
    if (mounted) setState(() { _memberships = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Миний клубүүд')),
      body: _loading ? const LoadingView() : _memberships.isEmpty
          ? const EmptyState(message: 'Элссэн клуб байхгүй байна', icon: Icons.groups_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _memberships.length,
              itemBuilder: (_, i) {
                final m = _memberships[i];
                final club = m['clubs'] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 22),
                    ),
                    title: Text(club['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: CategoryBadge(category: club['category']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: m['club_id']),
                  ),
                );
              },
            ),
    );
  }
}