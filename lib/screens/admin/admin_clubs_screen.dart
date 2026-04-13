// lib/screens/admin/admin_clubs_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class AdminClubsScreen extends StatefulWidget {
  const AdminClubsScreen({super.key});

  @override
  State<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends State<AdminClubsScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _clubs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('clubs')
          .select('id, name, description, category, created_at')
          .order('name');

      // Тус бүрийн гишүүн тоо, хүлээж буй хүсэлт тоо
      final List<Map<String, dynamic>> enriched = [];
      for (final club in data as List) {
        final members = await _db
            .from('club_memberships')
            .select('id')
            .eq('club_id', club['id'])
            .eq('status', 'approved');
        final pending = await _db
            .from('join_requests')
            .select('id')
            .eq('club_id', club['id'])
            .eq('status', 'pending');
        enriched.add({
          ...Map<String, dynamic>.from(club),
          'member_count':  (members as List).length,
          'pending_count': (pending as List).length,
        });
      }

      if (mounted) {
        setState(() {
          _clubs   = enriched;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(Map<String, dynamic> club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClubDetailSheet(club: club),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();

    return RefreshIndicator(
      onRefresh: _load,
      child: _clubs.isEmpty
          ? const EmptyState(message: 'Клуб байхгүй байна')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _clubs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final club         = _clubs[i];
                final name         = club['name']          ?? '';
                final description  = club['description']   ?? '';
                final category     = club['category']      ?? '';
                final memberCount  = club['member_count']  ?? 0;
                final pendingCount = club['pending_count'] ?? 0;

                Color    catColor;
                IconData catIcon;
                switch (category) {
                  case 'Урлагийн':   catColor = Colors.pink;         catIcon = Icons.palette_outlined; break;
                  case 'Сонирхлын':  catColor = Colors.teal;         catIcon = Icons.star_outline;     break;
                  default:           catColor = AppColors.primary;   catIcon = Icons.work_outline;
                }

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showDetail(club),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(catIcon, color: catColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(category,
                                      style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            )),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ]),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(description,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 12),
                          Row(children: [
                            _Chip(icon: Icons.people_outline, label: '$memberCount гишүүн'),
                            const SizedBox(width: 10),
                            if (pendingCount > 0)
                              _Chip(icon: Icons.pending_outlined, label: '$pendingCount хүлээж буй', color: Colors.orange),
                          ]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: c),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: c)),
    ]);
  }
}

class _ClubDetailSheet extends StatelessWidget {
  final Map<String, dynamic> club;
  const _ClubDetailSheet({required this.club});

  @override
  Widget build(BuildContext context) {
    final name         = club['name']          ?? '';
    final description  = club['description']   ?? '';
    final category     = club['category']      ?? '';
    final memberCount  = club['member_count']  ?? 0;
    final pendingCount = club['pending_count'] ?? 0;
    final createdAt    = club['created_at'] != null
        ? DateTime.parse(club['created_at']).toLocal() : null;
    final dateStr = createdAt != null
        ? '${createdAt.year}/${createdAt.month.toString().padLeft(2,'0')}/${createdAt.day.toString().padLeft(2,'0')}' : '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (description.isNotEmpty) ...[
            Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
          ],
          const Divider(),
          const SizedBox(height: 8),
          _R('Ангилал',              category),
          _R('Нийт гишүүн',          '$memberCount'),
          _R('Хүлээж буй хүсэлт',   '$pendingCount'),
          _R('Үүсгэсэн огноо',       dateStr),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _R(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 150, child: Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ]),
  );
}
