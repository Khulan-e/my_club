// lib/screens/student/my_clubs_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
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
        .select('*, clubs(id, name, category, logo_url, avg_rating, member_count)')
        .eq('user_id', uid)
        .eq('status', 'approved')
        .order('joined_at', ascending: false);
    if (mounted) setState(() { _memberships = List<Map<String, dynamic>>.from(res as List); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: c.bgDark,
      appBar: AppBar(
        backgroundColor: c.bgCard,
        elevation: 0,
        title: Text('Миний клубүүд', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: c.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('${_memberships.length} клуб',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _memberships.isEmpty
              ? const EmptyState(message: 'Элссэн клуб байхгүй байна', icon: Icons.groups_outlined)
              : ListView.builder(
                  // ── Overflow засах: зөвхөн screen-ийн доторх зай ──
                  padding: EdgeInsets.fromLTRB(16, 16, 16,
                    MediaQuery.of(context).padding.bottom + 16),
                  itemCount: _memberships.length,
                  itemBuilder: (_, i) {
                    final m    = _memberships[i];
                    final club = m['clubs'] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              gradient: c.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                          ),
                          title: Text(club['name'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary, fontSize: 15)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: CategoryBadge(category: club['category'] ?? ''),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
                          onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: club['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}