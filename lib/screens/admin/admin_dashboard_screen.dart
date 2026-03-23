// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final _pages = const [
    _DashboardTab(),
    _ClubsTab(),
    _RequestsTab(),
    _HoursTab(),
    _ReviewsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админы самбар')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Клубүүд'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Хүсэлт'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Цаг'),
          NavigationDestination(icon: Icon(Icons.rate_review_outlined), selectedIcon: Icon(Icons.rate_review), label: 'Сэтгэгдэл'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Dashboard tab
// ─────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _adminService = AdminService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topClubs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final results = await Future.wait([
      _adminService.getDashboardStats(),
      _adminService.getTopClubs(),
    ]);
    if (mounted) setState(() {
      _stats    = results[0] as Map<String, dynamic>;
      _topClubs = results[1] as List<Map<String, dynamic>>;
      _loading  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _statCard('Нийт клуб', '${_stats!['total_clubs']}', Icons.groups_rounded, AppColors.primary),
                _statCard('Нийт оюутан', '${_stats!['total_students']}', Icons.people_rounded, AppColors.teal),
                _statCard('Хүлээгдэж буй', '${_stats!['pending_requests']}', Icons.pending_rounded, AppColors.amber),
                _statCard('Нийт цаг', '${_stats!['total_volunteer_hours']}', Icons.schedule_rounded, AppColors.coral),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Идэвхтэй клубүүд', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            ..._topClubs.take(5).map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(c['name'].substring(0, 1), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${c['member_count']} гишүүн  ·  ${c['total_hours_given']} цаг',
                  style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                    const SizedBox(width: 3),
                    Text((c['avg_rating'] as num).toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// Requests tab
// ─────────────────────────────────────────
class _RequestsTab extends StatefulWidget {
  const _RequestsTab();
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _reqService = JoinRequestService();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final reqs = await _reqService.getAllPendingRequests();
    if (mounted) setState(() { _requests = reqs; _loading = false; });
  }

  Future<void> _approve(String id) async {
    await _reqService.approveRequest(id);
    _load();
  }

  Future<void> _reject(String id) async {
    await _reqService.rejectRequest(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const LoadingView() : RefreshIndicator(
      onRefresh: _load,
      child: _requests.isEmpty
          ? const EmptyState(message: 'Хүлээгдэж буй хүсэлт байхгүй', icon: Icons.check_circle_outline)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (_, i) {
                final r = _requests[i];
                final user = r['users'] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(user['full_name'].substring(0, 1),
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${user['student_code']}  ·  ${r['clubs']?['name'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (r['message'] != null && (r['message'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r['message'],
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reject(r['id']),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Татгалзах'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approve(r['id']),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Батлах'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────
// Clubs management tab
// ─────────────────────────────────────────
class _ClubsTab extends StatefulWidget {
  const _ClubsTab();
  @override
  State<_ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<_ClubsTab> {
  final _clubService = ClubService();
  final _adminService = AdminService();
  List<Map<String, dynamic>> _clubs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final clubs = await _clubService.getClubs();
    if (mounted) setState(() { _clubs = clubs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const LoadingView() : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _clubs.length,
          itemBuilder: (_, i) {
            final c = _clubs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Row(children: [
                  CategoryBadge(category: c['category']),
                  const SizedBox(width: 8),
                  Text('${c['member_count']} гишүүн', style: const TextStyle(fontSize: 11)),
                ]),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      child: const ListTile(leading: Icon(Icons.people_outline), title: Text('Гишүүд'), contentPadding: EdgeInsets.zero),
                      onTap: () async {
                        final members = await _adminService.getClubMembers(c['id']);
                        if (context.mounted) _showMembers(context, c['name'], members);
                      },
                    ),
                    PopupMenuItem(
                      child: const ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Устгах', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero),
                      onTap: () async {
                        await _clubService.deleteClub(c['id']);
                        _load();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClubDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Клуб нэмэх'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showMembers(BuildContext context, String clubName, List<Map<String, dynamic>> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$clubName — гишүүд',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final u = members[i]['users'] as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(u['full_name'].substring(0, 1),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(u['full_name']),
                    subtitle: Text(u['student_code']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClubDialog(BuildContext context) {
    final nameCtrl   = TextEditingController();
    final descCtrl   = TextEditingController();
    final emailCtrl  = TextEditingController();
    final phoneCtrl  = TextEditingController();
    final instrCtrl  = TextEditingController();
    String cat = 'professional';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Клуб нэмэх'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, label: 'Клубын нэр'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: cat,
                  decoration: const InputDecoration(labelText: 'Ангилал'),
                  items: const [
                    DropdownMenuItem(value: 'professional', child: Text('Мэргэжлийн')),
                    DropdownMenuItem(value: 'hobby',        child: Text('Сонирхлын')),
                    DropdownMenuItem(value: 'art',          child: Text('Урлагийн')),
                  ],
                  onChanged: (v) => setS(() => cat = v!),
                ),
                const SizedBox(height: 10),
                AppTextField(controller: descCtrl, label: 'Тайлбар', maxLines: 3),
                const SizedBox(height: 10),
                AppTextField(controller: emailCtrl, label: 'И-мэйл', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                AppTextField(controller: phoneCtrl, label: 'Утас', keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                AppTextField(controller: instrCtrl, label: 'Элсэх заавар', maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Цуцлах')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                await ClubService().createClub({
                  'name':            nameCtrl.text.trim(),
                  'category':        cat,
                  'description':     descCtrl.text.trim(),
                  'email':           emailCtrl.text.trim(),
                  'phone':           phoneCtrl.text.trim(),
                  'join_instruction': instrCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Нэмэх'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Hours tab (бөөнөөр цаг нэмэх)
// ─────────────────────────────────────────
class _HoursTab extends StatefulWidget {
  const _HoursTab();
  @override
  State<_HoursTab> createState() => _HoursTabState();
}

class _HoursTabState extends State<_HoursTab> {
  final _eventService = EventService();
  final _hoursService = VolunteerHoursService();
  final _adminService = AdminService();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final events = await _eventService.getUpcomingEvents();
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  void _showAddHoursDialog(BuildContext context, Map<String, dynamic> event) async {
    final members = await _adminService.getClubMembers(event['club_id']);
    final selected = <String>{};

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${event['title']} — цаг нэмэх'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${event['hours']} цаг олгох оюутнуудыг сонгоно уу',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final u = members[i]['users'] as Map<String, dynamic>;
                      final uid = members[i]['user_id'] as String;
                      return CheckboxListTile(
                        dense: true,
                        title: Text(u['full_name'], style: const TextStyle(fontSize: 13)),
                        subtitle: Text(u['student_code'], style: const TextStyle(fontSize: 11)),
                        value: selected.contains(uid),
                        onChanged: (v) => setS(() {
                          if (v!) selected.add(uid); else selected.remove(uid);
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Цуцлах')),
            ElevatedButton(
              onPressed: selected.isEmpty ? null : () async {
                await _hoursService.addHoursBulk(
                  userIds: selected.toList(),
                  clubId: event['club_id'],
                  eventId: event['id'],
                  eventTitle: event['title'],
                  hours: (event['hours'] as num).toDouble(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${selected.length} оюутанд цаг нэмлээ'), backgroundColor: AppColors.teal),
                  );
                }
              },
              child: Text('${selected.length} оюутанд нэмэх'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const LoadingView() : _events.isEmpty
        ? const EmptyState(message: 'Арга хэмжээ байхгүй', icon: Icons.event_outlined)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _events.length,
            itemBuilder: (_, i) {
              final e = _events[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.event_rounded, color: AppColors.teal, size: 20),
                  ),
                  title: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${e['clubs']?['name'] ?? ''}  ·  ${e['hours']} цаг',
                    style: const TextStyle(fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () => _showAddHoursDialog(context, e),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Цаг нэмэх'),
                  ),
                ),
              );
            },
          );
  }
}

// ─────────────────────────────────────────
// Reviews tab
// ─────────────────────────────────────────
class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final _reviewService = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await supabase
        .from('reviews')
        .select('*, users(full_name), clubs(name)')
        .order('created_at', ascending: false)
        .limit(50);
    if (mounted) setState(() { _reviews = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const LoadingView() : RefreshIndicator(
      onRefresh: _load,
      child: _reviews.isEmpty
          ? const EmptyState(message: 'Сэтгэгдэл байхгүй', icon: Icons.rate_review_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (_, i) {
                final r = _reviews[i];
                final stars = (r['rating'] as num).round();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['users']?['full_name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(r['clubs']?['name'] ?? '',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(children: [
                              Row(children: List.generate(5, (j) =>
                                Icon(j < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 14, color: AppColors.amber))),
                              if (r['is_visible'] == true)
                                IconButton(
                                  icon: const Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.textMuted),
                                  tooltip: 'Нуух',
                                  onPressed: () async {
                                    await _reviewService.hideReview(r['id']);
                                    _load();
                                  },
                                ),
                            ]),
                          ],
                        ),
                        if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(r['comment'], style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                        if (r['is_visible'] == false)
                          const Text('Нуугдсан', style: TextStyle(color: Colors.red, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}