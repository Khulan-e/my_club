// lib/screens/admin/admin_members_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _db = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _members  = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('club_memberships')
          .select('''
            id, status, joined_at,
            user:users(id, full_name, student_code, department),
            club:clubs(id, name, category)
          ''')
          .eq('status', 'approved')
          .order('joined_at', ascending: false);

      if (mounted) {
        setState(() {
          _members  = List<Map<String, dynamic>>.from(data);
          _filtered = _members;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _members
          : _members.where((m) {
              final name = (m['user']?['full_name'] ?? '').toLowerCase();
              final club = (m['club']?['name']      ?? '').toLowerCase();
              return name.contains(q.toLowerCase()) || club.contains(q.toLowerCase());
            }).toList();
    });
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Гишүүнчлэл цуцлах'),
        content: Text('${member['user']?['full_name'] ?? ''}-г ${member['club']?['name'] ?? ''} клубаас хасах уу?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Болих')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Хасах'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.from('club_memberships').delete().eq('id', member['id']);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Гишүүнчлэл цуцлагдлаа')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Нэр эсвэл клубаар хайх...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text('Нийт ${_filtered.length} гишүүн',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const EmptyState(message: 'Гишүүн олдсонгүй')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final m          = _filtered[i];
                    final name       = m['user']?['full_name']    ?? 'Оюутан';
                    final studentCode = m['user']?['student_code'] ?? '';
                    final department = m['user']?['department']   ?? '';
                    final clubName   = m['club']?['name']         ?? '';
                    final category   = m['club']?['category']     ?? '';
                    final joinedAt   = m['joined_at'] != null
                        ? DateTime.parse(m['joined_at']).toLocal() : null;
                    final dateStr = joinedAt != null
                        ? '${joinedAt.year}/${joinedAt.month.toString().padLeft(2,'0')}/${joinedAt.day.toString().padLeft(2,'0')}' : '';

                    final catColor = category == 'Урлагийн' ? Colors.pink
                        : category == 'Сонирхлын' ? Colors.teal : AppColors.primary;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$studentCode • $department',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(clubName, style: TextStyle(fontSize: 10, color: catColor)),
                              ),
                              const SizedBox(width: 6),
                              Text(dateStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ]),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                          onPressed: () => _remove(m),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
